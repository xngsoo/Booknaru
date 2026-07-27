//
//  FindHoldingsBenchmarkTests.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Testing
import Foundation
@testable import Domain

/// 순차 조회 vs FindHoldingsUseCase(TaskGroup 병렬) 소요 시간 비교.
/// 네트워크 변수를 배제하기 위해 도서관당 고정 지연(loanStatus)만 준 통제 측정이다.
@Suite("FindHoldings 성능")
struct FindHoldingsBenchmarkTests {

    /// loanStatus 한 건마다 고정 지연을 주는 스텁. holdingLibraries는 즉시 반환.
    struct DelayedRepository: LibraryRepository {
        let libraries: [Library]
        let perCallDelay: Duration

        func holdingLibraries(isbn13: ISBN13, region: RegionCode) async throws -> [Library] {
            libraries
        }
        func loanStatus(isbn13: ISBN13, libCode: String) async throws -> Bool {
            try await Task.sleep(for: perCallDelay)
            return true
        }
    }

    @Test("병렬 조회가 순차 조회보다 빠르다")
    func parallelBeatsSequential() async throws {
        let count = 20
        let delay = Duration.milliseconds(50)
        let isbn = ISBN13("9788954699914")!
        let libraries = (0..<count).map {
            Library(code: "lib\($0)", name: "도서관\($0)", address: "주소")
        }
        let repo = DelayedRepository(libraries: libraries, perCallDelay: delay)

        // 순차: 도서관 N곳을 하나씩 await
        let sequential = try await measure {
            var holdings: [LibraryHolding] = []
            for library in libraries {
                let loanable = try await repo.loanStatus(isbn13: isbn, libCode: library.code)
                holdings.append(LibraryHolding(library: library, isLoanalbe: loanable))
            }
            return holdings.count
        }

        // 병렬: FindHoldingsUseCase (TaskGroup)
        let sut = FindHoldingsUseCase(repository: repo)
        let parallel = try await measure {
            try await sut(isbn13: isbn, region: .seoul).count
        }

        print("BENCH count=\(count) delay=50ms sequential=\(sequential.ms)ms parallel=\(parallel.ms)ms speedup=\(String(format: "%.1f", sequential.ms / parallel.ms))x")

        #expect(sequential.value == count)
        #expect(parallel.value == count)
        // 병렬이 순차의 절반보다 확실히 빠르면 병렬화가 유효한 것
        #expect(parallel.ms < sequential.ms / 2)
    }

    // MARK: - 측정 헬퍼

    private func measure<T>(_ work: () async throws -> T) async rethrows -> (value: T, ms: Double) {
        let clock = ContinuousClock()
        let start = clock.now
        let value = try await work()
        let elapsed = clock.now - start
        let c = elapsed.components
        let ms = Double(c.seconds) * 1000 + Double(c.attoseconds) / 1_000_000_000_000_000
        return (value, ms)
    }
}
