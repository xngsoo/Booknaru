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

    /// CLPlacemark.administrativeArea(예: "서울특별시", "경기도", "제주특별자치도") → 정보나루 코드.
    /// 시/도 명칭 변경(강원/전북 특별자치도 등)에 견디도록 키워드 포함 여부로 매칭한다.
    public init?(administrativeArea: String) {
        let table: [(keyword: String, code: String)] = [
            ("서울", "11"), ("부산", "21"), ("대구", "22"), ("인천", "23"),
            ("광주", "24"), ("대전", "25"), ("울산", "26"), ("세종", "29"),
            ("경기", "31"), ("강원", "32"),
            ("충청북", "33"), ("충북", "33"), ("충청남", "34"), ("충남", "34"),
            ("전라북", "35"), ("전북", "35"), ("전라남", "36"), ("전남", "36"),
            ("경상북", "37"), ("경북", "37"), ("경상남", "38"), ("경남", "38"),
            ("제주", "39")
        ]
        guard let match = table.first(where: { administrativeArea.contains($0.keyword) }) else {
            return nil
        }
        self.init(match.code)
    }
}
