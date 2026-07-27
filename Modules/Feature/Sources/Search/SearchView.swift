//
//  SearchView.swift
//  Feature
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import SwiftUI
import Domain

public struct SearchView: View {
    @State private var viewModel: SearchViewModel

    public init(viewModel: SearchViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("책나루")
                .searchable(text: $viewModel.keyword, prompt: "책 제목을 검색하세요")
                .onSubmit(of: .search) {
                    Task { await viewModel.search() }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView("책을 검색해 보세요",
                                   systemImage: "magnifyingglass",
                                   description: Text("제목으로 검색하면 소장 도서관을 찾아드립니다."))
        case .loading:
            ProgressView()
        case .empty:
            ContentUnavailableView.search
        case .loaded(let books):
            List(books) { book in
                BookRow(book: book)
            }
            .listStyle(.plain)
        case .failed(let message):
            ContentUnavailableView(message, systemImage: "exclamationmark.triangle")
        }
    }
}

private struct BookRow: View {
    let book: Book

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: book.coverURL) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                RoundedRectangle(cornerRadius: 4).fill(.quaternary)
            }
            .frame(width: 44, height: 62)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}
