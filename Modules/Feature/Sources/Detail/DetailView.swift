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
                Divider()
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
            HStack { Spacer(); ProgressView("소장 도서관 찾는 중"); Spacer() }
                .padding(.vertical, DSSpacing.xl)
        case .failed(let message):
            ContentUnavailableView(message, systemImage: "exclamationmark.triangle")
        case .loaded(let holdings) where holdings.isEmpty:
            ContentUnavailableView("소장 도서관이 없습니다",
                                   systemImage: "books.vertical",
                                   description: Text("이 지역 도서관에는 소장 정보가 없어요."))
        case .loaded(let holdings):
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                Text("소장 도서관 \(holdings.count)곳").font(DSFont.sectionTitle)
                HoldingsMap(holdings: holdings)
                ForEach(holdings) { holding in
                    HoldingRow(holding: holding)
                    if holding.id != holdings.last?.id { Divider() }
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
                        .tint(holding.isLoanalbe ? DSColor.loanable : DSColor.unavailable)
                }
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.lg))
    }
}

// MARK: - 도서관 한 곳

private struct HoldingRow: View {
    let holding: LibraryHolding

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            HStack {
                Text(holding.library.name).font(DSFont.author).bold()
                Spacer()
                LoanBadge(isLoanable: holding.isLoanalbe)
            }
            Text(holding.library.address).font(DSFont.meta).foregroundStyle(DSColor.secondaryText)
            if let operatingTime = holding.library.operatingTime, operatingTime != "-" {
                Label(operatingTime, systemImage: "clock")
                    .font(DSFont.caption).foregroundStyle(DSColor.secondaryText)
            }
            if let closed = holding.library.closed, !closed.isEmpty {
                Label(closed, systemImage: "calendar.badge.exclamationmark")
                    .font(DSFont.caption).foregroundStyle(DSColor.warning)
            }
        }
        .padding(.vertical, DSSpacing.xs)
    }
}
