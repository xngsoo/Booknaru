//
//  DummyRepositories.swift
//  App
//
//  Created by SEUNGSOO HAN on 7/31/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

#if DEBUG
import Foundation
import CoreLocation
import Domain

/// 개발계 전용 더미. 실제 API를 호출하지 않고 고정 데이터만 돌려준다.
/// 무료 API의 호출 제한을 개발 중 빌드·실행 반복이 소진하지 않도록,
/// Debug(개발계) 빌드에서만 CompositionRoot가 이 구현들을 주입한다.
/// 운영계(Release) 빌드는 여전히 실제 Repository를 쓴다.

// App 모듈은 기본 격리가 MainActor라, nonisolated로 두어야 Sendable Repository에서 읽을 수 있다.
// 무한 스크롤·리스트 UI 작업을 위해 넉넉히 생성한다. ISBN은 "978"+10자리로 만들어 전부 유효.
private nonisolated let dummyTitles = [
    "클린 아키텍처", "오브젝트", "사피엔스", "코스모스", "총 균 쇠", "미움받을 용기",
    "데미안", "1984", "이기적 유전자", "정의란 무엇인가", "노르웨이의 숲", "어린 왕자"
]
private nonisolated let dummyAuthors = [
    "로버트 마틴", "조영호", "유발 하라리", "칼 세이건", "재레드 다이아몬드", "기시미 이치로",
    "헤르만 헤세", "조지 오웰", "리처드 도킨스", "마이클 샌델", "무라카미 하루키", "생텍쥐페리"
]
private nonisolated let dummyPublishers = ["인사이트", "위키북스", "김영사", "사이언스북스", "문학동네", "민음사"]

private nonisolated let dummyBooks: [Book] = (1...40).map { i in
    let idx = i - 1
    return Book(
        isbn13: ISBN13(String(format: "978%010d", i))!,
        title: "더미\(i): \(dummyTitles[idx % dummyTitles.count])",
        author: "글: \(dummyAuthors[idx % dummyAuthors.count])",
        publisher: dummyPublishers[idx % dummyPublishers.count],
        publicationYear: String(2000 + idx % 25),
        coverURL: nil,
        bookDescription: "개발계 더미 데이터입니다(#\(i)). 실제 API는 호출되지 않았습니다."
    )
}

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
    private let libraries: [Library] = (1...12).map { i in
        let code = String(format: "1110%02d", i)
        let name = "더미\(i): 시립 제\(i)도서관"
        let address = "서울 어딘가 \(i)길 \(i * 10)"
        let lat: Double = 37.55 + Double(i) * 0.005
        let lng: Double = 126.98 + Double(i) * 0.005
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        return Library(code: code, name: name, address: address, coordinate: coordinate)
    }

    func holdingLibraries(isbn13: ISBN13, region: RegionCode) async throws -> [Library] {
        libraries
    }

    func loanStatus(isbn13: ISBN13, libCode: String) async throws -> Bool {
        // 짝/홀로 대출 가능·불가를 섞어 두 상태 UI를 모두 볼 수 있게.
        (Int(libCode.suffix(2)) ?? 0) % 2 == 1
    }
}

struct DummyRegionProvider: RegionProvider {
    func currentRegion() async -> RegionCode { .seoul }
}
#endif
