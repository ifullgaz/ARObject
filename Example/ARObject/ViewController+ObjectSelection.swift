/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Methods on the main view controller for handling virtual object loading and movement
*/

import UIKit
import ARKit
import ARObject
import ARFocusSquare

extension ViewController: ARObjectSelectionViewControllerDelegate {
    
    // MARK: - ARObjectSelectionViewControllerDelegate
    func arObjectSelectionViewController(_ selectionViewController: ARObjectSelectionViewController, updateAvailabilityFor object: ARObject) -> Bool {
        return sceneView.objectInteractor?.canPlace(arObject: object, at: sceneView.center) ?? false
    }
    
    // - Tag: PlaceVirtualContent
    func arObjectSelectionViewController(_: ARObjectSelectionViewController, didSelectObject object: ARObject) {
        arObjectLoader.load(object: object, onCompletion: { [unowned self] loadedObject in
            do {
                let scene = try SCNScene(url: object.referenceURL!, options: nil)
                self.sceneView.prepare([scene], completionHandler: { _ in
                    DispatchQueue.main.async {
                        self.hideObjectLoadingUI()
                        let displayState: FocusNode.DisplayState = self.sceneView.focusNode!.displayState
                        guard !self.sceneView.useFocusNode || (
                              displayState != FocusNode.DisplayState.initializing &&
                              displayState != FocusNode.DisplayState.billboard),
                              self.sceneView.objectInteractor!.place(arObject: object, at: self.sceneView.center) else {
                             self.sceneView.statusView?.present(message: "Cannot place object\nTry moving left or right.")
                             if let controller = self.objectsViewController {
                                 self.arObjectSelectionViewController(controller, didDeselectObject: object)
                             }
                             return
                         }
                        
                    }
                })
            } catch {
                fatalError("Failed to load SCNScene from object.referenceURL")
            }
            
        })
        displayObjectLoadingUI()
    }
    
    func arObjectSelectionViewController(_: ARObjectSelectionViewController, didDeselectObject object: ARObject) {
        guard let objectIndex = arObjectLoader.loadedObjects.firstIndex(of: object) else {
            fatalError("Programmer error: Failed to lookup virtual object in scene.")
        }
        arObjectLoader.removeARObject(at: objectIndex)
        if let anchor = object.anchor {
            self.session.remove(anchor: anchor)
        }
    }

    // MARK: Object Loading UI
    func displayObjectLoadingUI() {
        // Show progress indicator.
        spinner.startAnimating()
        
        addObjectButton.setImage(#imageLiteral(resourceName: "buttonring"), for: [])

        addObjectButton.isEnabled = false
        isRestartAvailable = false
    }

    func hideObjectLoadingUI() {
        // Hide progress indicator.
        spinner.stopAnimating()

        addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
        addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])

        addObjectButton.isEnabled = true
        isRestartAvailable = true
    }
}
