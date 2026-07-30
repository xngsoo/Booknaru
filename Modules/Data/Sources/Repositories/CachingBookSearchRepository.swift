//
//  CachingBookSearchRepository.swift
//  Data
//
//  Created by SEUNGSOO HAN on 7/30/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Domain

/// BookSearchRepository에 캐싱을 얹는 데코레이터. base(실제 구현)를 감싸기만 하므로
/// Feature/Domain은 이 존재를 모르고, 조립은 CompositionRoot 한 곳에서만 바뀐다.
///
/// - `detail` : 서지·소개는 세션 중 불변 → ISBN13 키로 세션 캐시.
/// - `search` : 검색어는 재조회 패턴이 약해 캐싱 이득이 낮음 → 패스스루.
public struct CachingBookSearchRepository: BookSearchRepository {
    private let base: any BookSearchRepository
    private let detailCache: InMemoryCache<String, Book>

    public init(base: any BookSearchRepository,
                detailCache: InMemoryCache<String, Book> = InMemoryCache()) {
        self.base = base
        self.detailCache = detailCache
    }

    public func search(keyword: String) async throws -> [Book] {
        try await base.search(keyword: keyword)
    }

    public func detail(isbn13: ISBN13) async throws -> Book {
        if let cached = await detailCache.value(for: isbn13.value) {
            return cached
        }
        let book = try await base.detail(isbn13: isbn13)
        await detailCache.insert(book, for: isbn13.value)
        return book
    }
}
