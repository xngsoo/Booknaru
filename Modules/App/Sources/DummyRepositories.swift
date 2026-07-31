//
//  DummyRepositories.swift
//  App
//
//  Created by SEUNGSOO HAN on 7/31/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

#if DEBUG
import Foundation
import Domain

/// 개발계 전용 더미. 실제 API를 호출하지 않고 고정 데이터만 돌려준다.
/// 무료 API의 호출 제한을 개발 중 빌드·실행 반복이 소진하지 않도록,
/// Debug(개발계) 빌드에서만 CompositionRoot가 이 구현들을 주입한다.
/// 운영계(Release) 빌드는 여전히 실제 Repository를 쓴다.

// App 모듈은 기본 격리가 MainActor라, nonisolated로 두어야 Sendable Repository에서 읽을 수 있다.
private nonisolated let dummyBooks: [Book] = [
    Book(isbn13: ISBN13("9788934972464")!,
         title: "더미: 클린 아키텍처",
         author: "글: 로버트 마틴",
         publisher: "인사이트",
         publicationYear: "2019",
         coverURL: nil,
         bookDescription: "개발계 더미 데이터입니다. 실제 API는 호출되지 않았습니다."),
    Book(isbn13: ISBN13("9791162540640")!,
         title: "더미: 오브젝트",
         author: "글: 조영호",
         publisher: "위키북스",
         publicationYear: "2019",
         coverURL: nil,
         bookDescription: "개발계 더미 데이터입니다. 실제 API는 호출되지 않았습니다."),
    Book(isbn13: ISBN13("9788954682152")!,
         title: "더미: 사피엔스",
         author: "글: 유발 하라리",
         publisher: "김영사",
         publicationYear: "2015",
         coverURL: nil,
         bookDescription: "개발계 더미 데이터입니다. 실제 API는 호출되지 않았습니다.")
]

struct DummyBookSearchRepository: BookSearchRepository {
    func search(keyword: String) async throws -> [Book] {
        guard !keyword.isEmpty else { return dummyBooks }
        let hit = dummyBooks.filter {
            $0.title.contains(keyword) || $0.author.contains(keyword)
        }
        return hit.isEmpty ? dummyBooks : hit
    }

    func detail(isbn13: ISBN13) async throws -> Book {
        dummyBooks.first { $0.isbn13 == isbn13 } ?? dummyBooks[0]
    }
}

struct DummyLibraryRepository: LibraryRepository {
    private let libraries: [Library] = [
        Library(code: "111001", name: "더미: 남산도서관",
                address: "서울 용산구 소월로 109",
                coordinate: .init(latitude: 37.551, longitude: 126.981)),
        Library(code: "111002", name: "더미: 정독도서관",
                address: "서울 종로구 북촌로5길 48",
                coordinate: .init(latitude: 37.581, longitude: 126.983))
    ]

    func holdingLibraries(isbn13: ISBN13, region: RegionCode) async throws -> [Library] {
        libraries
    }

    func loanStatus(isbn13: ISBN13, libCode: String) async throws -> Bool {
        libCode == "111001"   // 하나는 대출 가능, 하나는 불가로 두 상태 모두 확인
    }
}

struct DummyRegionProvider: RegionProvider {
    func currentRegion() async -> RegionCode { .seoul }
}
#endif
