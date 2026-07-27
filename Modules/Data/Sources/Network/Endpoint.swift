import Foundation

/// "어떤 요청인지"를 서술하는 값. 실행은 HTTPClient가 한다
public struct Endpoint: Sendable {
    public let path: String
    public let queryItems: [URLQueryItem]
    
    public init(path: String, queryItems: [URLQueryItem] = []) {
        self.path = path
        self.queryItems = queryItems
    }
}
