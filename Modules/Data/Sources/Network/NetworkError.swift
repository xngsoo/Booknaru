import Foundation

public enum NetworkError: Error, Sendable {
    case invalidURL
    case transport(any Error)       // URLSession 자체가 던진 에러 (오프라인 등)
    case invalidResponse            // HTTPURLResponse 캐스팅 실패
    case unacceptableStatus(Int)    // 2xx 아님
    case decoding(any Error)        // JSON 디코딩 실패
}
