import Foundation
import Domain

public struct DefaultLibraryRepository: LibraryRepository {
    private let client: any HTTPClient   // 정보나루 전용 클라이언트

    public init(client: any HTTPClient) {
        self.client = client
    }

    public func holdingLibraries(isbn13: ISBN13, region: RegionCode) async throws -> [Library] {
        let endpoint = Endpoint(path: "libSrchByBook", queryItems: [
            .init(name: "isbn", value: isbn13.value),
            .init(name: "region", value: region.value),
            .init(name: "format", value: "json")
        ])
        let dto: LibSrchByBookResponse = try await client.send(endpoint)
        return dto.response.libs.map { Library($0.lib) }
    }

    public func loanStatus(isbn13: ISBN13, libCode: String) async throws -> Bool {
        let endpoint = Endpoint(path: "bookExist", queryItems: [
            .init(name: "isbn13", value: isbn13.value),
            .init(name: "libCode", value: libCode),
            .init(name: "format", value: "json")
        ])
        let dto: BookExistResponse = try await client.send(endpoint)
        return dto.response.result.loanAvailable == "Y"
    }
}
