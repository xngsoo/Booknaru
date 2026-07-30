//
//  FindHoldingsUseCase.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

/// 소장 도서관 N곳을 구한 뒤, 각 도서관의 대출 가능 여부를 병렬로 조회해
/// LibraryHolding 목록을 만든다. 이 병렬 조회가 프로젝트 핵심 최적화 지점이다.

public struct FindHoldingsUseCase: Sendable {
    private let repository: any LibraryRepository

    public init(repository: any LibraryRepository) {
        self.repository = repository
    }

    public func callAsFunction(isbn13: ISBN13, region: RegionCode) async throws -> [LibraryHolding] {
        let libraries = try await repository.holdingLibraries(isbn13: isbn13, region: region)

        // 도서관 N곳의 bookExist를 동시에. Domain이 nonisolated라 메인에 묶이지 않는다.
        return try await withThrowingTaskGroup(of: LibraryHolding.self) { group in
            for library in libraries {
                group.addTask {
                    let loanable = try await repository.loanStatus(isbn13: isbn13, libCode: library.code)
                    return LibraryHolding(library: library, isLoanable: loanable)
                }
            }
            var result: [LibraryHolding] = []
            for try await holding in group {
                result.append(holding)
            }
            return result
        }
    }
}
