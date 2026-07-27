//
//  LibraryRepositoryTests.swift
//  Data
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Testing
import Foundation
@testable import Data
import Domain

// 테스트가 공유 static(URLProtocolStub.stubs)을 갈아끼우므로 병렬 실행 시 경합이 난다.
// Swift Testing은 기본 병렬 실행이라 .serialized로 직렬화한다.
@Suite(.serialized) struct LibraryRepositoryTests {

    private let host = "data4library.kr"

    private func makeRepository() -> DefaultLibraryRepository {
        let client = URLSessionHTTPClient(
            baseURL: URL(string: "https://data4library.kr/api")!,
            auth: QueryAuthProvider(name: "authKey", key: "TEST"),
            session: URLProtocolStub.makeSession()
        )
        return DefaultLibraryRepository(client: client)
    }

    @Test func 소장도서관_응답을_Library로_매핑한다() async throws {
        // 실제 libSrchByBook 응답에서 한 건만 추린 픽스처
        let json = """
        { "response": { "libs": [
          { "lib": { "libCode": "111456", "libName": "가락몰도서관",
                     "address": "서울특별시 송파구 양재대로 932",
                     "tel": "02-3435-0950", "fax": "02-3435-0959",
                     "latitude": "37.492994", "longitude": "127.112326",
                     "homepage": "http://www.splib.or.kr/spalib/",
                     "closed": "매주 월요일 / 법정공휴일",
                     "operatingTime": "09:00 ~ 18:00" } }
        ] } }
        """
        URLProtocolStub.reset()
        URLProtocolStub.register(host: host, json: json)

        let libraries = try await makeRepository()
            .holdingLibraries(isbn13: ISBN13("9788954699914")!, region: .seoul)

        #expect(libraries.count == 1)
        let lib = try #require(libraries.first)
        #expect(lib.code == "111456")
        #expect(lib.name == "가락몰도서관")
        #expect(lib.coordinate?.latitude == 37.492994)   // 문자열 → Double 파싱 검증
        #expect(lib.closed == "매주 월요일 / 법정공휴일")   // 휴관일 매핑 검증
    }

    @Test func 대출가능여부는_Y일때만_true() async throws {
        let json = #"{ "response": { "result": { "hasBook": "Y", "loanAvailable": "Y" } } }"#
        URLProtocolStub.reset()
        URLProtocolStub.register(host: host, json: json)

        let loanable = try await makeRepository()
            .loanStatus(isbn13: ISBN13("9788954699914")!, libCode: "111456")

        #expect(loanable == true)
    }

    @Test func 서버_500이면_unacceptableStatus를_던진다() async throws {
        URLProtocolStub.reset()
        URLProtocolStub.register(host: host, json: "{}", statusCode: 500)

        await #expect(throws: NetworkError.self) {
            try await makeRepository()
                .loanStatus(isbn13: ISBN13("9788954699914")!, libCode: "111456")
        }
    }
}
