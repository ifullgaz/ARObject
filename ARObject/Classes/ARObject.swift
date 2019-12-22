//
//  ARObject.swift
//  ARObject
//
//  Created by Emmanuel Merali on 17/12/2019.
//  Copyright © 2019 Test. All rights reserved.
//

import ARKit

open class ARObject: SCNNode {
    
    /// Returns a `VirtualObject` if one exists as an ancestor to the provided node.
    public static func arObjectFrom(node: SCNNode) -> ARObject? {
        if let arObjectRoot = node as? ARObject {
            return arObjectRoot
        }
        
        guard let parent = node.parent else { return nil }
        
        // Recurse up to check if the parent is a `VirtualObject`.
        return arObjectFrom(node: parent)
    }

    /// The alignments that are allowed for a virtual object.
    public var allowedAlignment: ARRaycastQuery.TargetAlignment  = .any
    
    /// Rotates the first child node of a virtual object.
    /// - Note: For correct rotation on horizontal and vertical surfaces, rotate around
    /// local y rather than world y.
    public var objectRotation: Float {
        get {
            return childNodes.first!.eulerAngles.y
        }
        set (newValue) {
            childNodes.first!.eulerAngles.y = newValue
        }
    }
    
    /// The object's corresponding ARAnchor.
    public var anchor: ARAnchor?

    /// The raycast query used when placing this object.
    public var raycastQuery: ARRaycastQuery?
    
    /// The associated tracked raycast used to place this object.
    public var raycast: ARTrackedRaycast?
    
    /// The most recent raycast result used for determining the initial location
    /// of the object after placement.
    public var mostRecentInitialPlacementResult: ARRaycastResult?
    
    /// Flag that indicates the associated anchor should be updated
    /// at the end of a pan gesture or when the object is repositioned.
    public var shouldUpdateAnchor = false

    /// Stops tracking the object's position and orientation.
    /// - Tag: StopTrackedRaycasts
    public func stopTrackedRaycast() {
        raycast?.stopTracking()
        raycast = nil
    }
    
    open func setupGeometry() {}

    // MARK: - Initialization
    required public override init() {
        super.init()
        self.setupGeometry()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
}
