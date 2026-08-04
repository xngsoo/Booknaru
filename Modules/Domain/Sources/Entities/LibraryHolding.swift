//
//  LibraryHolding.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

/// 화면의 최종 데이터: "이 도서관에 있고, 지금 빌릴 수 있는지"
/// libSrchByBook(소장) + bookExist(대출가능)를 UseCase가 조합해 만든다.

import CoreLocation

public struct LibraryHolding: Identifiable, Hashable, Sendable {
    public let library: Library
    public let isLoanable: Bool
    /// 현재 위치에서의 직선 거리(m). 측위 실패 또는 도서관 좌표 미제공이면 nil.
    public let distance: CLLocationDistance?
    public var id: String { library.code }

    public init(library: Library, isLoanable: Bool, distance: CLLocationDistance? = nil) {
        self.library = library
        self.isLoanable = isLoanable
        self.distance = distance
    }
}
