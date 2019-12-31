//
//  ViewController.swift
//  ARObject
//
//  Created by Emmanuel Merali on 12/19/2019.
//  Copyright (c) 2019 Emmanuel Merali. All rights reserved.
//

import ARKit
import ARObject
import ARFocusSquare

class ViewController: ARObjectViewController {
    enum SegueIdentifier: String {
        case showObjects
    }
    
    @IBOutlet weak var addObjectButton: UIButton!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    private var lastObjectAvailabilityUpdateTimestamp: TimeInterval?
    
    /// Coordinates the loading and unloading of reference nodes for virtual objects.
    let arObjectLoader = ARObjectLoader()

    /// The view controller that displays the virtual object selection menu.
    var objectsViewController: ARObjectSelectionViewController?
    
    // MARK: - Interface Actions
    /// Displays the `ARObjectSelectionViewController` from the `addObjectButton` or in response to a tap gesture in the `sceneView`.
    @IBAction func showARObjectSelectionViewController() {
        // Ensure adding objects is an available action and we are not loading another object (to avoid concurrent modifications of the scene).
        guard !addObjectButton.isHidden && !arObjectLoader.isLoading else { return }
        
        self.sceneView.statusView?.cancelScheduledMessage(type: "content")
        performSegue(withIdentifier: SegueIdentifier.showObjects.rawValue, sender: addObjectButton)
    }

    override open func shouldHideFocusSquare() -> Bool {
        let isAnyObjectInView = arObjectLoader.loadedObjects.contains { object in
            return sceneView.isNode(object, insideFrustumOf: sceneView.pointOfView!)
        }
        return super.shouldHideFocusSquare() || isAnyObjectInView
    }

    override func focusNodeChangedDisplayState(_ node: FocusNode, state: FocusNode.DisplayState) {
        switch state {
            case .initializing, .billboard:
                addObjectButton.isHidden = true
                objectsViewController?.dismiss(animated: true, completion: nil)
            default:
                if !sceneView.coachingOverlayView!.isActive {
                    addObjectButton.isHidden = false
                }
                self.sceneView.statusView?.cancelScheduledMessage(type: "focus")
        }
    }

    override func updateFocusNode(hide: Bool) {
        super.updateFocusNode(hide: hide)
        if !hide {
            DispatchQueue.main.async {
                self.sceneView.statusView?.schedule(message: "Try moving left or right", in: 5.0, type: "focus")
            }
        }
    }
    
    // MARK: - Object Interactor Delegate
    override func arObjectInteractor(_ interactor: ARObjectInteractor, requestsObjectAt point: CGPoint, for alignment: ARRaycastQuery.TargetAlignment, completionBlock block: @escaping (ARObject?) -> Void) {
        showARObjectSelectionViewController()
        block(nil)
    }

    // MARK: AROBjectView Delegate
    override func objectView(_ view: ARObjectView, made focusNode: FocusNode) {
    }

    override func objectView(_ view: ARObjectView, made coachingOverlayView: ARCoachingOverlayView) {
        coachingOverlayView.activatesAutomatically = true
        coachingOverlayView.goal = .tracking
    }

    override func objectView(_ view: ARObjectView, made statusView: ARStatusView) {
        statusView.setRestartBock(block: { (sender) in
            self.restartExperience()
        })
    }

    override func objectView(_ view: ARObjectView, made objectInteractor: ARObjectInteractor) {}

    // MARK: - ARSCNViewDelegate
    override func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        super.renderer(renderer, updateAtTime: time)
        DispatchQueue.main.async {
            // If the object selection menu is open, update availability of items
            if self.objectsViewController?.viewIfLoaded?.window != nil {
                if let lastUpdateTimestamp = self.lastObjectAvailabilityUpdateTimestamp,
                   let timestamp = self.sceneView.session.currentFrame?.timestamp,
                   timestamp - lastUpdateTimestamp < 0.5 {
                    return
                } else {
                    self.lastObjectAvailabilityUpdateTimestamp = self.sceneView.session.currentFrame?.timestamp
                }
                self.objectsViewController?.updateObjectAvailability()
            }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
        DispatchQueue.main.async {
            self.sceneView.statusView?.cancelScheduledMessage(type: "plane")
            self.sceneView.statusView?.present(message: "Surface detected")
            if self.arObjectLoader.loadedObjects.isEmpty {
                self.sceneView.statusView?.schedule(message: "TAP + TO PLACE AN OBJECT", in: 7.5, type: "content")
            }
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        DispatchQueue.main.async {
            self.sceneView.statusView?.present(message: camera.trackingState.description)
            switch camera.trackingState {
            case .notAvailable, .limited:
                self.sceneView.statusView?.schedule(message: camera.trackingState.description, in: 3.0, type: "tracking")
            case .normal:
                self.sceneView.statusView?.cancelScheduledMessage(type: "tracking")
                self.showVirtualContent()
            }
        }
    }

    func sessionWasInterrupted(_ session: ARSession) {
        // Hide content before going into the background.
        hideVirtualContent()
    }
    
    func showVirtualContent() {
        arObjectLoader.loadedObjects.forEach { $0.isHidden = false }
    }

    /// - Tag: HideVirtualContent
    func hideVirtualContent() {
        arObjectLoader.loadedObjects.forEach { $0.isHidden = true }
    }

    override func resetSession() {
        super.resetSession()
        self.sceneView.statusView?.schedule(message: "Find a surface to place an object", in: 7.5, type: "plane")
    }

    override func restartExperience() {
        guard isRestartAvailable, !arObjectLoader.isLoading else { return }
        super.restartExperience()

        arObjectLoader.removeAllARObjects()
        addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
        addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let objectInteractor = ARObjectInteractor(sceneView: sceneView)
//        objectInteractor.updateQueue = updateQueue
//        objectInteractor.delegate = self
        
        sceneView.FocusIndicatorType = FocusArc.self
    }
}

