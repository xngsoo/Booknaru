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
        #expect(result.first { $0.id == "111456"}?.isLoanable == false)
        #expect(result.first { $0.id == "111108"}?.isLoanable == true)
    }

    // 좌표: 서울시청(37.566, 126.978) 기준으로 가까운 순 = 가온 → 남산 → 가락몰
    private var scattered: [Library] {
        [
            Library(code: "A", name: "가락몰도서관", address: "송파구",
                    coordinate: .init(latitude: 37.492, longitude: 127.118)),   // ~13km
            Library(code: "B", name: "가온도서관", address: "중구",
                    coordinate: .init(latitude: 37.568, longitude: 126.982)),   // ~0.4km
            Library(code: "C", name: "남산도서관", address: "용산구",
                    coordinate: .init(latitude: 37.551, longitude: 126.981))    // ~1.7km
        ]
    }

    @Test("현재 위치가 있으면 가까운 순으로 정렬한다")
    func sortsByDistance() async throws {
        let sut = FindHoldingsUseCase(repository: StubRepository(library: scattered, loanable: [:]))
        let result = try await sut(isbn13: ISBN13("9788934972464")!,
                                   region: .seoul,
                                   from: .init(latitude: 37.566, longitude: 126.978))

        #expect(result.map(\.id) == ["B", "C", "A"])
        #expect(result[0].distance ?? .infinity < 1_000)
    }

    @Test("좌표 없는 도서관은 뒤로, 측위 실패 시엔 이름순으로 고정된다")
    func fallsBackToNameOrder() async throws {
        let libs = scattered + [Library(code: "D", name: "가나도서관", address: "무좌표")]

        let noFix = FindHoldingsUseCase(repository: StubRepository(library: libs, loanable: [:]))
        let byName = try await noFix(isbn13: ISBN13("9788934972464")!, region: .seoul)
        #expect(byName.map(\.library.name) == ["가나도서관", "가락몰도서관", "가온도서관", "남산도서관"])
        #expect(byName.allSatisfy { $0.distance == nil })

        let withFix = try await noFix(isbn13: ISBN13("9788934972464")!,
                                      region: .seoul,
                                      from: .init(latitude: 37.566, longitude: 126.978))
        #expect(withFix.map(\.id) == ["B", "C", "A", "D"])   // 좌표 없는 D는 항상 끝
    }
}
