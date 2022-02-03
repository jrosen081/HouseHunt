//
//  Searchable.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/27/22.
//

import SwiftUI

extension View {
    @ViewBuilder
    func back_searchable(text: Binding<String>, prompt: String) -> some View {
        if #available(iOS 15, *) {
            self.searchable(text: text, prompt: prompt)
        } else {
            self.background(SearchController(text: text, prompt: prompt))
        }
    }
}

private struct SearchController: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController
    @Binding var text: String
    let prompt: String
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController(nibName: nil, bundle: nil)
        controller.view.frame = .zero
        controller.view.backgroundColor = .clear
        let searchController = UISearchController(nibName: nil, bundle: nil)
        controller.navigationItem.searchController = searchController
        searchController.searchBar.delegate = context.coordinator
        searchController.searchBar.text = text
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        uiViewController.navigationItem.searchController?.searchBar.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    class Coordinator: NSObject, UISearchBarDelegate {
        let text: Binding<String>
        
        init(text: Binding<String>) {
            self.text = text
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            self.text.wrappedValue = searchText
        }
    }
}
