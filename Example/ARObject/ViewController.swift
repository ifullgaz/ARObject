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
    
    @IBOutlet weak var upperControlsView: UIView!

    private var lastObjectAvailabilityUpdateTimestamp: TimeInterval?
    
    /// Coordinates the loading and unloading of reference nodes for virtual objects.
    let arObjectLoader = ARObjectLoader()

    var statusViewController: StatusViewController {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }

    /// The view controller that displays the virtual object selection menu.
    var objectsViewController: ARObjectSelectionViewController?
    
    // MARK: - Interface Actions
    /// Displays the `ARObjectSelectionViewController` from the `addObjectButton` or in response to a tap gesture in the `sceneView`.
    @IBAction func showARObjectSelectionViewController() {
        // Ensure adding objects is an available action and we are not loading another object (to avoid concurrent modifications of the scene).
        guard !addObjectButton.isHidden && !arObjectLoader.isLoading else { return }
        
        statusViewController.cancelScheduledMessage(for: .contentPlacement)
        performSegue(withIdentifier: SegueIdentifier.showObjects.rawValue, sender: addObjectButton)
    }

    override open func shouldHideFocusSquare() -> Bool {
        let isAnyObjectInView = arObjectLoader.loadedObjects.contains { object in
            return sceneView.isNode(object, insideFrustumOf: sceneView.pointOfView!)
        }
        return super.shouldHideFocusSquare() || isAnyObjectInView
    }

    override func focusNodeChangedDisplayState(_ node: FocusNode) {
        if node.detectionState == .initializing {
            addObjectButton.isHidden = true
            objectsViewController?.dismiss(animated: true, completion: nil)
        } else {
            if !sceneView.coachingOverlayView!.isActive {
                addObjectButton.isHidden = false
            }
            statusViewController.cancelScheduledMessage(for: .focusNode)
        }
    }

    override func updateFocusNode(hide: Bool) {
        super.updateFocusNode(hide: hide)
        if !hide {
            DispatchQueue.main.async {
                self.statusViewController.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusNode)
            }
        }
    }
    
    // MARK: - ARCoachingOverlayViewDelegate
    /// - Tag: HideUI
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        upperControlsView.isHidden = true
    }
    
    /// - Tag: PresentUI
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        upperControlsView.isHidden = false
    }

    // MARK: - Object Interactor Delegate
    override func arObjectInteractor(_ interactor: ARObjectInteractor, requestsObjectAt point: CGPoint, for alignment: ARRaycastQuery.TargetAlignment, completionBlock block: @escaping (ARObject?) -> Void) {
        showARObjectSelectionViewController()
        block(nil)
    }

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
            self.statusViewController.cancelScheduledMessage(for: .planeEstimation)
            self.statusViewController.showMessage("SURFACE DETECTED")
            if self.arObjectLoader.loadedObjects.isEmpty {
                self.statusViewController.scheduleMessage("TAP + TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .contentPlacement)
            }
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        DispatchQueue.main.async {
            self.statusViewController.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
            switch camera.trackingState {
            case .notAvailable, .limited:
                self.statusViewController.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
            case .normal:
                self.statusViewController.cancelScheduledMessage(for: .trackingStateEscalation)
                self.showVirtualContent()
            }
        }
    }

    func sessionWasInterrupted(_ session: ARSession) {
        // Hide content before going into the background.
        hideVirtualContent()
    }
    
    /*
     Allow the session to attempt to resume after an interruption.
     This process may not succeed, so the app must be prepared
     to reset the session if the relocalizing status continues
     for a long time -- see `escalateFeedback` in `StatusViewController`.
     */
    /// - Tag: Relocalization
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
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
        self.statusViewController.scheduleMessage("FIND A SURFACE TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .planeEstimation)
    }

    override func restartExperience() {
        guard isRestartAvailable, !arObjectLoader.isLoading else { return }
        super.restartExperience()

        statusViewController.cancelAllScheduledMessages()
        arObjectLoader.removeAllARObjects()
        addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
        addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])
        // Disable restart for a while in order to give the session time to restart.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.upperControlsView.isHidden = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let objectInteractor = ARObjectInteractor(sceneView: sceneView)
        objectInteractor.updateQueue = updateQueue
        objectInteractor.delegate = self
    }
}

