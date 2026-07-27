//
//  LibraryRepository.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

public protocol LibraryRepository: Sendable {
    /// 이 책을 소장한 도서관 목록 (대출 가능 여부는 아직 모름)
    func holdingLibraries(isbn13: ISBN13, region: RegionCode) async throws -> [Library]
    
    /// 특정 도서관에서 지금 대출 가능한지
    func loanStatus(isbn13: ISBN13, libCode: String) async throws -> Bool
}
