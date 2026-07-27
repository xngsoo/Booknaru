import Foundation

/// 알라딘 ItemLookUp(상품 조회) 응답. output=js 이면 JSON.
/// { "item": [ { "title": ..., "description": ..., "cover": ..., ... } ] }
struct AladinItemResponse: Decodable {
    let item: [Item]

    struct Item: Decodable {
        let title: String
        let author: String
        let publisher: String
        let isbn13: String
        let cover: String?
        let description: String?   // 이 앱이 알라딘에서 얻는 목표: 책 소개
        let pubDate: String?
    }
}
