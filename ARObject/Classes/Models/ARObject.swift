//
//  ARObject.swift
//  ARObject
//
//  Created by Emmanuel Merali on 17/12/2019.
//  Copyright © 2019 Test. All rights reserved.
//

import ARKit

// MARK: - ARObject Reference node support
public extension ARObject {
    /// The URL to a scene file from which to load content for the reference node
    private(set) var referenceURL: URL? {
        get {
            return referenceNode?.referenceURL
        }
        set {
            guard referenceURL != newValue else { return }
            self.unload()
            referenceNode?.removeFromParentNode()
            referenceNode = nil
            if let newValue = newValue,
               let referenceNode = SCNReferenceNode(url: newValue) {
                self.referenceNode = referenceNode
                addChildNode(referenceNode)
                name = newValue.lastPathComponent.replacingOccurrences(of: ".scn", with: "")
            }
        }
    }

    /// An option for whether to load the node’s content automatically
    var loadingPolicy: SCNReferenceLoadingPolicy {
        get {
            return referenceNode?.loadingPolicy ?? .immediate
        }
        set {
            referenceNode?.loadingPolicy = newValue
        }
    }

    /// A Boolean value that indicates whether the reference node has already loaded its content.
    var isLoaded: Bool {
        get {
            return referenceNode?.isLoaded ?? false
        }
    }

    func load() {
        referenceNode?.load()
    }
    
    func unload() {
        referenceNode?.unload()
    }
    
    convenience init?(url referenceURL: URL) {
        self.init()
        self.referenceURL = referenceURL
        if referenceNode == nil {
            return nil
        }
    }
}

// MARK: - ARObject
open class ARObject: SCNNode {
    
    /// Returns an `ARObject` if one exists as an ancestor to the provided node.
    /// - parameters:
    ///     - node: an SCNNode
    ///
    /// - returns
    ///     ARObject: an ARObject if the node is or has an ARObject in its ancestry or
    ///     nil if the node is not part of an ARObject hierarchy
    public static func arObjectFrom(node: SCNNode) -> ARObject? {
        if let arObjectRoot = node as? ARObject {
            return arObjectRoot
        }
        
        guard let parent = node.parent else { return nil }
        
        // Recurse up to check if the parent is an `ARObject`.
        return arObjectFrom(node: parent)
    }

    /// A reference node used as geometry when referenceURL is set
    private var referenceNode: SCNReferenceNode?
    
    /// The alignments that are allowed for a virtual object.
    public var allowedAlignment: ARRaycastQuery.TargetAlignment = .any
    
    /// Rotates the first child node of a virtual object.
    /// - Note: For correct rotation on horizontal and vertical surfaces, rotate around
    /// local y rather than world y. Has no effect when the gepmetry is empty.
    public var objectRotation: Float {
        get {
            return childNodes.first?.eulerAngles.y ?? 0.0
        }
        set (newValue) {
            childNodes.first?.eulerAngles.y = newValue
        }
    }
    
    /// The object's corresponding ARAnchor.
    public var anchor: ARAnchor?

    /// The associated tracked raycast used to place this object.
    public var raycast: ARTrackedRaycast?
    
    /// Stops tracking the object's position and orientation.
    /// - Tag: StopTrackedRaycasts
    public func stopTrackedRaycast() {
        raycast?.stopTracking()
        raycast = nil
    }

    public func distanceFrom(camera: ARCamera) -> Float {
        return simd_length(simdWorldPosition - camera.transform.translation)
    }

    open func setupGeometry() {}

    deinit {
        self.stopTrackedRaycast()
    }
    
    // MARK: - Initialization
    required public override init() {
        super.init()
        self.setupGeometry()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        if (loadingPolicy == .immediate) {
            load()
        }
    }
}
