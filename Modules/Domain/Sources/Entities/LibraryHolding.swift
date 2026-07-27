//
//  LibraryHolding.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

/// 화면의 최종 데이터: "이 도서관에 있고, 지금 빌릴 수 있는지"
/// libSrchByBook(소장) + bookExist(대출가능)를 UseCase가 조합해 만든다.

public struct LibraryHolding: Identifiable, Hashable, Sendable {
    public let library: Library
    public let isLoanalbe: Bool
    public var id: String { library.code }
    
    public init(library: Library, isLoanalbe: Bool) {
        self.library = library
        self.isLoanalbe = isLoanalbe
    }
}
