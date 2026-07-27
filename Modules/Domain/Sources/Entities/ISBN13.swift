/// ISBN13. 이 앱 전체가 이 값으로 알라딘, 도서관 정보마루 API를 조인한다.
/// String으로 두면 하이픈(-), 자릿수 오류가 조인 실패로 이어지므로
/// 생성시점에 한번 검증한다.

public struct ISBN13: Hashable, Sendable, CustomStringConvertible {
    public let value: String
    
    public init?(_ raw: String) {
        let digits = raw.filter(\.isNumber)
        guard digits.count == 13, digits.hasPrefix("97") else { return nil }
        self.value = digits
    }
    
    public var description: String { value }
}
