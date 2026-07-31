//
//  EmptyStateView.swift
//  DesignSystem
//
//  Created by SEUNGSOO HAN on 7/31/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import SwiftUI

/// 비어 있음·에러 상태를 알리는 커스텀 화면. 시스템 ContentUnavailableView를 대체한다.
/// 아이콘·제목·설명만 받으므로 Domain을 모른다.
public struct EmptyStateView: View {
    private let systemImage: String
    private let title: String
    private let message: String?
    private let tint: Color

    public init(_ title: String,
                systemImage: String,
                message: String? = nil,
                tint: Color = DSColor.secondaryText) {
        self.title = title
        self.systemImage = systemImage
        self.message = message
        self.tint = tint
    }

    public var body: some View {
        VStack(spacing: DSSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(tint)
            Text(title)
                .font(DSFont.sectionTitle)
                .multilineTextAlignment(.center)
            if let message {
                Text(message)
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DSSpacing.xl)
        // 아이콘은 장식 → 하나의 요소로 묶어 제목·설명만 읽히게.
        .accessibilityElement(children: .combine)
    }
}
