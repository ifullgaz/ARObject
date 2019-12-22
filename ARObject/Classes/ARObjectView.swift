//
//  ARObjectView.swift
//  ARObject
//
//  Created by Emmanuel Merali on 18/12/2019.
//  Copyright © 2019 Test. All rights reserved.
//

import ARKit
import ARFocusSquare

public protocol ARObjectViewDelegate: ARSCNViewDelegate, FocusNodeDelegate, ARCoachingOverlayViewDelegate {}

public extension ARObjectView {
    func createFocusNodeIfNeeded() {
#if TARGET_INTERFACE_BUILDER
        useFocusNodeIndicator.isOn = useFocusNode
#else
        if useFocusNode {
            if focusNode == nil {
                let focusNode = type(of: self).focusNodeType.init()
                self.focusNode = focusNode
                focusNode.sceneView = self
                if let focusNodeDelegate = delegate as? FocusNodeDelegate {
                    focusNode.delegate = focusNodeDelegate
                }
            }
        }
        else {
            focusNode = nil
        }
#endif
    }
    
    func createCoachingOverlayViewIfNeeded() {
#if TARGET_INTERFACE_BUILDER
        useCoachingOverlayViewindicator.isOn = useCoachingOverlayView
#else
        if useCoachingOverlayView {
            if coachingOverlayView == nil {
                let coachingOverlayView = ARCoachingOverlayView()
                self.coachingOverlayView = coachingOverlayView
                coachingOverlayView.sessionProvider = self
                if let coachingOverlayViewDelegate = delegate as? ARCoachingOverlayViewDelegate {
                    coachingOverlayView.delegate = coachingOverlayViewDelegate
                }
            }
        }
        else {
            coachingOverlayView = nil
        }
#endif
    }

    func createStatusViewIfNeeded() {
#if TARGET_INTERFACE_BUILDER
        useStatusViewIndicator.isOn = useStatusView
#else
#endif
    }

    func createDependentObjects() {
        DispatchQueue.main.async {
            self.createFocusNodeIfNeeded()
            self.createCoachingOverlayViewIfNeeded()
            self.createStatusViewIfNeeded()
        }
#if TARGET_INTERFACE_BUILDER
        self.addSubview(useFocusNodeIndicator)
        self.addSubview(useCoachingOverlayViewindicator)
        self.addSubview(useStatusViewIndicator)
        self.useFocusNodeIndicator.isOn = useFocusNode
        self.useCoachingOverlayViewindicator.isOn = useCoachingOverlayView
        self.useStatusViewIndicator.isOn = useStatusView
#endif
    }
}

@IBDesignable
open class ARObjectView: ARSCNView {

    // MARK: - IB Support
    #if TARGET_INTERFACE_BUILDER
    var useFocusNodeIndicator: FocusNodeIndicator = FocusNodeIndicator(frame: CGRect(x: 5, y: 50, width: 20, height: 20))
    var useCoachingOverlayViewindicator: CoachingOverlayViewIndicator = CoachingOverlayViewIndicator(frame: CGRect(x: 40, y: 50, width: 20, height: 20))
    var useStatusViewIndicator: StatusViewIndicator = StatusViewIndicator(frame: CGRect(x: 75, y: 50, width: 150, height: 20))
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
    @IBInspectable
    open var useFocusNode: Bool = true {
        didSet {
            createFocusNodeIfNeeded()
        }
    }

    /// Set to true to see the coaching overlay view
    @IBInspectable
    open var useCoachingOverlayView: Bool = true {
        didSet {
            createCoachingOverlayViewIfNeeded()
        }
    }

    @IBInspectable
    open var useStatusView: Bool = true {
        didSet {
            createStatusViewIfNeeded()
        }
    }

    @IBOutlet
    public var focusNode: FocusNode? = nil {
        didSet {
            guard focusNode !== oldValue else { return }
            oldValue?.removeFromParentNode()
            if let focusNode = focusNode {
                self.scene.rootNode.addChildNode(focusNode)
            }
        }
    }

    @IBOutlet
    public var coachingOverlayView: ARCoachingOverlayView? = nil {
        didSet {
            guard coachingOverlayView !== oldValue else { return }
            oldValue?.removeFromSuperview()
            if let coachingOverlayView = coachingOverlayView {
                coachingOverlayView.translatesAutoresizingMaskIntoConstraints = false
                self.addSubview(coachingOverlayView)
                NSLayoutConstraint.activate([
                    coachingOverlayView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                    coachingOverlayView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                    coachingOverlayView.widthAnchor.constraint(equalTo: self.widthAnchor),
                    coachingOverlayView.heightAnchor.constraint(equalTo: self.heightAnchor)
                    ])
            }
        }
    }

    open override var delegate: ARSCNViewDelegate? {
        didSet {
            if let focusNodeDelegate = delegate as? FocusNodeDelegate {
                focusNode?.delegate = focusNodeDelegate
            }
            if let coachingOverlayViewDelegate = delegate as? ARCoachingOverlayViewDelegate {
                coachingOverlayView?.delegate = coachingOverlayViewDelegate
            }
        }
    }
    
    // MARK: - Initialization
    override public init(frame: CGRect, options: [String : Any]? = nil) {
        super.init(frame: frame, options: options)
        createDependentObjects()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        createDependentObjects()
    }
}
