//
//  BookExistResponse.swift
//  Data
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation

struct BookExistResponse: Decodable {
    let response: ResponseBody
    
    struct ResponseBody: Decodable {
        let result: Result
    }
    struct Result: Decodable {
        let hasBook: String
        let loanAvailable: String
    }
}
