//
//  RegionCodeTests.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Testing
@testable import Domain

@Suite("RegionCode 시/도 매핑")
struct RegionCodeTests {

    @Test("시/도명을 정보나루 코드로 매핑한다", arguments: [
        ("서울특별시", "11"),
        ("부산광역시", "21"),
        ("경기도", "31"),
        ("제주특별자치도", "39")
    ])
    func maps(area: String, code: String) {
        #expect(RegionCode(administrativeArea: area)?.value == code)
    }

    @Test("명칭이 바뀐 특별자치도도 매핑한다")
    func mapsRenamedProvinces() {
        #expect(RegionCode(administrativeArea: "강원특별자치도")?.value == "32")
        #expect(RegionCode(administrativeArea: "전북특별자치도")?.value == "35")
    }

    @Test("충청북/충청남을 구분한다")
    func distinguishesChungcheong() {
        #expect(RegionCode(administrativeArea: "충청북도")?.value == "33")
        #expect(RegionCode(administrativeArea: "충청남도")?.value == "34")
    }

    @Test("알 수 없는 지역은 nil")
    func unknownIsNil() {
        #expect(RegionCode(administrativeArea: "도쿄도") == nil)
    }
}
