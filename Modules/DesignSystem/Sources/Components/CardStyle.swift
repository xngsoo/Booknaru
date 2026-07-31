//
//  CardStyle.swift
//  DesignSystem
//
//  Created by SEUNGSOO HAN on 7/31/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import SwiftUI

/// 카드형 컨테이너 스타일. 셀·섹션을 감싸 커스텀 룩을 통일한다.
/// 시스템 List 셀 대신 쓰므로 배경·모서리·그림자를 직접 통제한다.
private struct DSCardModifier: ViewModifier {
    var padding: CGFloat = DSSpacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DSColor.card, in: RoundedRectangle(cornerRadius: DSRadius.lg))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

public extension View {
    /// 카드 배경·모서리·그림자를 입힌다.
    func dsCard(padding: CGFloat = DSSpacing.md) -> some View {
        modifier(DSCardModifier(padding: padding))
    }
}
