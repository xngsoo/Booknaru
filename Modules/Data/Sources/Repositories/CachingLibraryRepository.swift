//
//  CachingLibraryRepository.swift
//  Data
//
//  Created by SEUNGSOO HAN on 7/30/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Domain

/// LibraryRepository에 캐싱을 얹는 데코레이터.
///
/// - `holdingLibraries` : 소장 도서관 목록은 사실상 불변 → (ISBN13, region) 키로 세션 캐시.
/// - `loanStatus`       : 대출 가능 여부는 반납/대출로 자주 바뀜 → 60초 TTL로
///   상세 화면 내 재진입은 절감하되 반납 반영은 놓치지 않는 절충. (근거: docs/DECISIONS.md)
public struct CachingLibraryRepository: LibraryRepository {
    private let base: any LibraryRepository
    private let holdingsCache: InMemoryCache<String, [Library]>
    private let loanCache: InMemoryCache<String, Bool>

    public init(base: any LibraryRepository,
                holdingsCache: InMemoryCache<String, [Library]> = InMemoryCache(),
                loanCache: InMemoryCache<String, Bool> = InMemoryCache(ttl: .seconds(60))) {
        self.base = base
        self.holdingsCache = holdingsCache
        self.loanCache = loanCache
    }

    public func holdingLibraries(isbn13: ISBN13, region: RegionCode) async throws -> [Library] {
        let key = "\(isbn13.value)|\(region.value)"
        if let cached = await holdingsCache.value(for: key) {
            return cached
        }
        let libraries = try await base.holdingLibraries(isbn13: isbn13, region: region)
        await holdingsCache.insert(libraries, for: key)
        return libraries
    }

    public func loanStatus(isbn13: ISBN13, libCode: String) async throws -> Bool {
        let key = "\(isbn13.value)|\(libCode)"
        if let cached = await loanCache.value(for: key) {
            return cached
        }
        let loanable = try await base.loanStatus(isbn13: isbn13, libCode: libCode)
        await loanCache.insert(loanable, for: key)
        return loanable
    }
}
