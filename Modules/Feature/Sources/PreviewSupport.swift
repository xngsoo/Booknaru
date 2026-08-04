//
//  PreviewSupport.swift
//  Feature
//
//  Created by SEUNGSOO HAN on 7/31/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

#if DEBUG
import Foundation
import CoreLocation
import Domain

// 프리뷰 전용 스텁·샘플. Sources에 있어 Tests의 스텁을 못 쓰므로 여기 최소한만 둔다.
// Feature는 기본 격리가 MainActor라, Sendable 리포지토리에서 읽으려면 nonisolated.

nonisolated let previewBooks: [Book] = [
    Book(isbn13: ISBN13("9788934972464")!, title: "클린 아키텍처",
         author: "글: 로버트 마틴", publisher: "인사이트", publicationYear: "2019",
         bookDescription: "소프트웨어 구조와 설계의 원칙을 다룬 책입니다. 프리뷰용 샘플 소개 문구."),
    Book(isbn13: ISBN13("9791162540640")!, title: "오브젝트",
         author: "글: 조영호", publisher: "위키북스", publicationYear: "2019"),
    Book(isbn13: ISBN13("9788954682152")!, title: "사피엔스",
         author: "글: 유발 하라리", publisher: "김영사", publicationYear: "2015")
]

struct PreviewBookSearchRepository: BookSearchRepository {
    func search(keyword: String) async throws -> [Book] { previewBooks }
    func detail(isbn13: ISBN13) async throws -> Book {
        previewBooks.first { $0.isbn13 == isbn13 } ?? previewBooks[0]
    }
}

struct PreviewLibraryRepository: LibraryRepository {
    func holdingLibraries(isbn13: ISBN13, region: RegionCode) async throws -> [Library] {
        [
            Library(code: "111001", name: "남산도서관", address: "서울 용산구 소월로 109",
                    coordinate: .init(latitude: 37.551, longitude: 126.981),
                    operatingTime: "09:00~18:00"),
            Library(code: "111002", name: "정독도서관", address: "서울 종로구 북촌로5길 48",
                    coordinate: .init(latitude: 37.581, longitude: 126.983),
                    closed: "매월 첫째·셋째 수요일 휴관")
        ]
    }
    func loanStatus(isbn13: ISBN13, libCode: String) async throws -> Bool {
        libCode == "111001"
    }
}

struct PreviewRegionProvider: RegionProvider {
    func currentRegion() async -> RegionCode { .seoul }
    func currentCoordinate() async -> CLLocationCoordinate2D? {
        .init(latitude: 37.566, longitude: 126.978)   // 시청 부근
    }
}

@MainActor
enum PreviewFactory {
    static func searchViewModel() -> SearchViewModel {
        SearchViewModel(bookSearch: PreviewBookSearchRepository())
    }
    static func detailViewModel(_ book: Book = previewBooks[0]) -> DetailViewModel {
        DetailViewModel(
            book: book,
            bookSearch: PreviewBookSearchRepository(),
            findHoldings: FindHoldingsUseCase(repository: PreviewLibraryRepository()),
            regionProvider: PreviewRegionProvider()
        )
    }
}
#endif
