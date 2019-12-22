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

open class ARObjectViewController: UIViewController, ARSessionDelegate, ARObjectViewDelegate {

    // MARK: - UI Elements
    @IBOutlet public var sceneView: ARObjectView!

    // MARK: - Overriden Instances Variables
    override open var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    // MARK: - Instances Variables
    lazy var updateQueue: DispatchQueue = {
        DispatchQueue(label: "com.arobject.\(String(describing: self)).serialSceneKitQueue")
    }()

    /// Marks if the AR experience is available for restart.
    public var isRestartAvailable = true

    // MARK: - FocusNode delegate
    open func shouldHideFocusSquare() -> Bool {
        return (sceneView!.coachingOverlayView?.isActive ?? false)
    }
    
    open func updateFocusSquare(hide: Bool) {
        if let focusNode = sceneView!.focusNode {
            if hide {
                focusNode.hide()
            } else {
                focusNode.unhide()
                focusNode.updateFocusNode()
            }
        }
    }

    open func focusNode(_ node: FocusNode, changedDisplayState state: FocusNode.DisplayState) {}

    // MARK: - ARSCNViewDelegate
    open func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        self.updateFocusSquare(hide: self.shouldHideFocusSquare())
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
        return [.showFeaturePoints, .showWorldOrigin]
    }
    
    open func resetSession() {
        let configuration = sessionConfiguration()
        sceneView.debugOptions = debugOptions()
        sceneView.session.run(configuration, options: sessionRunOptions())
    }

    open func restartExperience() {
        guard isRestartAvailable else { return }
        isRestartAvailable = false
        resetSession()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isRestartAvailable = true
        }
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        if sceneView == nil {
            sceneView = ARObjectView(frame: CGRect())
            view.addSubview(sceneView)
            sceneView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                sceneView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                sceneView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                sceneView.widthAnchor.constraint(equalTo: view.widthAnchor),
                sceneView.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])
            sceneView.delegate = self
            view.sendSubviewToBack(sceneView)
        }
        sceneView.focusNode?.updateQueue = updateQueue
        sceneView.useFocusNode = true
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
