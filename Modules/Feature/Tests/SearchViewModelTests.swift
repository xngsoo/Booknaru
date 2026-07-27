//
//  SearchViewModelTests.swift
//  Feature
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Testing
import Foundation
@testable import Feature
import Domain

@MainActor
@Suite struct SearchViewModelTests {

    private let sampleBook = Book(
        isbn13: ISBN13("9788954699914")!,
        title: "하얼빈",
        author: "김훈",
        publisher: "문학동네"
    )

    @Test func 검색_성공시_loaded_상태가_된다() async {
        let book = sampleBook
        let vm = SearchViewModel(bookSearch: StubBookSearchRepository(onSearch: { _ in [book] }))
        vm.keyword = "하얼빈"

        await vm.search()

        #expect(vm.state == .loaded([book]))
    }

    @Test func 결과가_0건이면_empty_상태가_된다() async {
        let vm = SearchViewModel(bookSearch: StubBookSearchRepository(onSearch: { _ in [] }))
        vm.keyword = "존재하지않는책"

        await vm.search()

        #expect(vm.state == .empty)
    }

    @Test func 검색이_실패하면_failed_상태가_된다() async {
        let vm = SearchViewModel(bookSearch: StubBookSearchRepository(onSearch: { _ in throw StubError() }))
        vm.keyword = "하얼빈"

        await vm.search()

        guard case .failed = vm.state else {
            Issue.record("failed 상태여야 하는데 \(vm.state)")
            return
        }
    }

    @Test func 공백_키워드는_검색하지_않고_idle을_유지한다() async {
        // 호출되면 실패시켜, 가드가 실제로 막았음을 상태(idle)로 증명한다
        let vm = SearchViewModel(bookSearch: StubBookSearchRepository(onSearch: { _ in
            Issue.record("공백 키워드에서는 search가 호출되면 안 된다")
            return []
        }))
        vm.keyword = "   "

        await vm.search()

        #expect(vm.state == .idle)
    }

    @Test func 검색어_앞뒤_공백은_제거되어_전달된다() async {
        let received = KeywordBox()
        let vm = SearchViewModel(bookSearch: StubBookSearchRepository(onSearch: { keyword in
            await received.set(keyword)
            return []
        }))
        vm.keyword = "  하얼빈  "

        await vm.search()

        #expect(await received.value == "하얼빈")
    }
}

/// @Sendable 클로저에서 안전하게 값을 담기 위한 액터 박스
private actor KeywordBox {
    private(set) var value: String?
    func set(_ v: String) { value = v }
}
