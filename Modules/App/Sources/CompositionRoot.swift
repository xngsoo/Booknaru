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
    private static let secrets = AppSecrets()

    private static let informClient = URLSessionHTTPClient(
        baseURL: URL(string: "https://data4library.kr/api")!,
        auth: QueryAuthProvider(name: "authKey", key: secrets.data4LibraryKey)
    )
    private static let aladinClient = URLSessionHTTPClient(
        baseURL: URL(string: "https://www.aladin.co.kr/ttb/api")!,
        auth: QueryAuthProvider(name: "ttbkey", key: secrets.aladinTTBKey)
    )

    private static let bookSearch = DefaultBookSearchRepository(
        informClient: informClient,
        aladinClient: aladinClient
    )
    private static let libraryRepository = DefaultLibraryRepository(client: informClient)
    private static let findHoldings = FindHoldingsUseCase(repository: libraryRepository)

    static func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(bookSearch: bookSearch)
    }

    static func makeDetailViewModel(book: Book) -> DetailViewModel {
        DetailViewModel(book: book, bookSearch: bookSearch, findHoldings: findHoldings)
    }
}
