//
//  LoadingIndicator.swift
//  DesignSystem
//
//  Created by SEUNGSOO HAN on 7/31/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import SwiftUI

/// 커스텀 로딩 스피너. 시스템 ProgressView를 대체한다.
/// 브랜드 액센트로 회전하는 호(arc)를 그린다. 선택적으로 안내 문구를 함께 보여준다.
public struct LoadingIndicator: View {
    private let title: String?
    @State private var spinning = false

    public init(_ title: String? = nil) {
        self.title = title
    }

    public var body: some View {
        VStack(spacing: DSSpacing.md) {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(DSColor.accent,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 32, height: 32)
                .rotationEffect(.degrees(spinning ? 360 : 0))
                .animation(.linear(duration: 0.9).repeatForever(autoreverses: false),
                           value: spinning)
                .onAppear { spinning = true }
            if let title {
                Text(title)
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title ?? "불러오는 중")
        .accessibilityAddTraits(.updatesFrequently)
    }
}
