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

public struct DetailView: View {
    @State private var viewModel: DetailViewModel

    public init(viewModel: DetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                AsyncImage(url: viewModel.book.coverURL) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 6).fill(.quaternary)
                }
                .frame(width: 100, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.book.title).font(.title3).bold()
                    Text(viewModel.book.author).font(.subheadline).foregroundStyle(.secondary)
                    Text(viewModel.book.publisher).font(.footnote).foregroundStyle(.secondary)
                    if let year = viewModel.book.publicationYear {
                        Text("\(year)년").font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }

            if let description = viewModel.book.bookDescription, !description.isEmpty {
                Text(description).font(.callout)
            }
        }
    }

    // MARK: - 소장 도서관

    @ViewBuilder
    private var holdingsSection: some View {
        switch viewModel.state {
        case .loading:
            HStack { Spacer(); ProgressView("소장 도서관 찾는 중"); Spacer() }
                .padding(.vertical, 24)
        case .failed(let message):
            ContentUnavailableView(message, systemImage: "exclamationmark.triangle")
        case .loaded(let holdings) where holdings.isEmpty:
            ContentUnavailableView("소장 도서관이 없습니다",
                                   systemImage: "books.vertical",
                                   description: Text("이 지역 도서관에는 소장 정보가 없어요."))
        case .loaded(let holdings):
            VStack(alignment: .leading, spacing: 12) {
                Text("소장 도서관 \(holdings.count)곳").font(.headline)
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
                        .tint(holding.isLoanalbe ? .green : .gray)
                }
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 도서관 한 곳

private struct HoldingRow: View {
    let holding: LibraryHolding

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(holding.library.name).font(.subheadline).bold()
                Spacer()
                LoanBadge(isLoanable: holding.isLoanalbe)
            }
            Text(holding.library.address).font(.footnote).foregroundStyle(.secondary)
            if let operatingTime = holding.library.operatingTime, operatingTime != "-" {
                Label(operatingTime, systemImage: "clock")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let closed = holding.library.closed, !closed.isEmpty {
                Label(closed, systemImage: "calendar.badge.exclamationmark")
                    .font(.caption).foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct LoanBadge: View {
    let isLoanable: Bool

    var body: some View {
        Text(isLoanable ? "대출 가능" : "대출 중")
            .font(.caption).bold()
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(isLoanable ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
            .foregroundStyle(isLoanable ? .green : .secondary)
            .clipShape(Capsule())
    }
}
