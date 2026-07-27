//
//  BookCover.swift
//  DesignSystem
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import SwiftUI

/// 표지 이미지. 로딩 전/실패 시 placeholder를 보여준다.
/// Domain 타입을 모르고 URL만 받으므로 DesignSystem에 둘 수 있다.
public struct BookCover: View {
    private let url: URL?
    private let width: CGFloat
    private let height: CGFloat

    public init(url: URL?, width: CGFloat, height: CGFloat) {
        self.url = url
        self.width = width
        self.height = height
    }

    public var body: some View {
        AsyncImage(url: url) { image in
            image.resizable().scaledToFit()
        } placeholder: {
            RoundedRectangle(cornerRadius: DSRadius.md).fill(.quaternary)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.md))
    }
}
