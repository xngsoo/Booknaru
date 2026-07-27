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
    var onSearch: @Sendable (String) async throws -> [Book] = { _ in [] }
    var onDetail: @Sendable (ISBN13) async throws -> Book = { _ in throw StubError() }

    func search(keyword: String) async throws -> [Book] {
        try await onSearch(keyword)
    }

    func detail(isbn13: ISBN13) async throws -> Book {
        try await onDetail(isbn13)
    }
}

/// FindHoldingsUseCase 주입용 스텁.
struct StubLibraryRepository: LibraryRepository {
    var onHoldingLibraries: @Sendable (ISBN13, RegionCode) async throws -> [Library] = { _, _ in [] }
    var onLoanStatus: @Sendable (ISBN13, String) async throws -> Bool = { _, _ in false }

    func holdingLibraries(isbn13: ISBN13, region: RegionCode) async throws -> [Library] {
        try await onHoldingLibraries(isbn13, region)
    }

    func loanStatus(isbn13: ISBN13, libCode: String) async throws -> Bool {
        try await onLoanStatus(isbn13, libCode)
    }
}

/// 위치 해석을 대신하는 스텁. 테스트는 항상 고정 지역을 준다.
struct StubRegionProvider: RegionProvider {
    var region: RegionCode = .seoul
    func currentRegion() async -> RegionCode { region }
}

struct StubError: Error {}
