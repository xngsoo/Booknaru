import SwiftUI
import Feature

@main
struct BooknaruApp: App {
    var body: some Scene {
        WindowGroup {
            SearchView(
                viewModel: CompositionRoot.makeSearchViewModel(),
                makeDetailViewModel: { CompositionRoot.makeDetailViewModel(book: $0) }
            )
        }
    }
}
