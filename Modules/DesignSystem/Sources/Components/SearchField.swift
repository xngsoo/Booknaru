//
//  SearchField.swift
//  DesignSystem
//
//  Created by SEUNGSOO HAN on 7/31/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import SwiftUI

/// 커스텀 검색 입력줄. 시스템 .searchable를 대체한다.
/// 텍스트 바인딩과 제출 콜백만 받으므로 Domain을 모른다.
public struct SearchField: View {
    @Binding private var text: String
    private let prompt: String
    private let onSubmit: () -> Void

    public init(text: Binding<String>,
                prompt: String,
                onSubmit: @escaping () -> Void) {
        _text = text
        self.prompt = prompt
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DSColor.secondaryText)

            TextField(prompt, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit(onSubmit)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DSColor.secondaryText)
                }
                .accessibilityLabel("검색어 지우기")
            }
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
        .background(DSColor.card, in: Capsule())
    }
}
