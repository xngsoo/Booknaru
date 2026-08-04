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
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(_ title: String,
                systemImage: String,
                message: String? = nil,
                tint: Color = DSColor.secondaryText,
                actionTitle: String? = nil,
                action: (() -> Void)? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.message = message
        self.tint = tint
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: DSSpacing.md) {
            // 아이콘은 장식 → 하나의 요소로 묶어 제목·설명만 읽히게.
            // 버튼은 이 묶음 밖에 둔다. 안에 넣으면 combine이 버튼을 삼켜 조작할 수 없다.
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
            .accessibilityElement(children: .combine)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
                    .tint(DSColor.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DSSpacing.xl)
    }
}
