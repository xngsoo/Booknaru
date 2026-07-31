//
//  BookRow.swift
//  Feature
//
//  Created by SEUNGSOO HAN on 7/31/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import SwiftUI
import Domain
import DesignSystem

/// 검색 결과 한 권. Domain의 Book을 받으므로 DesignSystem이 아닌 Feature에 둔다.
/// 카드형 커스텀 셀(시스템 List 셀 대체).
struct BookRow: View {
    let book: Book

    var body: some View {
        HStack(spacing: DSSpacing.md) {
            BookCover(url: book.coverURL, width: 48, height: 68)

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(book.title)
                    .font(DSFont.bookTitle)
                    .lineLimit(2)
                Text(book.author)
                    .font(DSFont.author)
                    .foregroundStyle(DSColor.secondaryText)
                    .lineLimit(1)
                Text(book.publisher)
                    .font(DSFont.meta)
                    .foregroundStyle(DSColor.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(DSFont.caption)
                .foregroundStyle(DSColor.secondaryText)
        }
        .dsCard()
        .accessibilityElement(children: .combine)
    }
}
