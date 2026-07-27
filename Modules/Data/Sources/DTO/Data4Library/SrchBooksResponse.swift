import Foundation

/// 정보나루 srchBooks 응답
struct SrchBooksResponse: Decodable {
    let response: ResponseBody
    
    struct ResponseBody: Decodable {
        let docs: [DocEnvelope]
    }
    struct DocEnvelope: Decodable {
        let doc: BookDoc
    }
    struct BookDoc: Decodable {
        let bookname: String
        let authors: String
        let publisher: String
        let publication_year: String?
        let isbn13: String
        let vol: String?
        let bookImageURL: String?
    }
}
