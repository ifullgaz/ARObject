//
//  ARObjectView.swift
//  ARObject
//
//  Created by Emmanuel Merali on 18/12/2019.
//  Copyright © 2019 Test. All rights reserved.
//

import ARKit
import ARFocusSquare

private extension ARObjectView {
    func removeFocusNode(focusNode: FocusNode?) {
        if let focusNode = focusNode {
            focusNode.removeFromParentNode()
            if manageFocusNode {
                focusNode.sceneView = nil
                focusNode.delegate = nil
                focusNode.updateQueue = nil
            }
        }
    }
    
    func updateFocusNodeIfNeeded() {
#if TARGET_INTERFACE_BUILDER
        useFocusNodeIndicator.isOn = useFocusNode
#else
        if useFocusNode {
            if focusNode == nil {
                let focusNode = self.focusNodeType.init()
                self.focusNode = focusNode
                manageFocusNode = true
            }
            if let focusNode = focusNode {
                if manageFocusNode {
                    focusNode.sceneView = self
                    focusNode.updateQueue = updateQueue
                    if let focusNodeDelegate = delegate as? FocusNodeDelegate {
                        focusNode.delegate = focusNodeDelegate
                    }
                }
                self.scene.rootNode.addChildNode(focusNode)
            }
        }
        else {
            removeFocusNode(focusNode: focusNode)
        }
#endif
    }

    func removeCoachingOverlayView(coachingOverlayView: ARCoachingOverlayView?) {
        if let coachingOverlayView = coachingOverlayView {
            coachingOverlayView.removeFromSuperview()
            if manageCoachingOverlayView {
                coachingOverlayView.delegate = nil
                coachingOverlayView.sessionProvider = nil
            }
        }
    }
    
    func updateCoachingOverlayViewIfNeeded() {
#if TARGET_INTERFACE_BUILDER
        useCoachingOverlayViewindicator.isOn = useCoachingOverlayView
#else
        if useCoachingOverlayView {
            if coachingOverlayView == nil {
                let coachingOverlayView = ARCoachingOverlayView()
                self.coachingOverlayView = coachingOverlayView
                coachingOverlayView.activatesAutomatically = true
                coachingOverlayView.goal = .tracking
                manageCoachingOverlayView = true
            }
            if let coachingOverlayView = coachingOverlayView {
                if manageCoachingOverlayView {
                    coachingOverlayView.sessionProvider = self
                    if let coachingOverlayViewDelegate = delegate as? ARCoachingOverlayViewDelegate {
                        coachingOverlayView.delegate = coachingOverlayViewDelegate
                    }
                }
                // This will remove any existing constraints if any
                coachingOverlayView.removeFromSuperview()
                self.addSubview(coachingOverlayView)
                coachingOverlayView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    coachingOverlayView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                    coachingOverlayView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                    coachingOverlayView.widthAnchor.constraint(equalTo: self.widthAnchor),
                    coachingOverlayView.heightAnchor.constraint(equalTo: self.heightAnchor)
                    ])
            }
        }
        else {
            removeCoachingOverlayView(coachingOverlayView: coachingOverlayView)
        }
#endif
    }

    func removeStatusView(statusView: ARStatusDisplayer?) {
        if let statusView = statusView {
            statusView.removeFromSuperview()
        }
    }
    
    func updateStatusViewIfNeeded() {
#if TARGET_INTERFACE_BUILDER
        useStatusViewIndicator.isOn = useStatusView
#else
        if useStatusView {
            if statusView == nil {
                let statusView = ARStatusView()
                self.statusView = statusView
                manageStatusView = true
            }
            if let statusView = statusView {
                statusView.removeFromSuperview()
                self.addSubview(statusView)
                statusView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    statusView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                    statusView.widthAnchor.constraint(equalTo: self.widthAnchor),
                    statusView.heightAnchor.constraint(equalToConstant: 64),
                    statusView.topAnchor.constraint(equalTo: self.topAnchor, constant: 80)
                ])
            }
        }
        else {
            removeStatusView(statusView: statusView)
        }
#endif
    }

    func removeObjectInteractor(objectInteractor: ARObjectInteractor?) {
        if let objectInteractor = objectInteractor {
            if manageObjectInteractor {
                objectInteractor.sceneView = nil
                objectInteractor.updateQueue = nil
                objectInteractor.delegate = nil
            }
        }
    }
    
    func updateObjectInteractorIfNeeded() {
#if TARGET_INTERFACE_BUILDER
        useObjectInteractorIndicator.isOn = useObjectInteractor
#else
        if useObjectInteractor {
            if objectInteractor == nil {
                let objectInteractor = ARObjectInteractor()
                self.objectInteractor = objectInteractor
                manageObjectInteractor = true
            }
            if let objectInteractor = objectInteractor {
                if manageObjectInteractor {
                    objectInteractor.sceneView = self
                    objectInteractor.updateQueue = updateQueue
                    if let objectInteractorDelegate = delegate as? ARObjectInteractorDelegate {
                        objectInteractor.delegate = objectInteractorDelegate
                    }
                }
            }
        }
        else {
            removeObjectInteractor(objectInteractor: objectInteractor)
        }
#endif
    }

    func updateDependentObjects() {
#if TARGET_INTERFACE_BUILDER
        self.addSubview(useFocusNodeIndicator)
        self.addSubview(useCoachingOverlayViewindicator)
        self.addSubview(useStatusViewIndicator)
        self.addSubview(useObjectInteractorIndicator)
        self.updateFocusNodeIfNeeded()
        self.updateCoachingOverlayViewIfNeeded()
        self.updateStatusViewIfNeeded()
        self.updateObjectInteractorIfNeeded()
        self.dependentObjectsUpdated = true
#endif
        // Dispatching the creation of objects gives the opportunity to configure the
        // view before creating objects that may not be needed
        DispatchQueue.main.async {
            self.updateFocusNodeIfNeeded()
            self.updateCoachingOverlayViewIfNeeded()
            self.updateStatusViewIfNeeded()
            self.updateObjectInteractorIfNeeded()
            self.dependentObjectsUpdated = true
        }
    }
}

@IBDesignable
open class ARObjectView: ARSCNView {

    // MARK: - IB Support
    #if TARGET_INTERFACE_BUILDER
    var useFocusNodeIndicator: FocusNodeIndicator = FocusNodeIndicator(frame: CGRect(x: 5, y: 50, width: 20, height: 20))
    var useCoachingOverlayViewindicator: CoachingOverlayViewIndicator = CoachingOverlayViewIndicator(frame: CGRect(x: 40, y: 50, width: 20, height: 20))
    var useObjectInteractorIndicator: ObjectInteractorIndicator = ObjectInteractorIndicator(frame: CGRect(x: 75, y: 50, width: 20, height: 20))
    var useStatusViewIndicator: StatusViewIndicator = StatusViewIndicator(frame: CGRect(x: 110, y: 50, width: 20, height: 20))
    #endif

    // MARK: - Class variables
    /// Returns the class used to create the focus node if in use
    /// - returns: the class used to create the focus node
    ///
    /// This method returns the FocusSquare class object by default. Subclasses can override this method and return a different layer class as needed. For example, if you want to display a simple square, you might want to override this property and return the FocusPlane class, as shown here:
    ///
    ///    Returning a FocusPlane
    ///````
    ///    override class var focusNodeType: FocusNode.Type {
    ///       return FocusPlane.self}
    ///````
    ///    This method is called only once early in the creation of the view in order to create the focus node.
    open class var focusNodeType: FocusNode.Type { return FocusSquare.self }

    // MARK: - Instance variables
    /// Set to true to see the focus node
    private var manageFocusNode: Bool = false
    private var manageCoachingOverlayView: Bool = false
    private var manageObjectInteractor: Bool = false
    private var manageStatusView: Bool = false
    private var dependentObjectsUpdated: Bool = false

    @IBInspectable
    open var useFocusNode: Bool = true {
        didSet {
            guard useFocusNode != oldValue, dependentObjectsUpdated else { return }
            updateFocusNodeIfNeeded()
        }
    }

    /// Set to true to see the coaching overlay view
    @IBInspectable
    open var useCoachingOverlayView: Bool = true {
        didSet {
            guard useCoachingOverlayView != oldValue, dependentObjectsUpdated else { return }
            updateCoachingOverlayViewIfNeeded()
        }
    }

    @IBInspectable
    open var useObjectInteractor: Bool = true {
        didSet {
            guard useObjectInteractor != oldValue, dependentObjectsUpdated else { return }
            updateObjectInteractorIfNeeded()
        }
    }

    @IBInspectable
    open var useStatusView: Bool = true {
        didSet {
            guard useStatusView != oldValue, dependentObjectsUpdated else { return }
            updateStatusViewIfNeeded()
        }
    }

    @IBOutlet
    public var updateQueue: DispatchQueue? = nil {
        didSet {
            guard updateQueue !== oldValue else { return }
            if dependentObjectsUpdated {
                updateDependentObjects()
            }
        }
    }
    
    @IBOutlet
    public var focusNode: FocusNode? = nil {
        didSet {
            guard focusNode !== oldValue else { return }
            removeFocusNode(focusNode: oldValue)
            manageFocusNode = false
        }
    }

    @IBOutlet
    public var coachingOverlayView: ARCoachingOverlayView? = nil {
        didSet {
            guard coachingOverlayView !== oldValue else { return }
            removeCoachingOverlayView(coachingOverlayView: oldValue)
            manageCoachingOverlayView = false
        }
    }

    @IBOutlet
    public var objectInteractor: ARObjectInteractor? = nil {
        didSet {
            guard objectInteractor !== oldValue else { return }
            removeObjectInteractor(objectInteractor: oldValue)
            manageObjectInteractor = false
        }
    }
    
    @IBOutlet
    public var statusView: ARStatusDisplayer? = nil {
        didSet {
            guard statusView !== oldValue else { return }
            removeStatusView(statusView: oldValue)
            manageStatusView = false
        }
    }
    
    @IBOutlet
    open override var delegate: ARSCNViewDelegate? {
        didSet {
            guard delegate !== oldValue else { return }
            if let sessionDelegate = delegate as? ARSessionDelegate {
                self.session.delegate = sessionDelegate
            }
            if dependentObjectsUpdated {
                updateDependentObjects()
            }
        }
    }

    public var focusNodeType: FocusNode.Type = FocusSquare.self

    // MARK: - Initialization
    convenience public init(in view: UIView) {
        self.init(frame: view.frame)
        view.addSubview(self)
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            self.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            self.widthAnchor.constraint(equalTo: view.widthAnchor),
            self.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        view.sendSubviewToBack(self)
    }
    
    override public init(frame: CGRect, options: [String : Any]? = nil) {
        super.init(frame: frame, options: options)
        updateDependentObjects()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        updateDependentObjects()
    }
}
