//
//  Library.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import CoreLocation

public struct Library: Identifiable, Sendable {
    public let code: String
    public let name: String
    public let address: String
    public let coordinate: CLLocationCoordinate2D?   // lat/lng 문자열을 Double로 파싱
    public let phone: String?
    public let homepage: URL?
    public let operatingTime: String?
    
    public var id: String { code }
    
    public init(code: String,
                name: String,
                address: String,
                coordinate: CLLocationCoordinate2D? = nil,
                phone: String? = nil,
                homepage: URL? = nil,
                operatingTime: String? = nil) {
        self.code = code
        self.name = name
        self.address = address
        self.coordinate = coordinate
        self.phone = phone
        self.homepage = homepage
        self.operatingTime = operatingTime
    }
}

// CLLocationCoordinate2D는 Hashable/Equatable 미제공 -> code 기준으로 직접 채택
extension Library: Hashable {
    public static func == (l: Library, r: Library) -> Bool {
        l.code == r.code
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}
