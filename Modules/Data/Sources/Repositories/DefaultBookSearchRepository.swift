import Foundation
import Domain

public struct DefaultBookSearchRepository: BookSearchRepository {
    private let informClient: any HTTPClient   // 정보나루: 검색·기본정보
    private let aladinClient: any HTTPClient    // 알라딘: 소개 보강

    public init(informClient: any HTTPClient, aladinClient: any HTTPClient) {
        self.informClient = informClient
        self.aladinClient = aladinClient
    }

    public func search(keyword: String) async throws -> [Book] {
        let endpoint = Endpoint(path: "srchBooks", queryItems: [
            .init(name: "keyword", value: keyword),
            .init(name: "format", value: "json")
        ])
        let dto: SrchBooksResponse = try await informClient.send(endpoint)
        return dto.response.docs.compactMap { Book($0.doc) }
    }

    public func detail(isbn13: ISBN13) async throws -> Book {
        // 정보나루 기본정보와 알라딘 소개는 독립 → 동시에 요청(async let)
        async let base = fetchBase(isbn13: isbn13)
        async let description = fetchDescription(isbn13: isbn13)
        return try await base.withDescription(description)
    }

    // MARK: - Private

    private func fetchBase(isbn13: ISBN13) async throws -> Book {
        let endpoint = Endpoint(path: "srchBooks", queryItems: [
            .init(name: "isbn13", value: isbn13.value),
            .init(name: "format", value: "json")
        ])
        let dto: SrchBooksResponse = try await informClient.send(endpoint)
        guard let doc = dto.response.docs.first, let book = Book(doc.doc) else {
            throw NetworkError.invalidResponse
        }
        return book
    }

    private func fetchDescription(isbn13: ISBN13) async throws -> String? {
        // 알라딘 ItemLookUp.aspx?ttbkey=..&itemIdType=ISBN13&ItemId=..&output=js&Version=20131101
        let endpoint = Endpoint(path: "ItemLookUp.aspx", queryItems: [
            .init(name: "itemIdType", value: "ISBN13"),
            .init(name: "ItemId", value: isbn13.value),
            .init(name: "output", value: "js"),
            .init(name: "Version", value: "20131101")
        ])
        let dto: AladinItemResponse = try await aladinClient.send(endpoint)
        return dto.item.first?.description?.htmlUnescaped
    }
}
