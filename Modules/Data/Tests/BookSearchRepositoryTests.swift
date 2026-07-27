//
//  BookSearchRepositoryTests.swift
//  Data
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Testing
import Foundation
@testable import Data
import Domain

@Suite(.serialized) struct BookSearchRepositoryTests {

    private let informHost = "data4library.kr"
    private let aladinHost = "www.aladin.co.kr"

    // 실제 정보나루 srchBooks 응답에서 한 건 추린 픽스처
    private let informJSON = """
    { "response": { "docs": [
      { "doc": { "bookname": "하얼빈 :김훈 장편소설 ", "authors": "지은이: 김훈",
                 "publisher": "문학동네", "publication_year": "2022",
                 "isbn13": "9788954699914", "vol": "",
                 "bookImageURL": "https://image.aladin.co.kr/product/29857/0/cover/895469991x_1.jpg" } }
    ] } }
    """

    // 실제 알라딘 ItemLookUp 응답에서 필요한 필드만 추린 픽스처
    private let aladinJSON = """
    { "item": [
      { "title": "하얼빈", "author": "김훈 (지은이)", "publisher": "문학동네",
        "isbn13": "9788954699914",
        "cover": "https://image.aladin.co.kr/product/29857/0/coversum/895469991x_3.jpg",
        "description": "‘우리 시대 최고의 문장가’ 김훈의 신작 장편소설 『하얼빈』.",
        "pubDate": "2022-08-03" } ]
    }
    """

    private func makeRepository() -> DefaultBookSearchRepository {
        let informClient = URLSessionHTTPClient(
            baseURL: URL(string: "https://data4library.kr/api")!,
            auth: QueryAuthProvider(name: "authKey", key: "TEST"),
            session: URLProtocolStub.makeSession()
        )
        let aladinClient = URLSessionHTTPClient(
            baseURL: URL(string: "https://www.aladin.co.kr/ttb/api")!,
            auth: QueryAuthProvider(name: "ttbkey", key: "TEST"),
            session: URLProtocolStub.makeSession()
        )
        return DefaultBookSearchRepository(informClient: informClient, aladinClient: aladinClient)
    }

    @Test func 검색은_정보나루_응답만으로_Book을_만든다() async throws {
        URLProtocolStub.reset()
        URLProtocolStub.register(host: informHost, json: informJSON)

        let books = try await makeRepository().search(keyword: "하얼빈")

        #expect(books.count == 1)
        let book = try #require(books.first)
        #expect(book.isbn13.value == "9788954699914")
        #expect(book.title == "하얼빈 :김훈 장편소설 ")
        #expect(book.coverURL?.host == "image.aladin.co.kr")   // 표지는 정보나루가 제공
        #expect(book.bookDescription == nil)                   // 소개는 detail에서만 채워짐
    }

    @Test func detail은_정보나루_기본정보와_알라딘_소개를_조인한다() async throws {
        URLProtocolStub.reset()
        URLProtocolStub.register(host: informHost, json: informJSON)   // fetchBase
        URLProtocolStub.register(host: aladinHost, json: aladinJSON)   // fetchDescription

        let book = try await makeRepository().detail(isbn13: ISBN13("9788954699914")!)

        // 기본정보는 정보나루에서
        #expect(book.title == "하얼빈 :김훈 장편소설 ")
        #expect(book.publisher == "문학동네")
        // 소개는 알라딘에서 (조인 성공의 증거)
        let description = try #require(book.bookDescription)
        #expect(description.contains("문장가"))
    }
}
