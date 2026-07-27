//
//  AppSecrets.swift
//  App
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation

/// Info.plist로 노출된 API 키를 읽는 얇은 래퍼.
/// 키 조립은 App에서만 일어나고, 하위 레이어는 키의 출처를 모른다.
struct AppSecrets {
    let data4LibraryKey: String
    let aladinTTBKey: String

    init(bundle: Bundle = .main) {
        func value(_ key: String) -> String {
            (bundle.object(forInfoDictionaryKey: key) as? String) ?? ""
        }
        self.data4LibraryKey = value("DATA4LIBRARY_KEY")
        self.aladinTTBKey = value("ALADIN_TTB_KEY")
    }
}
