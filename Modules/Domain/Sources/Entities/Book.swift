//
//  Book.swift
//  Domain
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Foundation

public struct Book: Hashable, Sendable {
    public let isbn13: ISBN13
    public let title: String
    public let author: String // "글: 홍길동, 그림: 이순신" 형태의 원문
    public let publisher: String
    public let publicationYear: String?
    public let volume: String?  // srchBooks의 vol, 빈 값 가능
    public let coverURL: URL?   // 정보나루가 직접 제공
    public let bookDescription: String? // 2차 API로만 채워지는 유일한 필드
    
    public var id: ISBN13 { isbn13 }
    
    public init(isbn13: ISBN13,
                title: String,
                author: String,
                publisher: String,
                publicationYear: String? = nil,
                volume: String? = nil,
                coverURL: URL? = nil,
                bookDescription: String? = nil) {
        self.isbn13 = isbn13
        self.title = title
        self.author = author
        self.publisher = publisher
        self.publicationYear = publicationYear
        self.volume = volume
        self.coverURL = coverURL
        self.bookDescription = bookDescription
    }
}
