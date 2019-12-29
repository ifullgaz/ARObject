//
//  ARObjectViewController.swift
//  ARObject
//
//  Created by Emmanuel Merali on 17/12/2019.
//  Copyright © 2019 Test. All rights reserved.
//

import ARKit
import ARFocusSquare
import IFGExtensions

open class ARObjectViewController: UIViewController,
                                   ARSessionDelegate,
                                   ARSCNViewDelegate,
                                   FocusNodeDelegate,
                                   ARCoachingOverlayViewDelegate,
                                   ARObjectInteractorDelegate,
                                   ARObjectViewDelegate {

    // MARK: - UI Elements
    @IBOutlet public var sceneView: ARObjectView!

    // MARK: - Class Variables
    open class var updateQueueName:String {
        String(describing: self).components(separatedBy: ".").last!
    }
    
    // MARK: - Instances Variables
    public lazy var updateQueue: DispatchQueue = {
        DispatchQueue(label: "com.arobject.\(type(of: self).updateQueueName).serialSceneKitQueue")
    }()

    /// Marks if the AR experience is available for restart.
    public var isRestartAvailable = true

    public var session: ARSession {
        sceneView!.session
    }

    // MARK: - FocusNode management
    open func shouldHideFocusSquare() -> Bool {
        return (sceneView.coachingOverlayView?.isActive ?? false)
    }
    
    open func updateFocusNode(hide: Bool) {
        if sceneView.useFocusNode, let focusNode = sceneView.focusNode {
            focusNode.set(hidden: hide, animated: true)
            focusNode.updateFocusNode()
        }
    }

    // MARK: - Focus Node Delegate
    open func focusNodeChangedDisplayState(_ node: FocusNode) {}

    // MARK: - Coaching Overlay View Delegate
    open func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        sceneView.statusView?.isHidden = true
    }
    
    /// - Tag: PresentUI
    open func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        sceneView.statusView?.isHidden = false
    }

    /// - Tag: StartOver
    open func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        restartExperience()
    }

    // MARK: - ARObjectInteractorDelegate {
    open func arObjectInteractor(_ interactor: ARObjectInteractor,
                            requestsObjectAt point: CGPoint,
                            for alignment: ARRaycastQuery.TargetAlignment,
                            completionBlock block: @escaping(_ object: ARObject?) -> Void) {
        block(nil)
    }
    
    open func arObjectInteractor(_ interactor: ARObjectInteractor,
                            didInsertObject object: ARObject,
                            at point: CGPoint) {}

    open func arObjectInteractor(_ interactor: ARObjectInteractor,
                            didFailToInsertObject object: ARObject,
                            at point: CGPoint) {}

    open func arObjectInteractor(_ interactor: ARObjectInteractor,
                            canSelectObject object: ARObject,
                            at point: CGPoint) -> Bool { return true }

    open func arObjectInteractor(_ interactor: ARObjectInteractor,
                            didSelectObject object: ARObject,
                            at point: CGPoint) {}

    open func arObjectInteractor(_ interactor: ARObjectInteractor,
                            canMoveObject object: ARObject,
                            to point: CGPoint) -> Bool { return true }

    open func arObjectInteractor(_ interactor: ARObjectInteractor,
                            didMoveObject object: ARObject,
                            to point: CGPoint) {}
    
    open func arObjectInteractor(_ interactor: ARObjectInteractor,
                            canRotateObject object: ARObject,
                            by angle: CGFloat) -> Bool { return true }

    open func arObjectInteractor(_ interactor: ARObjectInteractor,
                            didRotateObject object: ARObject,
                            by angle: CGFloat) {}

    // MARK: - ARObjectView Delegate
    open func objectView(_ view: ARObjectView, made focusNode: FocusNode) {}

    open func objectView(_ view: ARObjectView, made coachingOverlayView: ARCoachingOverlayView) {
        coachingOverlayView.activatesAutomatically = true
        coachingOverlayView.goal = .tracking
    }

    open func objectView(_ view: ARObjectView, made statusView: ARStatusView) {}

    open func objectView(_ view: ARObjectView, made objectInteractor: ARObjectInteractor) {}

    // MARK: - ARSCNViewDelegate
    open func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusNode(hide: self.shouldHideFocusSquare())
        }
    }
    
    // MARK: - ARSessionDelegate
    open func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        // Remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        self.showAlert(
            title: "The AR session failed.",
            message: errorMessage,
            buttonTitle: "Restart Session") { (_) in
                self.restartExperience()
        }
    }
    
    open func session(_ session: ARSession, didUpdate frame: ARFrame) {
        self.sceneView.statusView?.updateWorldMappingStatus(frame.worldMappingStatus)
    }
    
    /*
     Allow the session to attempt to resume after an interruption.
     This process may not succeed, so the app must be prepared
     to reset the session if the relocalizing status continues
     for a long time -- see `escalateFeedback` in `StatusViewController`.
     */
    /// - Tag: Relocalization
    open func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }

    // MARK: - Session configuration
    open func sessionConfiguration() -> ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        return configuration
    }

    open func sessionRunOptions() -> ARSession.RunOptions {
        return [.resetTracking, .removeExistingAnchors]
    }
    
    open func debugOptions() -> SCNDebugOptions {
//        return [.showFeaturePoints, .showWorldOrigin]
        return []
    }
    
    // MARK: - Session Management
    open func resetSession() {
        let configuration = sessionConfiguration()
        sceneView.debugOptions = debugOptions()
        sceneView.session.delegateQueue = self.updateQueue
        sceneView.session.run(configuration, options: sessionRunOptions())
    }

    open func restartExperience() {
        guard isRestartAvailable else { return }
        isRestartAvailable = false
        resetSession()
        self.sceneView.statusView?.cancelAllScheduledMessages()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isRestartAvailable = true
            self.sceneView.statusView?.isHidden = false
        }
    }

    // MARK: - Overriden Instances Variables
    override open var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    // MARK: - UI life cycle
    override open func viewDidLoad() {
        super.viewDidLoad()

        if sceneView == nil {
            sceneView = ARObjectView(in: self.view)
            sceneView.delegate = self
        }
        sceneView.updateQueue = updateQueue
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        resetSession()
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
}
