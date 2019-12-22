//
//  ARObjectInteractor.swift
//  ARObject
//
//  Created by Emmanuel Merali on 17/12/2019.
//  Copyright © 2019 Test. All rights reserved.
//

import ARKit

/**
 A custom `UIPanGestureRecognizer` to track when a translation threshold has been exceeded
 and panning should begin.
 
 - Tag: ThresholdPanGesture
 */
public class ThresholdPanGesture: UIPanGestureRecognizer {
    
    /// Indicates whether the currently active gesture has exceeeded the threshold.
    private(set) var isThresholdExceeded = false
    
    /// Observe when the gesture's `state` changes to reset the threshold.
    public override var state: UIGestureRecognizer.State {
        didSet {
            switch state {
            case .began, .changed:
                break
                
            default:
                // Reset threshold check.
                isThresholdExceeded = false
            }
        }
    }
    
    /// Returns the threshold value that should be used dependent on the number of touches.
    private static func threshold(forTouchCount count: Int) -> CGFloat {
        switch count {
        case 1: return 30
            
        // Use a higher threshold for gestures using more than 1 finger. This gives other gestures priority.
        default: return 60
        }
    }
    
    /// - Tag: touchesMoved
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        let translationMagnitude = translation(in: view).length
        
        // Adjust the threshold based on the number of touches being used.
        let threshold = ThresholdPanGesture.threshold(forTouchCount: touches.count)
        
        if !isThresholdExceeded && translationMagnitude > threshold {
            isThresholdExceeded = true
            
            // Set the overall translation to zero as the gesture should now begin.
            setTranslation(.zero, in: view)
        }
    }
}

private extension ARSCNView {

    /// Center of the view
    var screenCenter: CGPoint {
        let bounds = self.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }

    // - Tag: CastRayForFocusSquarePosition
    func castRay(for query: ARRaycastQuery) -> [ARRaycastResult] {
        return session.raycast(query)
    }

    // - Tag: GetRaycastQuery
    func getRaycastQuery(from point: CGPoint, for alignment: ARRaycastQuery.TargetAlignment = .any) -> ARRaycastQuery? {
        return raycastQuery(from: point, allowing: .estimatedPlane, alignment: alignment)
    }
    
    func getEstimatedPlanes(from point: CGPoint, for alignment: ARRaycastQuery.TargetAlignment = .any) -> [ARRaycastResult]? {
        if let query = getRaycastQuery(from: point, for: alignment) {
            return castRay(for: query)
        }
        return nil
    }

    // MARK: Position Testing
    /// Hit tests against the `sceneView` to find an object at the provided point.
    func arObject(at point: CGPoint) -> ARObject? {
        let hitTestOptions: [SCNHitTestOption: Any] = [.boundingBoxOnly: true]
        let hitTestResults = hitTest(point, options: hitTestOptions)
        
        return hitTestResults.lazy.compactMap { result in
            return ARObject.arObjectFrom(node: result.node)
        }.first
    }
    
    // - MARK: Object anchors
    /// - Tag: AddOrUpdateAnchor
    func addOrUpdateAnchor(for object: ARObject) {
        // If the anchor is not nil, remove it from the session.
        if let anchor = object.anchor {
            session.remove(anchor: anchor)
        }
        
        // Create a new anchor with the object's current transform and add it to the session
        let newAnchor = ARAnchor(transform: object.simdWorldTransform)
        object.anchor = newAnchor
        session.add(anchor: newAnchor)
    }
}

/// Extends `UIGestureRecognizer` to provide the center point resulting from multiple touches.
private extension UIGestureRecognizer {
    func center(in view: UIView) -> CGPoint? {
        guard numberOfTouches > 0 else { return nil }
        
        let first = CGRect(origin: location(ofTouch: 0, in: view), size: .zero)

        let touchBounds = (1..<numberOfTouches).reduce(first) { touchBounds, index in
            return touchBounds.union(CGRect(origin: location(ofTouch: index, in: view), size: .zero))
        }

        return CGPoint(x: touchBounds.midX, y: touchBounds.midY)
    }
}

@objc
public protocol ARObjectInteractorDelegate: class {
    func arObjectRequested(by interactor: ARObjectInteractor,
                                at point: CGPoint,
                                for alignment: ARRaycastQuery.TargetAlignment) -> ARObject?
}

/// - Tag: VirtualObjectInteraction
open class ARObjectInteractor: NSObject, UIGestureRecognizerDelegate {
    /**
     The object that has been most recently intereacted with.
     The `selectedObject` can be moved at any time with the tap gesture.
     */
    private var selectedObject: ARObject?
    
    /// The object that is tracked for use by the pan and rotation gestures.
    private var trackedObject: ARObject? {
        didSet {
            guard trackedObject != nil else { return }
            selectedObject = trackedObject
        }
    }
    
    private var session: ARSession {
        return sceneView.session
    }
    
    /// The tracked screen position used to update the `trackedObject`'s position.
    private var currentTrackingPosition: CGPoint?
    
    /// Developer setting to translate assuming the detected plane extends infinitely.
    public var translateAssumingInfinitePlane = true
    
    /// The scene view to hit test against when moving virtual content.
    @IBOutlet
    public var sceneView: ARSCNView!
    
    /// A reference to a delegate
    @IBOutlet
    public weak var delegate: ARObjectInteractorDelegate?
    
    public var updateQueue: DispatchQueue?

    required public override init() {
        
    }
    
    convenience public init(sceneView view: ARSCNView?) {
        self.init()
        
        let panGesture = ThresholdPanGesture(target: self, action: #selector(didPan(_:)))
        panGesture.delegate = self
        sceneView.addGestureRecognizer(panGesture)

        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
        rotationGesture.delegate = self
        sceneView.addGestureRecognizer(rotationGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    private func setTransform(of arObject: ARObject, with result: ARRaycastResult) {
        arObject.simdWorldTransform = result.worldTransform
    }

    // - Tag: ProcessRaycastResults
    private func setVirtualObject3DPosition(_ results: [ARRaycastResult], with arObject: ARObject) {
        guard let result = results.first else {
            fatalError("Unexpected case: the update handler is always supposed to return at least one result.")
        }
        self.setTransform(of: arObject, with: result)
        // If the virtual object is not yet in the scene, add it.
        if arObject.parent == nil {
            self.sceneView.scene.rootNode.addChildNode(arObject)
            arObject.shouldUpdateAnchor = true
        }
        if arObject.shouldUpdateAnchor {
            arObject.shouldUpdateAnchor = false
            let queue = updateQueue ?? DispatchQueue.main
            queue.async {
                self.sceneView.addOrUpdateAnchor(for: arObject)
            }
        }
    }
    
    // - Tag: GetTrackedRaycast
    private func createRaycastAndUpdate3DPosition(of arObject: ARObject, from query: ARRaycastQuery) {
        guard let result = session.raycast(query).first else {
            return
        }
        if arObject.allowedAlignment == .any && self.trackedObject == arObject {
            // If an object that's aligned to a surface is being dragged, then
            // smoothen its orientation to avoid visible jumps, and apply only the translation directly.
            arObject.simdWorldPosition = result.worldTransform.translation
            let previousOrientation = arObject.simdWorldTransform.orientation
            let currentOrientation = result.worldTransform.orientation
            arObject.simdWorldOrientation = simd_slerp(previousOrientation, currentOrientation, 0.1)
        } else {
            self.setTransform(of: arObject, with: result)
        }
    }
    
    private func createTrackedRaycastAndSet3DPosition(of arObject: ARObject,
                                              from query: ARRaycastQuery,
                                              withInitialResult initialResult: ARRaycastResult? = nil) -> ARTrackedRaycast? {
        if let initialResult = initialResult {
            self.setTransform(of: arObject, with: initialResult)
        }
        
        return session.trackedRaycast(query) { (results) in
            self.setVirtualObject3DPosition(results, with: arObject)
        }
    }
    
    private func updatedTrackingPosition(for object: ARObject, from gesture: UIPanGestureRecognizer) -> CGPoint {
        let translation = gesture.translation(in: sceneView)
        
        let currentPosition = currentTrackingPosition ?? CGPoint(sceneView.projectPoint(object.position))
        let updatedPosition = CGPoint(x: currentPosition.x + translation.x, y: currentPosition.y + translation.y)
        currentTrackingPosition = updatedPosition
        return updatedPosition
    }

    /** A helper method to return the first object that is found under the provided `gesture`s touch locations.
     Performs hit tests using the touch locations provided by gesture recognizers. By hit testing against the bounding
     boxes of the virtual objects, this function makes it more likely that a user touch will affect the object even if the
     touch location isn't on a point where the object has visible content. By performing multiple hit tests for multitouch
     gestures, the method makes it more likely that the user touch affects the intended object.
      - Tag: TouchTesting
    */
    private func objectInteracting(with gesture: UIGestureRecognizer, in view: ARSCNView) -> ARObject? {
        for index in 0..<gesture.numberOfTouches {
            let touchLocation = gesture.location(ofTouch: index, in: view)
            // Look for an object directly under the `touchLocation`.
            if let object = sceneView.arObject(at: touchLocation) {
                return object
            }
        }

        // As a last resort look for an object under the center of the touches.
        if let center = gesture.center(in: view) {
            return sceneView.arObject(at: center)
        }
        
        return nil
    }
    
    // MARK: - Update object position
    /// - Tag: DragVirtualObject
    private func translate(_ object: ARObject, basedOn screenPos: CGPoint) {
        object.stopTrackedRaycast()
        
        // Update the object by using a one-time position request.
        if let query = sceneView.raycastQuery(from: screenPos, allowing: .estimatedPlane, alignment: object.allowedAlignment) {
            createRaycastAndUpdate3DPosition(of: object, from: query)
        }
    }
    
    private func setDown(_ object: ARObject, basedOn screenPos: CGPoint) {
        object.stopTrackedRaycast()
        
        // Prepare to update the object's anchor to the current location.
        object.shouldUpdateAnchor = true
        
        // Attempt to create a new tracked raycast from the current location.
        if let query = sceneView.raycastQuery(from: screenPos, allowing: .estimatedPlane, alignment: object.allowedAlignment),
            let raycast = createTrackedRaycastAndSet3DPosition(of: object, from: query) {
            object.raycast = raycast
        } else {
            // If the tracked raycast did not succeed, simply update the anchor to the object's current position.
            object.shouldUpdateAnchor = false
            let queue = updateQueue ?? DispatchQueue.main
            queue.async {
                self.sceneView.addOrUpdateAnchor(for: object)
            }
        }
    }

    // MARK: Gesture Regognizer Delegate
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow objects to be translated and rotated at the same time.
        return true
    }

    // MARK: - Gesture Actions
    @objc
    func didPan(_ gesture: ThresholdPanGesture) {
        switch gesture.state {
        case .began:
            // Check for an object at the touch location.
            if let object = objectInteracting(with: gesture, in: sceneView) {
                trackedObject = object
            }
            
        case .changed where gesture.isThresholdExceeded:
            guard let object = trackedObject else { return }
            // Move an object if the displacment threshold has been met.
            translate(object, basedOn: updatedTrackingPosition(for: object, from: gesture))

            gesture.setTranslation(.zero, in: sceneView)
            
        case .changed:
            // Ignore the pan gesture until the displacment threshold is exceeded.
            break
            
        case .ended:
            // Update the object's position when the user stops panning.
            guard let object = trackedObject else { break }
            setDown(object, basedOn: updatedTrackingPosition(for: object, from: gesture))
            
            fallthrough
            
        default:
            // Reset the current position tracking.
            currentTrackingPosition = nil
            trackedObject = nil
        }
    }
    
    /**
     For looking down on the object (99% of all use cases), you subtract the angle.
     To make rotation also work correctly when looking from below the object one would have to
     flip the sign of the angle depending on whether the object is above or below the camera.
     - Tag: didRotate */
    @objc
    func didRotate(_ gesture: UIRotationGestureRecognizer) {
        guard gesture.state == .changed else { return }
        
        trackedObject?.objectRotation -= Float(gesture.rotation)
        
        gesture.rotation = 0
    }
    
    /// Handles the interaction when the user taps the screen.
    @objc
    func didTap(_ gesture: UITapGestureRecognizer) {
        let touchLocation = gesture.location(in: sceneView)
        
        if let tappedObject = sceneView.arObject(at: touchLocation) {
            // If an object exists at the tap location, select it.
            selectedObject = tappedObject
        } else if let object = selectedObject {
            // Otherwise, move the selected object to its new position at the tap location.
            setDown(object, basedOn: touchLocation)
            selectedObject = nil
        } else if let delegate = delegate {
            if let plane = sceneView.getEstimatedPlanes(from: touchLocation)?.first,
               let object = delegate.arObjectRequested(by: self,
                                                       at: touchLocation,
                                                       for: plane.targetAlignment) {
                place(arObject: object)
            }
        }
    }

    public func canPlace(arObject: ARObject, at point: CGPoint) -> Bool {
        if let query = sceneView.getRaycastQuery(from: point, for: arObject.allowedAlignment),
           let result = sceneView.castRay(for: query).first {
            arObject.mostRecentInitialPlacementResult = result
            arObject.raycastQuery = query
            return true
        }
        return false
    }
    
    public func place(arObject: ARObject) {
        guard let query = arObject.raycastQuery else { return }

        let trackedRaycast = createTrackedRaycastAndSet3DPosition(of: arObject,
                                                                  from: query,
                                                                  withInitialResult: arObject.mostRecentInitialPlacementResult)

        arObject.raycast = trackedRaycast
        arObject.isHidden = false
    }
}
