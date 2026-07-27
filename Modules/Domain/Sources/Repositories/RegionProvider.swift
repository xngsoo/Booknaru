//
//  RegionProvider.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

/// 사용자의 현재 지역 코드를 제공한다.
/// 위치 권한 거부·측위 실패 시에도 던지지 않고 기본 지역(서울)으로 폴백한다
/// — 지역은 화면을 못 그릴 만큼 치명적이지 않으므로, 실패를 에러가 아닌 폴백으로 다룬다.
public protocol RegionProvider: Sendable {
    func currentRegion() async -> RegionCode
}
