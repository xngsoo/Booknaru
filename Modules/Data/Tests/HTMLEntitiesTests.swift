//
//  HTMLEntitiesTests.swift
//  DataTests
//
//  Created by SEUNGSOO HAN on 7/30/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import Testing
@testable import Data

@Suite("HTML 엔티티 디코딩")
struct HTMLEntitiesTests {

    @Test("이름 엔티티를 되돌린다")
    func namedEntities() {
        #expect("월 &middot; 화".htmlUnescaped == "월 · 화")
        #expect("&lt;서문&gt;".htmlUnescaped == "<서문>")
        #expect("A &amp; B".htmlUnescaped == "A & B")
    }

    @Test("숫자·16진 참조를 되돌린다")
    func numericEntities() {
        #expect("It&#39;s".htmlUnescaped == "It's")
        #expect("&#x2019;".htmlUnescaped == "\u{2019}")
    }

    @Test("엔티티가 없으면 원문 그대로")
    func passthrough() {
        #expect("한강 연작소설".htmlUnescaped == "한강 연작소설")
    }

    @Test("모르는/깨진 엔티티는 원문 유지")
    func unknownLeftIntact() {
        #expect("Tom & Jerry".htmlUnescaped == "Tom & Jerry")      // 세미콜론 없음
        #expect("&unknown;".htmlUnescaped == "&unknown;")           // 미등록 이름
    }

    @Test("여러 엔티티가 섞여도 모두 처리")
    func mixed() {
        #expect("&lt;p&gt;A&amp;B&#39;s&lt;/p&gt;".htmlUnescaped == "<p>A&B's</p>")
    }
}
