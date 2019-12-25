/*
See LICENSE folder for this sample’s licensing information.

Abstract:
UI Actions for the main view controller.
*/

import UIKit

extension ViewController: UIPopoverPresentationControllerDelegate {
    
    // MARK: - UIPopoverPresentationControllerDelegate

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // All menus should be popovers (even on iPhone).
        if let popoverController = segue.destination.popoverPresentationController, let button = sender as? UIButton {
            popoverController.delegate = self
            popoverController.sourceView = button
            popoverController.sourceRect = button.bounds
        }
        
        guard let identifier = segue.identifier,
              let segueIdentifer = SegueIdentifier(rawValue: identifier),
              segueIdentifer == .showObjects else { return }
        
        let objectsViewController = segue.destination as! ARObjectSelectionViewController
        objectsViewController.arObjects = ARObjectLoader.availableObjects
        objectsViewController.delegate = self
        self.objectsViewController = objectsViewController
        
        // Set all rows of currently placed objects to selected.
        for object in arObjectLoader.loadedObjects {
            guard let index = ARObjectLoader.availableObjects.firstIndex(of: object) else { continue }
            objectsViewController.selectedARObjectRows.insert(index)
        }
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        objectsViewController = nil
    }
}
