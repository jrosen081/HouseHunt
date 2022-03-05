//
//  LinkView.swift
//  JexiApp
//
//  Created by Jack Rosen on 1/10/22.
//

import SwiftUI
import LinkPresentation
import UniformTypeIdentifiers

#if !os(macOS)
private struct LinkViewWrapper: UIViewRepresentable {
    class LinkView: LPLinkView {
        override var intrinsicContentSize: CGSize { CGSize(width: 0, height: super.intrinsicContentSize.height) }
    }
    typealias UIViewType = LinkView
    let metadata: LPLinkMetadata
    
    func makeUIView(context: Context) -> LinkView {
        let link = LinkView(metadata: metadata)
        return link
    }
    
    func updateUIView(_ uiView: LinkView, context: Context) {
        uiView.metadata = metadata
    }
}
#else
private struct LinkViewWrapper: NSViewRepresentable {
    class LinkView: LPLinkView {
        override var intrinsicContentSize: CGSize { CGSize(width: 0, height: super.intrinsicContentSize.height) }
    }
    typealias NSViewType = LinkView
    let metadata: LPLinkMetadata
    
    func makeNSView(context: Context) -> LinkView {
        let link = LinkView(metadata: metadata)
        return link
    }
    
    func updateNSView(_ uiView: LinkView, context: Context) {
        DispatchQueue.main.async {
            uiView.metadata = metadata
        }
    }
}

#endif

struct LinkView: View {
    let linkUrl: URL?
    @State private var metadata: LoadingState<LPLinkMetadata> = .notStarted
    @State private var task: Task<Void, Never>?
    @EnvironmentObject var linkInteractor: LinkInteractor
    
    private func loadData(linkUrl: URL?) async {
        guard let linkUrl = linkUrl else {
            return
        }
        self.metadata = .loading
        do {
            let metadata: LPLinkMetadata = try await linkInteractor.fetchMetadata(url: linkUrl)
            await MainActor.run {
                self.metadata = .success(metadata)
            }
        } catch {
            print(error)
            self.metadata = .error(error.localizedDescription)
        }
        
    }
    
    var body: some View {
        Group {
            switch metadata {
            case .loading, .notStarted:
                ProgressView("Loading Link")
                    .padding()
            case .success(let metadata):
                LinkViewWrapper(metadata: metadata)
                    .padding(.vertical)
            case .error(let error):
                HStack {
                    VStack(alignment: .leading) {
                        Text("Something Went Wrong:")
                        Text(error)
                    }
                    Spacer()
                    Image(systemName: "xmark")
                }.foregroundColor(.red)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("An Error Occurred Loading the Link")
            }
        }
        .back_task {
            await self.loadData(linkUrl: self.linkUrl)
        }
    }
}

struct LinkView_Previews: PreviewProvider {
    static var previews: some View {
        LinkView(linkUrl: URL(string: "https://github.com"))
    }
}
