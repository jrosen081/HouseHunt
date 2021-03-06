//
//  ShareSheet.swift
//  Apartments
//
//  Created by Jack Rosen on 1/25/22.
//

import SwiftUI

#if !os(macOS)
private struct ShareSheet: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIActivityViewController
    
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIViewControllerType(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothin
    }
}

private struct ShareSheetCreator: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController
    
    
    let items: [Any]
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented {
            let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
            controller.popoverPresentationController?.sourceView = uiViewController.view
            uiViewController.present(controller, animated: true) {
                self.isPresented = false
            }
        }
    }
}
#else

private struct ShareSheet: NSViewRepresentable {
    typealias NSViewType = NSView
    @Binding var isPresented: Bool
    let items: [Any]
    
    func makeNSView(context: Context) -> NSView {
        return NSView(frame: .zero)
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard isPresented else { return }
        let picker = NSSharingServicePicker(items: items)
        DispatchQueue.main.async {
            picker.show(relativeTo: .zero, of: nsView, preferredEdge: .minY)
            self.isPresented = false
        }
    }
}
#endif

extension View {
    @ViewBuilder
    func shareSheet(items: [Any], isPresented: Binding<Bool>) -> some View {
        #if !os(macOS)
        self.background(ShareSheetCreator(items: items, isPresented: isPresented))
        #else
        self.background(ShareSheet(isPresented: isPresented, items: items))
        #endif
    }
}
