//
//  HoldingRow.swift
//  Feature
//
//  Created by SEUNGSOO HAN on 7/31/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import SwiftUI
import Domain
import DesignSystem

/// 소장 도서관 한 곳. Domain의 LibraryHolding을 받으므로 Feature에 둔다.
/// 카드형 커스텀 셀.
struct HoldingRow: View {
    let holding: LibraryHolding

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            HStack {
                Text(holding.library.name)
                    .font(DSFont.author).bold()
                Spacer()
                LoanBadge(isLoanable: holding.isLoanable)
            }
            Text(holding.library.address)
                .font(DSFont.meta)
                .foregroundStyle(DSColor.secondaryText)
            if let operatingTime = holding.library.operatingTime, operatingTime != "-" {
                InfoLabel(operatingTime, systemImage: "clock")
            }
            if let closed = holding.library.closed, !closed.isEmpty {
                InfoLabel(closed, systemImage: "calendar.badge.exclamationmark",
                          tint: DSColor.warning)
            }
        }
        .dsCard()
        .accessibilityElement(children: .combine)
    }
}
