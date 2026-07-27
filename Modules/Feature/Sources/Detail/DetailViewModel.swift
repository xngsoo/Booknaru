//
//  DetailViewModel.swift
//  Feature
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import Observation
import Domain

/// 상세 화면. 검색에서 넘어온 기본 Book을 들고 시작해,
/// 알라딘 소개 보강과 소장 도서관 조회를 병렬로 수행한다.
@Observable
public final class DetailViewModel {
    public enum State: Equatable {
        case loading
        case loaded([LibraryHolding])
        case failed(String)
    }

    /// 소개는 보강 실패해도 기본 정보로 화면을 그린다. 그래서 book은 항상 존재.
    public private(set) var book: Book
    public private(set) var state: State = .loading

    private let bookSearch: any BookSearchRepository
    private let findHoldings: FindHoldingsUseCase
    private let region: RegionCode

    public init(book: Book,
                bookSearch: any BookSearchRepository,
                findHoldings: FindHoldingsUseCase,
                region: RegionCode = .seoul) {
        self.book = book
        self.bookSearch = bookSearch
        self.findHoldings = findHoldings
        self.region = region
    }

    public func load() async {
        state = .loading
        // 소개 보강과 소장 도서관 조회는 서로 독립 → 동시에.
        async let enriched = enrichedBook()
        async let holdingsResult = holdings()

        book = await enriched   // 실패 시 기존 book 그대로
        do {
            state = .loaded(try await holdingsResult)
        } catch {
            state = .failed("소장 도서관을 불러오지 못했습니다.")
        }
    }

    /// 소개 보강은 실패해도 화면을 막지 않는다(기본 book으로 폴백).
    private func enrichedBook() async -> Book {
        (try? await bookSearch.detail(isbn13: book.isbn13)) ?? book
    }

    private func holdings() async throws -> [LibraryHolding] {
        try await findHoldings(isbn13: book.isbn13, region: region)
    }
}
