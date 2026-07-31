//
//  DSDivider.swift
//  DesignSystem
//
//  Created by SEUNGSOO HAN on 7/31/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import SwiftUI

/// 얇은 구분선. 시스템 Divider를 대체해 두께·색을 통제한다.
public struct DSDivider: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .fill(Color(.separator))
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}
