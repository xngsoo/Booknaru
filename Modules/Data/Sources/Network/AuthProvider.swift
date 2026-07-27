import Foundation

/// 인증 방식 추상화. 정보나루, 알라딘 모두 쿼리 파라미터 인증이지만
/// 파라미터 이름이 다르다(authKey vs ttbkey). 키가 endpoint가 아니라
/// "어느 API의 client인가"에 속한다는 경계를 유지하기 위해 남겨둔다.
public protocol AuthProvider: Sendable {
    var queryItems: [URLQueryItem] { get }
    var headers: [String: String] { get }
}

/// 쿼리 파라미터 인증. name만 바꿔 정보나루, 알라딘 양쪽에 쓴다.
public struct QueryAuthProvider: AuthProvider {
    private let name: String
    private let key: String
    
    public init(name: String, key: String) {
        self.name = name
        self.key = key
    }
    
    public var queryItems: [URLQueryItem] { [URLQueryItem(name: name, value: key)] }
    public var headers: [String : String] { [:] }
}
