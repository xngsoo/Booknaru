//
//  CacheBenchmarkTests.swift
//  DataTests
//
//  Created by SEUNGSOO HAN on 7/30/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Testing
import Foundation
@testable import Data
import Domain

/// 같은 ISBN 재조회 시 콜드(미스, 네트워크 지연 발생) vs 웜(히트, 메모리) 소요 비교.
/// 네트워크 변수를 배제하려 base에 고정 지연만 준 통제 측정이다.
/// (FindHoldingsBenchmarkTests의 측정 방식을 그대로 따른다.)
@Suite("캐싱 성능")
struct CacheBenchmarkTests {

    /// 호출마다 고정 지연을 주는 base 스텁.
    struct DelayedRepository: LibraryRepository {
        let libraries: [Library]
        let perCallDelay: Duration

        func holdingLibraries(isbn13: ISBN13, region: RegionCode) async throws -> [Library] {
            try await Task.sleep(for: perCallDelay)
            return libraries
        }
        func loanStatus(isbn13: ISBN13, libCode: String) async throws -> Bool {
            try await Task.sleep(for: perCallDelay)
            return true
        }
    }

    @Test("웜 캐시 재조회가 콜드보다 빠르다")
    func warmBeatsCold() async throws {
        let delay = Duration.milliseconds(50)
        let isbn = ISBN13("9788954699914")!
        let libraries = (0..<20).map { Library(code: "lib\($0)", name: "도서관\($0)", address: "주소") }
        let base = DelayedRepository(libraries: libraries, perCallDelay: delay)
        // loanStatus까지 캐시가 유효하도록 넉넉한 TTL
        let sut = CachingLibraryRepository(base: base, loanCache: InMemoryCache(ttl: .seconds(60)))

        // 콜드: 미스 → base 지연 발생
        let cold = try await measure {
            _ = try await sut.holdingLibraries(isbn13: isbn, region: .seoul)
            return try await sut.loanStatus(isbn13: isbn, libCode: "lib0")
        }

        // 웜: 같은 키 재조회 → 메모리 반환
        let warm = try await measure {
            _ = try await sut.holdingLibraries(isbn13: isbn, region: .seoul)
            return try await sut.loanStatus(isbn13: isbn, libCode: "lib0")
        }

        print("BENCH cache delay=50ms cold=\(cold.ms)ms warm=\(warm.ms)ms speedup=\(String(format: "%.1f", cold.ms / max(warm.ms, 0.0001)))x")

        // 웜은 네트워크 왕복 없이 메모리에서 반환되므로 콜드의 절반보다 확실히 빠르다.
        #expect(warm.ms < cold.ms / 2)
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
