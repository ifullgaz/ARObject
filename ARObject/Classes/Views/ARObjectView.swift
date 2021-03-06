//
//  ARObjectView.swift
//  ARObject
//
//  Created by Emmanuel Merali on 18/12/2019.
//  Copyright © 2019 Test. All rights reserved.
//

import ARKit
import ARFocusSquare

public protocol ARObjectViewDelegate {
    func objectView(_ view: ARObjectView, made focusNode: FocusNode)

    func objectView(_ view: ARObjectView, made coachingOverlayView: ARCoachingOverlayView)

    func objectView(_ view: ARObjectView, made statusView: ARStatusView)

    func objectView(_ view: ARObjectView, made objectInteractor: ARObjectInteractor)
}

private extension ARObjectView {
    func removeFocusNode(focusNode: FocusNode?) {
        if let focusNode = focusNode {
            focusNode.removeFromParentNode()
            if manageFocusNode {
                focusNode.sceneView = nil
                focusNode.delegate = nil
            }
        }
    }
    
    func updateFocusNodeIfNeeded() {
#if TARGET_INTERFACE_BUILDER
        useFocusNodeIndicator.isOn = useFocusNode
#else
        if useFocusNode {
            if focusNode == nil {
                let focusIndicatorNode = self.FocusIndicatorType.init()
                let focusNode = FocusNode(content: focusIndicatorNode)
                self.focusNode = focusNode
                manageFocusNode = true
                if let arObjectViewDelegate = delegate as? ARObjectViewDelegate {
                    arObjectViewDelegate.objectView(self, made: focusNode)
                }
            }
            if let focusNode = focusNode {
                if manageFocusNode {
                    focusNode.sceneView = self
                    focusNode.updateQueue = updateQueue
                    if let focusNodeDelegate = delegate as? FocusNodeDelegate {
                        focusNode.delegate = focusNodeDelegate
                    }
                }
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
                manageCoachingOverlayView = true
                if let arObjectViewDelegate = delegate as? ARObjectViewDelegate {
                    arObjectViewDelegate.objectView(self, made: coachingOverlayView)
                }
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
                if let arObjectViewDelegate = delegate as? ARObjectViewDelegate {
                    arObjectViewDelegate.objectView(self, made: statusView)
                }
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
                if let arObjectViewDelegate = delegate as? ARObjectViewDelegate {
                    arObjectViewDelegate.objectView(self, made: objectInteractor)
                }
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
        self.dependentObjectsNeedUpdate = true
#endif
        // Dispatching the creation of objects gives the opportunity to configure the
        // view before creating objects that may not be needed
        DispatchQueue.main.async {
            self.updateFocusNodeIfNeeded()
            self.updateCoachingOverlayViewIfNeeded()
            self.updateStatusViewIfNeeded()
            self.updateObjectInteractorIfNeeded()
            self.dependentObjectsNeedUpdate = true
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

    // MARK: - Instance variables
    /// Set to true to see the focus node
    private var manageFocusNode: Bool = false
    private var manageCoachingOverlayView: Bool = false
    private var manageObjectInteractor: Bool = false
    private var manageStatusView: Bool = false
    private var dependentObjectsNeedUpdate: Bool = false

    @IBInspectable
    open var useFocusNode: Bool = true {
        didSet {
            guard useFocusNode != oldValue, dependentObjectsNeedUpdate else { return }
            updateFocusNodeIfNeeded()
        }
    }

    /// Set to true to see the coaching overlay view
    @IBInspectable
    open var useCoachingOverlayView: Bool = true {
        didSet {
            guard useCoachingOverlayView != oldValue, dependentObjectsNeedUpdate else { return }
            updateCoachingOverlayViewIfNeeded()
        }
    }

    @IBInspectable
    open var useObjectInteractor: Bool = true {
        didSet {
            guard useObjectInteractor != oldValue, dependentObjectsNeedUpdate else { return }
            updateObjectInteractorIfNeeded()
        }
    }

    @IBInspectable
    open var useStatusView: Bool = true {
        didSet {
            guard useStatusView != oldValue, dependentObjectsNeedUpdate else { return }
            updateStatusViewIfNeeded()
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
            if dependentObjectsNeedUpdate {
                updateDependentObjects()
            }
        }
    }

    public var FocusIndicatorType: FocusIndicatorNode.Type = FocusSquare.self

    public var updateQueue: DispatchQueue = DispatchQueue.global(qos: .userInitiated) {
        didSet {
            guard updateQueue !== oldValue else { return }
            self.session.delegateQueue = updateQueue
            if dependentObjectsNeedUpdate {
                updateDependentObjects()
            }
        }
    }
    
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
