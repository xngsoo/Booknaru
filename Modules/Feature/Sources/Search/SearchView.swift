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
            VStack(spacing: DSSpacing.md) {
                SearchField(text: $viewModel.keyword,
                            prompt: "책 제목을 검색하세요") {
                    Task { await viewModel.search() }
                }
                .padding(.horizontal, DSSpacing.lg)

                content
            }
            .navigationTitle("책나루")
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
            Spacer()
            EmptyStateView("책을 검색해 보세요",
                           systemImage: "magnifyingglass",
                           message: "제목으로 검색하면 소장 도서관을 찾아드립니다.")
            Spacer()
        case .loading:
            Spacer()
            LoadingIndicator("검색 중")
            Spacer()
        case .empty:
            Spacer()
            EmptyStateView("검색 결과가 없습니다",
                           systemImage: "text.magnifyingglass",
                           message: "다른 제목으로 다시 검색해 보세요.")
            Spacer()
        case .loaded(let books):
            resultList(books)
        case .failed(let message):
            Spacer()
            // 검색어는 그대로 남아 있으므로 버튼 하나로 같은 검색을 다시 태운다.
            EmptyStateView(message,
                           systemImage: "exclamationmark.triangle",
                           tint: DSColor.warning,
                           actionTitle: "다시 시도") {
                Task { await viewModel.search() }
            }
            Spacer()
        }
    }

    // 시스템 List 대신 ScrollView + LazyVStack로 셀을 직접 그린다.
    private func resultList(_ books: [Book]) -> some View {
        ScrollView {
            LazyVStack(spacing: DSSpacing.md) {
                ForEach(books) { book in
                    NavigationLink(value: book) {
                        BookRow(book: book)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DSSpacing.lg)
            .padding(.bottom, DSSpacing.lg)
        }
        .scrollDismissesKeyboard(.immediately)
    }
}

#if DEBUG
#Preview("검색 결과") {
    // SearchViewModel은 참조 타입이라, 밖에서 search()를 부르면 SearchView가 관찰하는
    // 같은 인스턴스가 갱신돼 결과 상태가 렌더된다.
    let viewModel = PreviewFactory.searchViewModel()
    viewModel.keyword = "책"
    return SearchView(viewModel: viewModel,
                      makeDetailViewModel: { PreviewFactory.detailViewModel($0) })
        .task { await viewModel.search() }
}

#Preview("초기 상태") {
    SearchView(viewModel: PreviewFactory.searchViewModel(),
               makeDetailViewModel: { PreviewFactory.detailViewModel($0) })
}
#endif
