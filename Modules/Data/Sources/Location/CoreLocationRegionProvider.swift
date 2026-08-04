//
//  CoreLocationRegionProvider.swift
//  Data
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import CoreLocation
import Domain

/// CoreLocation으로 현재 위치를 얻어 역지오코딩 → 정보나루 지역 코드로 변환한다.
/// 한 번 확정되면 캐시한다(같은 세션에서 위치가 크게 바뀔 일이 드물고, 재측위 비용을 아낌).
/// 권한 거부·측위/지오코딩 실패는 모두 기본 지역(서울)으로 폴백한다.
public actor CoreLocationRegionProvider: RegionProvider {
    private var cached: RegionCode?
    private var cachedFix: CLLocation?
    private var didFix = false      // 측위 실패(nil)도 캐시해야 재시도 폭주를 막는다

    public init() {}

    public func currentRegion() async -> RegionCode {
        if let cached { return cached }
        let resolved = await resolve() ?? .seoul
        cached = resolved
        return resolved
    }

    public func currentCoordinate() async -> CLLocationCoordinate2D? {
        await fix()?.coordinate
    }

    /// 지역 해석과 거리 정렬이 같은 측위 결과를 나눠 쓴다.
    /// 액터 재진입으로 중복 측위가 생기지 않도록 호출부는 순차로 부른다.
    private func fix() async -> CLLocation? {
        if !didFix {
            cachedFix = await firstFix()
            didFix = true
        }
        return cachedFix
    }

    private func resolve() async -> RegionCode? {
        guard let location = await fix() else { return nil }
        guard let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location),
              let area = placemarks.first?.administrativeArea else { return nil }
        return RegionCode(administrativeArea: area)
    }

    /// 최초 유효 위치 하나만 받아 즉시 종료.
    /// iOS 17 CLLocationUpdate는 권한 거부를 노출하는 API가 없어(관련 프로퍼티는 iOS 18+),
    /// 거부/측위 지연은 타임아웃(기본 5초)으로 끊고 상위에서 기본 지역으로 폴백한다.
    private func firstFix(timeout: Duration = .seconds(5)) async -> CLLocation? {
        await withTaskGroup(of: CLLocation?.self) { group in
            group.addTask { await Self.firstLocation() }
            group.addTask { try? await Task.sleep(for: timeout); return nil }
            let result = await group.next() ?? nil
            group.cancelAll()
            return result
        }
    }

    private static func firstLocation() async -> CLLocation? {
        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                if let location = update.location { return location }
            }
        } catch {
            return nil
        }
        return nil
    }
}
