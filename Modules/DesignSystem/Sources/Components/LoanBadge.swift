//
//  LoanBadge.swift
//  DesignSystem
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import SwiftUI

/// 대출 가능/중 배지. Bool만 받으므로 Domain에 의존하지 않는다.
public struct LoanBadge: View {
    private let isLoanable: Bool

    public init(isLoanable: Bool) {
        self.isLoanable = isLoanable
    }

    public var body: some View {
        Text(isLoanable ? "대출 가능" : "대출 중")
            .font(DSFont.badge)
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xs)
            .background((isLoanable ? DSColor.loanable : DSColor.unavailable).opacity(0.15))
            .foregroundStyle(isLoanable ? DSColor.loanable : DSColor.secondaryText)
            .clipShape(Capsule())
    }
}
