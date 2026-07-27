//
//  CompositionRoot.swift
//  App
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation
import Domain
import Data
import Feature

/// 의존성 조립이 일어나는 유일한 지점.
/// 키 → AuthProvider → HTTPClient → Repository → UseCase → ViewModel 순으로 조립해
/// 완성된 ViewModel을 생성자 주입으로 화면에 넘긴다.
/// Feature는 여기서 조립된 Domain 타입만 받고, Data 구현체는 이 파일 밖으로 새지 않는다.
@MainActor
enum CompositionRoot {
    private static let data4LibraryBaseURL = URL(string: "https://data4library.kr/api")!
    private static let aladinBaseURL = URL(string: "https://www.aladin.co.kr/ttb/api")!

    static func makeSearchViewModel() -> SearchViewModel {
        let secrets = AppSecrets()

        let informClient = URLSessionHTTPClient(
            baseURL: data4LibraryBaseURL,
            auth: QueryAuthProvider(name: "authKey", key: secrets.data4LibraryKey)
        )
        let aladinClient = URLSessionHTTPClient(
            baseURL: aladinBaseURL,
            auth: QueryAuthProvider(name: "ttbkey", key: secrets.aladinTTBKey)
        )

        let bookSearch = DefaultBookSearchRepository(
            informClient: informClient,
            aladinClient: aladinClient
        )
        return SearchViewModel(bookSearch: bookSearch)
    }
}
