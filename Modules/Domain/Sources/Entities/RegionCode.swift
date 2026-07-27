//
//  RegionCode.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.

/// 정보나루 지역 코드 (11=서울, 21=부산 ..)
/// libSrchByBook은 위경도 반경이 아닌 이 코드로 필터링 한다.

public struct RegionCode: Hashable, Sendable {
    public let value: String
    
    public init(_ value: String) { self.value = value }
    
    public static let seoul = RegionCode("11")
}
