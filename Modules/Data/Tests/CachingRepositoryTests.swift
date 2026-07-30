//
//  CachingRepositoryTests.swift
//  DataTests
//
//  Created by SEUNGSOO HAN on 7/30/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Testing
import Foundation
@testable import Data
import Domain

/// 캐싱 데코레이터가 base 호출을 몇 번 위임하는지로 히트/미스를 검증한다.
@Suite("캐싱 데코레이터")
struct CachingRepositoryTests {

    /// 호출 횟수를 세는 스파이. actor로 두어 동시 호출에서도 카운트가 안전하다.
    actor SpyLibraryRepository: LibraryRepository {
        private(set) var holdingsCalls = 0
        private(set) var loanCalls = 0
        let libraries: [Library]

        init(libraries: [Library]) { self.libraries = libraries }

        func holdingLibraries(isbn13: ISBN13, region: RegionCode) async throws -> [Library] {
            holdingsCalls += 1
            return libraries
        }
        func loanStatus(isbn13: ISBN13, libCode: String) async throws -> Bool {
            loanCalls += 1
            return true
        }
    }

    private let isbn = ISBN13("9788954699914")!

    @Test("holdingLibraries 재조회는 base를 다시 부르지 않는다(세션 캐시)")
    func holdingsCachedAcrossCalls() async throws {
        let spy = SpyLibraryRepository(libraries: [Library(code: "lib1", name: "도서관", address: "주소")])
        let sut = CachingLibraryRepository(base: spy)

        _ = try await sut.holdingLibraries(isbn13: isbn, region: .seoul)
        _ = try await sut.holdingLibraries(isbn13: isbn, region: .seoul)

        #expect(await spy.holdingsCalls == 1)
    }

    @Test("loanStatus는 TTL 안에서는 캐시 히트한다")
    func loanCachedWithinTTL() async throws {
        let spy = SpyLibraryRepository(libraries: [])
        // 테스트 실행 시간보다 충분히 긴 TTL → 두 번째는 반드시 히트
        let sut = CachingLibraryRepository(base: spy, loanCache: InMemoryCache(ttl: .seconds(60)))

        _ = try await sut.loanStatus(isbn13: isbn, libCode: "lib1")
        _ = try await sut.loanStatus(isbn13: isbn, libCode: "lib1")

        #expect(await spy.loanCalls == 1)
    }

    @Test("loanStatus는 TTL이 지나면 다시 base를 부른다(신선도)")
    func loanExpiresAfterTTL() async throws {
        let spy = SpyLibraryRepository(libraries: [])
        // 아주 짧은 TTL로 만료를 강제
        let sut = CachingLibraryRepository(base: spy, loanCache: InMemoryCache(ttl: .milliseconds(20)))

        _ = try await sut.loanStatus(isbn13: isbn, libCode: "lib1")
        try await Task.sleep(for: .milliseconds(60))
        _ = try await sut.loanStatus(isbn13: isbn, libCode: "lib1")

        #expect(await spy.loanCalls == 2)
    }

    @Test("서로 다른 도서관은 각각 조회한다(키 분리)")
    func loanKeyedByLibCode() async throws {
        let spy = SpyLibraryRepository(libraries: [])
        let sut = CachingLibraryRepository(base: spy)

        _ = try await sut.loanStatus(isbn13: isbn, libCode: "lib1")
        _ = try await sut.loanStatus(isbn13: isbn, libCode: "lib2")

        #expect(await spy.loanCalls == 2)
    }
}
