//
//  DetailViewModelTests.swift
//  Feature
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Testing
import Foundation
import CoreLocation
@testable import Feature
import Domain

@MainActor
@Suite struct DetailViewModelTests {

    private let isbn = ISBN13("9788954699914")!

    private var baseBook: Book {
        Book(isbn13: isbn, title: "하얼빈", author: "김훈", publisher: "문학동네")
    }

    private var enrichedBook: Book {
        Book(isbn13: isbn, title: "하얼빈", author: "김훈", publisher: "문학동네",
             bookDescription: "김훈의 신작 장편소설.")
    }

    private var library: Library {
        Library(code: "111456", name: "가락몰도서관", address: "서울 송파구",
                coordinate: CLLocationCoordinate2D(latitude: 37.49, longitude: 127.11),
                closed: "매주 월요일")
    }

    private func makeViewModel(
        onDetail: @escaping @Sendable (ISBN13) async throws -> Book,
        libraries: @escaping @Sendable (ISBN13, RegionCode) async throws -> [Library],
        loanable: @escaping @Sendable (ISBN13, String) async throws -> Bool = { _, _ in true }
    ) -> DetailViewModel {
        let bookSearch = StubBookSearchRepository(onDetail: onDetail)
        let libraryRepo = StubLibraryRepository(onHoldingLibraries: libraries, onLoanStatus: loanable)
        let findHoldings = FindHoldingsUseCase(repository: libraryRepo)
        return DetailViewModel(book: baseBook,
                               bookSearch: bookSearch,
                               findHoldings: findHoldings,
                               regionProvider: StubRegionProvider())
    }

    @Test func 로드_성공시_소개_보강과_소장_도서관을_함께_채운다() async {
        let lib = library
        let enriched = enrichedBook
        let vm = makeViewModel(
            onDetail: { _ in enriched },
            libraries: { _, _ in [lib] },
            loanable: { _, _ in true }
        )

        await vm.load()

        #expect(vm.book.bookDescription == "김훈의 신작 장편소설.")
        guard case .loaded(let holdings) = vm.state else {
            Issue.record("loaded 상태여야 하는데 \(vm.state)"); return
        }
        #expect(holdings.count == 1)
        #expect(holdings.first?.isLoanalbe == true)
    }

    @Test func 소개_보강이_실패해도_기본_book으로_화면을_그린다() async {
        let lib = library
        let vm = makeViewModel(
            onDetail: { _ in throw StubError() },   // 소개 보강 실패
            libraries: { _, _ in [lib] }
        )

        await vm.load()

        #expect(vm.book.bookDescription == nil)     // 기본 book 유지
        guard case .loaded = vm.state else {
            Issue.record("소장 조회는 성공했으므로 loaded여야 함: \(vm.state)"); return
        }
    }

    @Test func 소장_도서관_조회_실패시_failed_상태가_된다() async {
        let enriched = enrichedBook
        let vm = makeViewModel(
            onDetail: { _ in enriched },
            libraries: { _, _ in throw StubError() }   // 소장 조회 실패
        )

        await vm.load()

        guard case .failed = vm.state else {
            Issue.record("failed 상태여야 하는데 \(vm.state)"); return
        }
    }

    @Test func 소장_도서관이_0건이면_빈_loaded가_된다() async {
        let enriched = enrichedBook
        let vm = makeViewModel(
            onDetail: { _ in enriched },
            libraries: { _, _ in [] }
        )

        await vm.load()

        #expect(vm.state == .loaded([]))
    }
}
