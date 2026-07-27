import Foundation

public protocol HTTPClient: Sendable {
    func send<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T
}

public struct URLSessionHTTPClient: HTTPClient {
    private let baseURL: URL
    private let auth: any AuthProvider
    private let session: URLSession
    private let decoder: JSONDecoder
    
    public init(baseURL: URL,
                auth: any AuthProvider,
                session: URLSession = .shared,
                decoder: JSONDecoder = JSONDecoder()) {
        self.baseURL = baseURL
        self.auth = auth
        self.session = session
        self.decoder = decoder
    }
    
    public func send<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        // 1) URL 조립 - endpoint 쿼리 + auth 쿼리 합치기
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL
        }
        
        let merged = endpoint.queryItems + auth.queryItems
        components.queryItems = merged.isEmpty ? nil : merged
        
        guard let url = components.url else { throw NetworkError.invalidURL }
        
        // 2) 요청 조립 - auth 헤더 얹기
        var request = URLRequest(url: url)
        for (field, value) in auth.headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        
        // 3) 전송
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.transport(error)
        }
        
        // 4) 상태코드 검증
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw NetworkError.unacceptableStatus(http.statusCode)
        }
        
        // 5) 디코딩
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decoding(error)
        }
    }
}
