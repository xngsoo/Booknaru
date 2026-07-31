//
//  InfoLabel.swift
//  DesignSystem
//
//  Created by SEUNGSOO HAN on 7/31/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import SwiftUI

/// 아이콘 + 텍스트 한 줄. 시스템 Label을 대체해 폰트·색을 토큰으로 통일한다.
public struct InfoLabel: View {
    private let text: String
    private let systemImage: String
    private let tint: Color

    public init(_ text: String,
                systemImage: String,
                tint: Color = DSColor.secondaryText) {
        self.text = text
        self.systemImage = systemImage
        self.tint = tint
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DSSpacing.xs) {
            Image(systemName: systemImage)
                .font(DSFont.caption)
            Text(text)
                .font(DSFont.caption)
        }
        .foregroundStyle(tint)
        .accessibilityElement(children: .combine)
    }
}
