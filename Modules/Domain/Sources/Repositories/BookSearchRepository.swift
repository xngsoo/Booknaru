//
//  BookSearchRepository.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

public protocol BookSearchRepository: Sendable {
    func search(keyword: String) async throws -> [Book]
    func detail(isbn13: ISBN13) async throws -> Book    // 2차 API로 소개 보강
}
