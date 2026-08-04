//
//  FindHoldingsUseCase.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

/// 소장 도서관 N곳을 구한 뒤, 각 도서관의 대출 가능 여부를 병렬로 조회해
/// LibraryHolding 목록을 만든다. 이 병렬 조회가 프로젝트 핵심 최적화 지점이다.

import CoreLocation

public struct FindHoldingsUseCase: Sendable {
    private let repository: any LibraryRepository

    public init(repository: any LibraryRepository) {
        self.repository = repository
    }

    /// - Parameter origin: 현재 위치. 있으면 가까운 순으로 정렬하고, 없으면 이름순.
    ///   TaskGroup 수집 순서는 응답 도착 순(= 매번 다름)이라 정렬은 선택이 아니라 필수다.
    public func callAsFunction(isbn13: ISBN13,
                               region: RegionCode,
                               from origin: CLLocationCoordinate2D? = nil) async throws -> [LibraryHolding] {
        let libraries = try await repository.holdingLibraries(isbn13: isbn13, region: region)

        // 도서관 N곳의 bookExist를 동시에. Domain이 nonisolated라 메인에 묶이지 않는다.
        let holdings = try await withThrowingTaskGroup(of: LibraryHolding.self) { group in
            for library in libraries {
                group.addTask {
                    let loanable = try await repository.loanStatus(isbn13: isbn13, libCode: library.code)
                    return LibraryHolding(library: library,
                                          isLoanable: loanable,
                                          distance: distance(from: origin, to: library.coordinate))
                }
            }
            var result: [LibraryHolding] = []
            for try await holding in group {
                result.append(holding)
            }
            return result
        }
        return holdings.sorted(by: nearerFirst)
    }

    /// 도로 거리가 아닌 직선 거리. 목록에서 "어디가 더 가까운지" 가리는 데는 충분하고,
    /// 경로 API를 도서관 수만큼 부르는 비용을 피한다.
    private func distance(from origin: CLLocationCoordinate2D?,
                          to target: CLLocationCoordinate2D?) -> CLLocationDistance? {
        guard let origin, let target else { return nil }
        return CLLocation(latitude: origin.latitude, longitude: origin.longitude)
            .distance(from: CLLocation(latitude: target.latitude, longitude: target.longitude))
    }

    /// 거리 아는 곳이 가까운 순으로 먼저, 모르는 곳은 뒤에. 동률·미측위는 이름순으로 고정해
    /// 같은 입력이면 항상 같은 순서가 되게 한다.
    private func nearerFirst(_ lhs: LibraryHolding, _ rhs: LibraryHolding) -> Bool {
        switch (lhs.distance, rhs.distance) {
        case let (l?, r?): return l == r ? lhs.library.name < rhs.library.name : l < r
        case (_?, nil): return true
        case (nil, _?): return false
        case (nil, nil): return lhs.library.name < rhs.library.name
        }
    }
}
