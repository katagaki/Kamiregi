import UIKit

// Fetches X (Twitter) profile pictures by scraping the og:image tag,
// since the public API requires authentication.
final class ProfileImageFetcher: @unchecked Sendable {

    static let shared = ProfileImageFetcher()

    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60

    private static let userAgent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " +
        "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15"

    private let session: URLSession
    private let memoryCache = NSCache<NSString, UIImage>()
    private let cacheDirectory: URL

    init(session: URLSession = .shared) {
        self.session = session
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("XProfileImages", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }

    func fetch(for userName: String) async -> UIImage? {
        let key = Self.normalized(userName)
        guard !key.isEmpty else { return nil }

        if let cached = cachedImage(for: key, allowStale: false) {
            return cached
        }
        if let url = await resolveImageURL(for: key),
           let (data, image) = await download(url) {
            store(data, image: image, for: key)
            return image
        }
        return cachedImage(for: key, allowStale: true)
    }

    // MARK: - Resolution

    private func resolveImageURL(for userName: String) async -> URL? {
        guard let encoded = userName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let pageURL = URL(string: "https://x.com/\(encoded)") else { return nil }

        var request = URLRequest(url: pageURL)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        guard let (data, response) = try? await session.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let html = String(data: data, encoding: .utf8),
              let raw = Self.ogImage(in: html) else { return nil }

        return URL(string: Self.upgradeSize(raw))
    }

    private func download(_ url: URL) async -> (Data, UIImage)? {
        var request = URLRequest(url: url)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        guard let (data, response) = try? await session.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let image = UIImage(data: data) else { return nil }
        return (data, image)
    }

    // MARK: - Cache

    private func cacheURL(for key: String) -> URL {
        cacheDirectory.appendingPathComponent(key).appendingPathExtension("img")
    }

    private func cacheAge(for key: String) -> TimeInterval? {
        let path = cacheURL(for: key).path
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let modified = attrs[.modificationDate] as? Date else { return nil }
        return Date().timeIntervalSince(modified)
    }

    private func cachedImage(for key: String, allowStale: Bool) -> UIImage? {
        guard let age = cacheAge(for: key) else { return nil }
        guard allowStale || age < maxCacheAge else { return nil }

        if let memory = memoryCache.object(forKey: key as NSString) { return memory }

        guard let data = try? Data(contentsOf: cacheURL(for: key)),
              let image = UIImage(data: data) else { return nil }
        memoryCache.setObject(image, forKey: key as NSString)
        return image
    }

    private func store(_ data: Data, image: UIImage, for key: String) {
        memoryCache.setObject(image, forKey: key as NSString)
        try? data.write(to: cacheURL(for: key), options: .atomic)
    }

    // MARK: - Parsing

    private static func normalized(_ userName: String) -> String {
        var trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("@") { trimmed.removeFirst() }
        return trimmed.lowercased()
    }

    private static func ogImage(in html: String) -> String? {
        let patterns = [
            #"property=["']og:image["'][^>]*content=["']([^"']+)["']"#,
            #"content=["']([^"']+)["'][^>]*property=["']og:image["']"#
        ]
        for pattern in patterns {
            if let match = firstCaptureGroup(pattern, in: html) { return match }
        }
        return nil
    }

    private static func upgradeSize(_ urlString: String) -> String {
        let pattern = #"_(?:normal|bigger|mini|\d+x\d+)(\.[A-Za-z0-9]+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return urlString }
        let range = NSRange(urlString.startIndex..., in: urlString)
        return regex.stringByReplacingMatches(in: urlString, range: range,
                                              withTemplate: "_400x400$1")
    }

    private static func firstCaptureGroup(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges > 1,
              let captured = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[captured])
    }
}
