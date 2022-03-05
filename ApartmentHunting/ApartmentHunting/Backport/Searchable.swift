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
        if #available(iOS 15, macOS 12, *) {
            Group {
                if #available(iOS 15, macOS 12, *) {
                    self.searchable(text: text, prompt: prompt)
                }
            }
            
        } else {
            ZStack {
                self
                Color.clear
#if os(iOS)
                    .background(SearchableView(textToUpdate: text, prompt: prompt))
#endif
                    .allowsHitTesting(false)
            }
            
            
        }
    }
}


#if os(iOS)

struct SearchableView: UIViewControllerRepresentable {
    typealias UIViewControllerType = SearchableController
    @Binding var textToUpdate: String
    let prompt: String
    
    func makeUIViewController(context: Context) -> SearchableController {
        let controller = SearchableController()
        controller.currentText = textToUpdate
        controller.prompt = prompt
        controller.updater = { textToUpdate = $0 }
        return controller
    }
    
    func updateUIViewController(_ controller: SearchableController, context: Context) {
        controller.currentText = textToUpdate
        controller.prompt = prompt
        controller.updater = { textToUpdate = $0 }
        controller.updateController()
    }
}

class SearchableController: UIViewController, UISearchBarDelegate {
    var currentText = ""
    var updater: (String) -> () = {_ in }
    var prompt = ""
    
    lazy var controller: UISearchController = {
       let controller = UISearchController()
        controller.searchBar.prompt = prompt
        controller.searchBar.text = currentText
        controller.searchBar.delegate = self
        controller.obscuresBackgroundDuringPresentation = false
        return controller
    }()
    
    func updateController() {
        controller.searchBar.text = currentText
        controller.searchBar.prompt = prompt
    }
    
    override func viewDidLoad() {
        self.view.isUserInteractionEnabled = false
    }
    
    override func didMove(toParent parent: UIViewController?) {
        guard let parent = parent else {
            return
        }
        
        parent.navigationItem.searchController = controller
        parent.navigationItem.hidesSearchBarWhenScrolling = true
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        parent.navigationItem.standardAppearance = appearance
        parent.navigationItem.compactAppearance = appearance
    }
    
    override func willMove(toParent parent: UIViewController?) {
        guard let selfParent = self.parent, selfParent != parent else {
            return
        }
        selfParent.navigationItem.searchController = nil
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.updater(searchText)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.text = ""
        self.updater("")
    }
}
#endif
