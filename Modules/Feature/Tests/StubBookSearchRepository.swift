//
//  StubBookSearchRepository.swift
//  Feature
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import Domain

/// 생성자 주입 덕분에 실제 네트워크 없이 ViewModel을 테스트할 수 있다.
/// Domain 프로토콜만 채택하므로 Feature는 Data를 몰라도 된다.
struct StubBookSearchRepository: BookSearchRepository {
    let onSearch: @Sendable (String) async throws -> [Book]

    func search(keyword: String) async throws -> [Book] {
        try await onSearch(keyword)
    }

    func detail(isbn13: ISBN13) async throws -> Book {
        fatalError("이 테스트에서는 detail을 사용하지 않는다")
    }
}

struct StubError: Error {}
