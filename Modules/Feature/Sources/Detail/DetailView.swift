//
//  DetailView.swift
//  Feature
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import SwiftUI
import MapKit
import Domain
import DesignSystem

public struct DetailView: View {
    @State private var viewModel: DetailViewModel

    public init(viewModel: DetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                header
                DSDivider()
                holdingsSection
            }
            .padding()
        }
        .navigationTitle(viewModel.book.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    // MARK: - 헤더 (표지 + 서지정보 + 소개)

    private var header: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            HStack(alignment: .top, spacing: DSSpacing.lg) {
                BookCover(url: viewModel.book.coverURL, width: 100, height: 140)

                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(viewModel.book.title).font(DSFont.detailTitle)
                    Text(viewModel.book.author).font(DSFont.author).foregroundStyle(DSColor.secondaryText)
                    Text(viewModel.book.publisher).font(DSFont.meta).foregroundStyle(DSColor.secondaryText)
                    if let year = viewModel.book.publicationYear {
                        Text("\(year)년").font(DSFont.meta).foregroundStyle(DSColor.secondaryText)
                    }
                }
                Spacer(minLength: 0)
            }

            if let description = viewModel.book.bookDescription, !description.isEmpty {
                Text(description).font(DSFont.body)
            }
        }
    }

    // MARK: - 소장 도서관

    @ViewBuilder
    private var holdingsSection: some View {
        switch viewModel.state {
        case .loading:
            LoadingIndicator("소장 도서관 찾는 중")
                .padding(.vertical, DSSpacing.xl)
        case .failed(let message):
            EmptyStateView(message, systemImage: "exclamationmark.triangle",
                           tint: DSColor.warning)
        case .loaded(let holdings) where holdings.isEmpty:
            EmptyStateView("소장 도서관이 없습니다",
                           systemImage: "books.vertical",
                           message: "이 지역 도서관에는 소장 정보가 없어요.")
        case .loaded(let holdings):
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                SectionHeader("소장 도서관 \(holdings.count)곳")
                HoldingsMap(holdings: holdings)
                ForEach(holdings) { holding in
                    HoldingRow(holding: holding)
                }
            }
        }
    }
}

// MARK: - 지도 (좌표 있는 도서관만 핀)

private struct HoldingsMap: View {
    let holdings: [LibraryHolding]

    private var pinned: [LibraryHolding] {
        holdings.filter { $0.library.coordinate != nil }
    }

    var body: some View {
        Map {
            ForEach(pinned) { holding in
                if let coordinate = holding.library.coordinate {
                    Marker(holding.library.name, coordinate: coordinate)
                        .tint(holding.isLoanable ? DSColor.loanable : DSColor.unavailable)
                }
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.lg))
    }
}

#if DEBUG
#Preview {
    // DetailView는 .task에서 스스로 load()하므로 스텁 데이터로 소장 목록이 채워진다.
    NavigationStack {
        DetailView(viewModel: PreviewFactory.detailViewModel())
    }
}
#endif
