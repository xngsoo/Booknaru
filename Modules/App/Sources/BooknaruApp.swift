import SwiftUI
import Feature

@main
struct BooknaruApp: App {
    var body: some Scene {
        WindowGroup {
            SearchView(viewModel: CompositionRoot.makeSearchViewModel())
        }
    }
}
