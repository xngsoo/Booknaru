//
//  LibSrchByBookResponse.swift
//  Data
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation

struct LibSrchByBookResponse: Decodable {
    let response: ResponseBody
    
    struct ResponseBody: Decodable {
        let libs: [LibEnvelope]
    }
    struct LibEnvelope: Decodable {
        let lib: LibDoc
    }
    struct LibDoc: Decodable {
        let libCode: String
        let libName: String
        let address: String
        let tel: String?
        let latitude: String?
        let longitude: String?
        let homepage: String?
        let operatingTime: String?
        let closed: String?
    }
}
