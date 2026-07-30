import Foundation

extension String {
    /// API가 HTML 이스케이프한 텍스트(`&lt;` `&middot;` `&#39;` 등)를 사람이 읽는 문자로 되돌린다.
    /// 정보나루 운영시간·알라딘 소개 등에 엔티티가 섞여 들어와 화면에 그대로 노출되는 것을 막는다.
    /// nonisolated에서 도는 순수 문자열 처리(NSAttributedString HTML 파서를 피함).
    var htmlUnescaped: String {
        guard contains("&") else { return self }   // 흔한 경우 빠른 반환

        var result = ""
        result.reserveCapacity(count)
        var index = startIndex

        while index < endIndex {
            let character = self[index]
            if character == "&",
               let semicolon = self[index...].firstIndex(of: ";"),
               distance(from: index, to: semicolon) <= 10 {   // 엔티티는 짧다. 길면 '&' 그대로.
                let body = String(self[self.index(after: index)..<semicolon])
                if let decoded = Self.decode(body) {
                    result.append(decoded)
                    index = self.index(after: semicolon)
                    continue
                }
            }
            result.append(character)
            index = self.index(after: index)
        }
        return result
    }

    /// `&`와 `;` 사이 본문을 문자로 해석. 모르면 nil(원문 유지).
    private static func decode(_ body: String) -> Character? {
        if body.hasPrefix("#") {   // 숫자 참조: &#39; / &#x2019;
            let number = body.dropFirst()
            let value: UInt32?
            if number.hasPrefix("x") || number.hasPrefix("X") {
                value = UInt32(number.dropFirst(), radix: 16)
            } else {
                value = UInt32(number, radix: 10)
            }
            guard let value, let scalar = Unicode.Scalar(value) else { return nil }
            return Character(scalar)
        }
        return named[body]
    }

    private static let named: [String: Character] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'",
        "nbsp": "\u{00A0}", "middot": "\u{00B7}", "hellip": "\u{2026}",
        "ndash": "\u{2013}", "mdash": "\u{2014}",
        "lsquo": "\u{2018}", "rsquo": "\u{2019}",
        "ldquo": "\u{201C}", "rdquo": "\u{201D}",
        "copy": "\u{00A9}", "reg": "\u{00AE}", "trade": "\u{2122}", "deg": "\u{00B0}"
    ]
}
