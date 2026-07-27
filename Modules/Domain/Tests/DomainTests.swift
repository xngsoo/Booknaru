import Testing
import Foundation
@testable import Domain

@Suite("ISBN13 검증")
struct ISBN13Tests {
    @Test("하이픈이 포함돼도 숫자만 추출") func stripsHyphens() {
        #expect(ISBN13("978-89-134-7293-4")?.value == "9788913472934")
    }
    @Test("13자리 아니면 실패") func rejectWrongLength() {
        #expect(ISBN13("12345") == nil)
    }
    @Test("978/979로 시작 안 하면 실패") func rejectBadPrefix() {
        #expect(ISBN13("1234-5678904567890") == nil)
    }
}

@Suite("FindHoldingsUseCase")
struct FindHoldingsUseCaseTests {
    // 도메인은 Data를 모르므로 프로토콜만으로 Mock을 주입해 테스트한다.
    struct StubRepository: LibraryRepository {
        let library: [Library]
        let loanable: [String: Bool]
        
        func holdingLibraries(isbn13: ISBN13, region: RegionCode) async throws -> [Library] {
            library
        }
        func loanStatus(isbn13: ISBN13, libCode: String) async throws -> Bool {
            loanable[libCode] ?? false
        }
    }
    
    @Test("소장 도서관마다 대출 여부를 조합해 반환한다")
    func combineHoldings() async throws {
        let libs = [
            Library(code: "111456", name: "가락몰도서관", address: "송파구"),
            Library(code: "111108", name: "가온도서관", address: "중구")
        ]
        let sut = FindHoldingsUseCase(
            repository: StubRepository(library: libs, loanable: ["111456": false, "111108": true])
        )
        let result = try await sut(isbn13: ISBN13("9788934972464")!, region: .seoul)
        
        #expect(result.count == 2)
        #expect(result.first { $0.id == "111456"}?.isLoanalbe == false)
        #expect(result.first { $0.id == "111108"}?.isLoanalbe == true)
    }
}
