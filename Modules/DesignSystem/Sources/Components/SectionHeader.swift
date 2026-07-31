//
//  SectionHeader.swift
//  DesignSystem
//
//  Created by SEUNGSOO HAN on 7/31/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import SwiftUI

/// 섹션 제목. 앞에 브랜드 액센트 바를 두어 커스텀 룩을 준다.
public struct SectionHeader: View {
    private let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        HStack(spacing: DSSpacing.sm) {
            RoundedRectangle(cornerRadius: DSRadius.sm)
                .fill(DSColor.accent)
                .frame(width: 4, height: 18)
            Text(title)
                .font(DSFont.sectionTitle)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
