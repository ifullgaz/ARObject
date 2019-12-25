//
//  ARObjectInteractor.swift
//  ARObject
//
//  Created by Emmanuel Merali on 17/12/2019.
//  Copyright © 2019 Test. All rights reserved.
//

import ARKit

// MARK: - Gestures recognition
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

    public func cancel() {
        let wasEnabled = isEnabled
        self.isEnabled = false
        self.isEnabled = wasEnabled
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

// MARK: - ARSCNView helpers
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
        let hitTestOptions: [SCNHitTestOption: Any] = [.boundingBoxOnly: true, .searchMode: 1]
        let hitTestResults = hitTest(point, options: hitTestOptions)
        
        return hitTestResults.lazy.compactMap { result in
            return ARObject.arObjectFrom(node: result.node)
        }.first
    }
}

// MARK: - ARObjectInteractorDelegate
public protocol ARObjectInteractorDelegate: class {
    func arObjectInteractor(_ interactor: ARObjectInteractor,
                            requestsObjectAt point: CGPoint,
                            for alignment: ARRaycastQuery.TargetAlignment,
                            completionBlock block: @escaping(_ object: ARObject?) -> Void)

    func arObjectInteractor(_ interactor: ARObjectInteractor,
                            didInsertObject object: ARObject,
                            at point: CGPoint)

    func arObjectInteractor(_ interactor: ARObjectInteractor,
                            didFailToInsertObject object: ARObject,
                            at point: CGPoint)

    func arObjectInteractor(_ interactor: ARObjectInteractor,
                            canSelectObject object: ARObject,
                            at point: CGPoint) -> Bool

    func arObjectInteractor(_ interactor: ARObjectInteractor,
                            didSelectObject object: ARObject,
                            at point: CGPoint)

    func arObjectInteractor(_ interactor: ARObjectInteractor,
                            canMoveObject object: ARObject,
                            to point: CGPoint) -> Bool

    func arObjectInteractor(_ interactor: ARObjectInteractor,
                            didMoveObject object: ARObject,
                            to point: CGPoint)

    func arObjectInteractor(_ interactor: ARObjectInteractor,
                            canRotateObject object: ARObject,
                            by angle: CGFloat) -> Bool

    func arObjectInteractor(_ interactor: ARObjectInteractor,
                            didRotateObject object: ARObject,
                            by angle: CGFloat)
}

public extension ARObjectInteractorDelegate {
//    func arObjectInteractor(_ interactor: ARObjectInteractor,
//                            requestsObjectAt point: CGPoint,
//                            for alignment: ARRaycastQuery.TargetAlignment,
//                            completionBlock block: @escaping(_ object: ARObject?) -> Void) {
//        block(nil)
//    }
//    
//    func arObjectInteractor(_ interactor: ARObjectInteractor,
//                            didInsertObject object: ARObject,
//                            at point: CGPoint) {}
//
//    func arObjectInteractor(_ interactor: ARObjectInteractor,
//                            didFailToInsertObject object: ARObject,
//                            at point: CGPoint) {}
//
//    func arObjectInteractor(_ interactor: ARObjectInteractor,
//                            canSelectObject object: ARObject,
//                            at point: CGPoint) -> Bool { return true }
//
//    func arObjectInteractor(_ interactor: ARObjectInteractor,
//                            didSelectObject object: ARObject,
//                            at point: CGPoint) {}
//
//    func arObjectInteractor(_ interactor: ARObjectInteractor,
//                            canMoveObject object: ARObject,
//                            to point: CGPoint) -> Bool { return true }
//
//    func arObjectInteractor(_ interactor: ARObjectInteractor,
//                            didMoveObject object: ARObject,
//                            to point: CGPoint) {}
//    
//    func arObjectInteractor(_ interactor: ARObjectInteractor,
//                            canRotateObject object: ARObject,
//                            by angle: CGFloat) -> Bool { return true }
//
//    func arObjectInteractor(_ interactor: ARObjectInteractor,
//                            didRotateObject object: ARObject,
//                            by angle: CGFloat) {}
}

// MARK: - ARObjectInteractor
/// - Tag: ARObjectInteractor
open class ARObjectInteractor: NSObject, UIGestureRecognizerDelegate {

    // MARK: - Private variables
    /**
     The object that has been most recently intereacted with.
     The `selectedObject` can be moved at any time with the tap gesture.
     */
    private var selectedObject: ARObject?
    
    /// The object that is tracked for use by the pan and rotation gestures.
    private var trackedObject: ARObject? {
        didSet {
//            guard trackedObject != nil else { return }
//            selectedObject = trackedObject
        }
    }
    
    private var session: ARSession {
        return sceneView.session
    }
    
    /// The tracked screen position used to update the `trackedObject`'s position.
    private var currentTrackingPosition: CGPoint?

    /// The current gesture recognizers
    private var gestureRecognizers: [UIGestureRecognizer] = []
    
    /// Developer setting to translate assuming the detected plane extends infinitely.
    public var translateAssumingInfinitePlane = true
    
    // MARK: - Public variables
    /// The scene view to hit test against when moving virtual content.
    @IBOutlet
    public weak var sceneView: ARObjectView! {
        didSet {
            guard sceneView !== oldValue else { return }
            /// Remove all gesture recognizers from the old view
            for gestureRecognizer in gestureRecognizers {
                oldValue?.removeGestureRecognizer(gestureRecognizer)
            }
            guard let sceneView = sceneView else {
                gestureRecognizers = []
                return
            }
            /// Create new Gesture recognizers for the view
            let panGesture = ThresholdPanGesture(target: self, action: #selector(didPan(_:)))
            panGesture.delegate = self
            sceneView.addGestureRecognizer(panGesture)

            let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
            rotationGesture.delegate = self
            sceneView.addGestureRecognizer(rotationGesture)

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
            sceneView.addGestureRecognizer(tapGesture)
            
            gestureRecognizers = [panGesture, rotationGesture, tapGesture]
        }
    }
    
    /// A reference to a delegate
    @IBOutlet
    public weak var delegate: AnyObject?
    
    @IBOutlet
    public weak var updateQueue: DispatchQueue?

    // MARK: - Private interface
    private func setTransform(of arObject: ARObject, with result: ARRaycastResult) {
        arObject.simdWorldTransform = result.worldTransform
    }
    
    // - MARK: - Object anchors
    /// - Tag: AddOrUpdateAnchor
    func addOrUpdateAnchor(for object: ARObject) {
        // If the anchor is not nil, remove it from the session.
        if let anchor = object.anchor {
            session.remove(anchor: anchor)
        }
        
        // Create a new anchor with the object's current transform and add it to the session
        let newAnchor = ARAnchor(name: object.name ?? "", transform: object.simdWorldTransform)
        object.anchor = newAnchor
        session.add(anchor: newAnchor)
    }

    // - Tag: ProcessRaycastResults
    private func setObjectPosition(_ results: [ARRaycastResult], with arObject: ARObject) {
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
                self.addOrUpdateAnchor(for: arObject)
            }
        }
    }
    
    private func createTrackedRaycast(of arObject: ARObject,
                                      from query: ARRaycastQuery) -> ARTrackedRaycast? {
        return session.trackedRaycast(query) { (results) in
            self.setObjectPosition(results, with: arObject)
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
    private func translate(_ object: ARObject, basedOn screenPos: CGPoint) {
        object.stopTrackedRaycast()
        
        // Update the object by using a one-time position request.
        if let query = sceneView.raycastQuery(from: screenPos, allowing: .estimatedPlane, alignment: object.allowedAlignment),
           let result = session.raycast(query).first {
            if object.allowedAlignment == .any && self.trackedObject == object {
                // If an object that's aligned to a surface is being dragged, then
                // smoothen its orientation to avoid visible jumps, and apply only the translation directly.
                object.simdWorldPosition = result.worldTransform.translation
                let previousOrientation = object.simdWorldTransform.orientation
                let currentOrientation = result.worldTransform.orientation
                object.simdWorldOrientation = simd_slerp(previousOrientation, currentOrientation, 0.1)
            } else {
                self.setTransform(of: object, with: result)
            }
        }
    }
    
    private func setDown(_ object: ARObject, basedOn screenPos: CGPoint) {
        object.stopTrackedRaycast()
        
        // Prepare to update the object's anchor to the current location.
        object.shouldUpdateAnchor = true
        
        // Attempt to create a new tracked raycast from the current location.
        if let query = sceneView.raycastQuery(from: screenPos, allowing: .estimatedPlane, alignment: object.allowedAlignment),
           let raycast = createTrackedRaycast(of: object, from: query) {
            object.raycast = raycast
        } else {
            // If the tracked raycast did not succeed, simply update the anchor to the object's current position.
            object.shouldUpdateAnchor = false
            let queue = updateQueue ?? DispatchQueue.main
            queue.async {
                self.addOrUpdateAnchor(for: object)
            }
        }
    }
    
    // MARK: Gesture Actions
    @objc
    private func didPan(_ gesture: ThresholdPanGesture) {
        switch gesture.state {
        case .began:
            // Check for an object at the touch location.
            if let object = objectInteracting(with: gesture, in: sceneView) {
                var canMove = true
                if let delegate = delegate as? ARObjectInteractorDelegate {
                    let touchLocation = gesture.location(in: sceneView)
                    canMove = delegate.arObjectInteractor(self, canMoveObject: object, to: touchLocation)
                }
                if canMove {
                    trackedObject = object
                }
            }
            
        case .changed where gesture.isThresholdExceeded:
            guard let object = trackedObject else { return }
            let touchLocation = updatedTrackingPosition(for: object, from: gesture)
            // Move an object if the displacment threshold has been met.
            translate(object, basedOn: touchLocation)
            if let delegate = delegate as? ARObjectInteractorDelegate {
                delegate.arObjectInteractor(self, didMoveObject: object, to: touchLocation)
            }
            gesture.setTranslation(.zero, in: sceneView)
            
        case .changed:
            // Ignore the pan gesture until the displacment threshold is exceeded.
            break
            
        case .ended:
            // Update the object's position when the user stops panning.
            guard let object = trackedObject else { break }
            let touchLocation = updatedTrackingPosition(for: object, from: gesture)
            setDown(object, basedOn: touchLocation)
            if let delegate = delegate as? ARObjectInteractorDelegate {
                delegate.arObjectInteractor(self, didMoveObject: object, to: touchLocation)
            }

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
    private func didRotate(_ gesture: UIRotationGestureRecognizer) {
        guard gesture.state == .changed else { return }
        if let trackedObject = trackedObject {
            var canRotate = true
            if let delegate = delegate as? ARObjectInteractorDelegate {
                canRotate = delegate.arObjectInteractor(self, canRotateObject: trackedObject, by: gesture.rotation)
            }
            if canRotate {
                trackedObject.objectRotation -= Float(gesture.rotation)
                if let delegate = delegate as? ARObjectInteractorDelegate {
                    delegate.arObjectInteractor(self, didRotateObject: trackedObject, by: gesture.rotation)
                }
            }
        }
        gesture.rotation = 0
    }
    
    /// Handles the interaction when the user taps the screen.
    @objc
    private func didTap(_ gesture: UITapGestureRecognizer) {
        let touchLocation = gesture.location(in: sceneView)
        
        if let tappedObject = sceneView.arObject(at: touchLocation) {
            // If an object exists at the tap location, select it.
            var canSelect = true
            if let delegate = delegate as? ARObjectInteractorDelegate {
                delegate.arObjectInteractor(self, didSelectObject: tappedObject, at: touchLocation)
                canSelect = delegate.arObjectInteractor(self, canSelectObject: tappedObject, at: touchLocation)
            }
            if canSelect {
                selectedObject = tappedObject
            }
        } else if let object = selectedObject {
            // Otherwise, if we have a previously selected object,
            // move the selected object to its new position at the tap location.
            var canMove = true
            if let delegate = delegate as? ARObjectInteractorDelegate {
                canMove = delegate.arObjectInteractor(self, canMoveObject: object, to: touchLocation)
            }
            if canMove {
                setDown(object, basedOn: touchLocation)
                if let delegate = delegate as? ARObjectInteractorDelegate {
                    delegate.arObjectInteractor(self, didMoveObject: object, to: touchLocation)
                }
            }
            selectedObject = nil
        } else if let delegate = delegate as? ARObjectInteractorDelegate,
                  let query = sceneView.getRaycastQuery(from: touchLocation),
                  let plane = sceneView.castRay(for: query).first {
                    delegate.arObjectInteractor(self,
                                               requestsObjectAt: touchLocation,
                                               for: plane.targetAlignment) { (object) -> Void in
                guard let object = object else { return }
                if self.canPlace(arObject: object, at: touchLocation) &&
                   self.place(arObject: object) {
                    delegate.arObjectInteractor(self, didInsertObject: object, at: touchLocation)
                }
                else {
                    delegate.arObjectInteractor(self, didFailToInsertObject: object, at: touchLocation)
                }
            }
        }
    }

    // MARK: - Gesture Regognizer Delegate
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow objects to be translated and rotated at the same time.
        return true
    }

    // MARK: - Public interface
    public func canPlace(arObject: ARObject, at point: CGPoint) -> Bool {
        if let query = sceneView.getRaycastQuery(from: point, for: arObject.allowedAlignment),
           let _ = sceneView.castRay(for: query).first {
            arObject.raycastQuery = query
            return true
        }
        return false
    }
    
    public func place(arObject: ARObject) -> Bool {
        guard let query = arObject.raycastQuery else { return false }

        let trackedRaycast = createTrackedRaycast(of: arObject,
                                                  from: query)

        arObject.raycast = trackedRaycast
        arObject.isHidden = false
        return true
    }
    
    // MARK: - Initialization
    convenience public init(sceneView view: ARObjectView) {
        self.init()
        sceneView = view
    }
}
