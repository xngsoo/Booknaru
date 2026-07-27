//
//  SearchView.swift
//  Feature
//
//  Created by SEUNGSOO HAN on 7/27/26.
//  Copyright © 2026 xngsoo. All rights reserved.
//

import SwiftUI
import Domain
import DesignSystem

public struct SearchView: View {
    @State private var viewModel: SearchViewModel
    private let makeDetailViewModel: (Book) -> DetailViewModel

    public init(viewModel: SearchViewModel,
                makeDetailViewModel: @escaping (Book) -> DetailViewModel) {
        _viewModel = State(initialValue: viewModel)
        self.makeDetailViewModel = makeDetailViewModel
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("책나루")
                .searchable(text: $viewModel.keyword, prompt: "책 제목을 검색하세요")
                .onSubmit(of: .search) {
                    Task { await viewModel.search() }
                }
                .navigationDestination(for: Book.self) { book in
                    DetailView(viewModel: makeDetailViewModel(book))
                }
        }
        .tint(DSColor.accent)
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
                NavigationLink(value: book) {
                    BookRow(book: book)
                }
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
        HStack(spacing: DSSpacing.md) {
            BookCover(url: book.coverURL, width: 44, height: 62)

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(book.title)
                    .font(DSFont.bookTitle)
                    .lineLimit(2)
                Text(book.author)
                    .font(DSFont.author)
                    .foregroundStyle(DSColor.secondaryText)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, DSSpacing.xs)
    }
}
