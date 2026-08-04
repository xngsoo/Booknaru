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
            if let distance = formattedDistance {
                InfoLabel(distance, systemImage: "location")
            }
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

    /// 단위(m/km)·자릿수는 usage: .road에 맡긴다. 직접 반올림하면 로케일마다 틀어진다.
    private var formattedDistance: String? {
        holding.distance.map {
            Measurement(value: $0, unit: UnitLength.meters)
                .formatted(.measurement(width: .abbreviated, usage: .road))
        }
    }
}
