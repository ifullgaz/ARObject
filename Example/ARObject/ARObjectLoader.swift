/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A type which loads and tracks virtual objects.
*/

import ARKit
import ARObject

/**
 Loads multiple `ARObject`s on a background queue to be able to display the
 objects quickly once they are needed.
*/
class ARObjectLoader {
    private(set) var loadedObjects = [ARObject]()
    
    private(set) var isLoading = false
    
    // MARK: Static Properties and Methods
    /// Loads all the model objects within `Models.scnassets`.
    static let availableObjects: [ARObject] = {
        let modelsURL = Bundle.main.url(forResource: "Models.scnassets", withExtension: nil)!
        let fileEnumerator = FileManager().enumerator(at: modelsURL, includingPropertiesForKeys: [])!
        return fileEnumerator.compactMap { element in
            let url = element as! URL
            guard url.pathExtension == "scn" && !url.path.contains("lighting") else { return nil }
            let arObject = ARObject(url: url)
            if arObject.name == "sticky note" {
                arObject.allowedAlignment = .any
            } else if arObject.name == "painting" {
                arObject.allowedAlignment = .vertical
            } else {
                arObject.allowedAlignment = .horizontal
            }
            return arObject
        }
    }()

    // MARK: - Loading object
    /**
     Loads a `ARObject` on a background queue. `loadedHandler` is invoked
     on a background queue once `object` has been loaded.
    */
    func load(object: ARObject, onCompletion handler: @escaping (ARObject) -> Void) {
        isLoading = true
        loadedObjects.append(object)
        
        // Load the content into the reference node.
        DispatchQueue.global(qos: .userInitiated).async {
            object.load()
            self.isLoading = false
            handler(object)
        }
    }
    
    // MARK: - Removing Objects
    
    func removeAllARObjects() {
        // Reverse the indices so we don't trample over indices as objects are removed.
        for index in loadedObjects.indices.reversed() {
            removeARObject(at: index)
        }
    }

    /// - Tag: RemoveARObject
    func removeARObject(at index: Int) {
        guard loadedObjects.indices.contains(index) else { return }
        
        // Stop the object's tracked ray cast.
        loadedObjects[index].stopTrackedRaycast()
        
        // Remove the visual node from the scene graph.
        loadedObjects[index].removeFromParentNode()
        // Recoup resources allocated by the object.
        loadedObjects[index].unload()
        loadedObjects.remove(at: index)
    }
}
