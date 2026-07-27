//
//  SearchViewModel.swift
//  Feature
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import Observation
import Domain

/// 검색 화면 상태. Feature는 Data를 모르고 Domain 프로토콜(BookSearchRepository)에만 의존한다.
/// 실제 구현체 주입은 App(CompositionRoot)이 생성자로 넣어준다.
@Observable
public final class SearchViewModel {
    public enum State: Equatable {
        case idle
        case loading
        case loaded([Book])
        case empty            // 검색은 성공했지만 결과 0건
        case failed(String)
    }

    public private(set) var state: State = .idle
    public var keyword: String = ""

    private let bookSearch: any BookSearchRepository

    public init(bookSearch: any BookSearchRepository) {
        self.bookSearch = bookSearch
    }

    public func search() async {
        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        state = .loading
        do {
            // await 지점에서 nonisolated인 Data 레이어로 넘어가 네트워크는 메인 밖에서 돈다.
            let books = try await bookSearch.search(keyword: trimmed)
            state = books.isEmpty ? .empty : .loaded(books)
        } catch {
            state = .failed("검색에 실패했습니다. 잠시 후 다시 시도해 주세요.")
        }
    }
}
