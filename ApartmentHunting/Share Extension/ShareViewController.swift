//
//  ShareViewController.swift
//  Home Hunt Share
//
//  Created by Jack Rosen on 2/18/22.
//

import UIKit
import Social
import Firebase
import CloudKit

class ShareViewController: SLComposeServiceViewController {
    private enum Errors: Error, LocalizedError {
        case notSignedIn
        
        var errorDescription: String? {
            switch self {
            case .notSignedIn:
                return "You are not signed in to an acccount"
            }
        }
    }
    let authInteractor: AuthInteractor = {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        return AuthInteractor()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView.text = ""
        self.placeholder = "Add Notes Here"
        self.navigationController?.navigationBar.topItem?.rightBarButtonItem?.title = "Add"
        
    }
    
    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return !self.textView.text.isEmpty
    }

    override func didSelectPost() {
        if let user = authInteractor.user,
           let extensionItem = self.extensionContext?.inputItems.first as? NSExtensionItem,
           let item = extensionItem.attachments?.first,
           item.hasItemConformingToTypeIdentifier("public.url") {
            switch user.apartmentSearchState {
            case .success(let id):
                item.loadItem(forTypeIdentifier: "public.url", options: nil) { item, error in
                    if let error = error {
                        self.extensionContext?.cancelRequest(withError: error)
                    } else if let item = item as? URL {
                        print(item)
                        Task {
                            do {
                                try await ApartmentAPIInteractor.addApartment(url: item.absoluteString, apartmentSearchId: id) { title in
                                    ApartmentModel(location: title, url: item.absoluteString, state: .interested, dateUploaded: Date(), author: user.id, previousStates: [], apartmentSearchId: id, notes: self.textView.text)
                                }
                                print("Success")
                                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                            } catch {
                                print("error: \(error)")
                                self.extensionContext?.cancelRequest(withError: error)
                            }
                        }
                    }
                }
                
            default:
                self.extensionContext?.cancelRequest(withError: Errors.notSignedIn)
            }
        } else {
            self.extensionContext?.cancelRequest(withError: Errors.notSignedIn)
        }
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

}
