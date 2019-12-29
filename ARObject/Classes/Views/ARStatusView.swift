//
//  ARViewStatus.swift
//  TestBlurViewRotation
//
//  Created by Emmanuel Merali on 29/12/2019.
//  Copyright © 2019 Test. All rights reserved.
//

import ARKit

public extension ARCamera.TrackingState {
    var recommendation: String? {
        switch self {
        case .limited(.excessiveMotion):
            return "Try slowing down your movement, or reset the session."
        case .limited(.insufficientFeatures):
            return "Try pointing at a flat surface, or reset the session."
        case .limited(.relocalizing):
            return "Return to the location where you left off or try resetting the session."
        default:
            return nil
        }
    }
}

public typealias ARStatusDisplayerRestartBlock = (_ sender: Any?) -> Void

@objc
public protocol ARStatusDisplayer where Self: UIView {
    
    func updateWorldMappingStatus(_ status: ARFrame.WorldMappingStatus)
    
    func setRestartBock(block: ARStatusDisplayerRestartBlock?)
    
    func present(message: String)

    func dismiss()

    func schedule(message: String, in delay: TimeInterval, type: String)

    func cancelScheduledMessage(type: String)

    func cancelAllScheduledMessages()
}

@IBDesignable
open class ARStatusView: UIView, ARStatusDisplayer {
    
    // MARK: - Public constants
    public static var perpectiveCoefficient: CGFloat = 1 / 500

    public static var animationDuration: TimeInterval = 0.25

    public static var displayDuration: TimeInterval = 5.0

    // MARK: - Private instance variables
    private var worldMappingStatusView: UIView = UIView()
    
    private var statusLabel: UIView = UIView()
    
    private var restartButton: UIButton = UIButton(type: .custom)
    
    private var labelTop: UILabel!

    private var labelBottom: UILabel!

    private var blurViewTop: UIVisualEffectView!
    
    private var blurViewBottom: UIVisualEffectView!
    
    private var layerTransformTop: CATransform3D!

    private var layerTransformBottom: CATransform3D!

    private var autoHideTimer: Timer?

    private var scheduleTimers: [String: Timer] = [:]

    private var isAnimating: Bool = false

    private var restartBlock: ARStatusDisplayerRestartBlock? = nil
    
    // MARK: - Public instance variables
    private(set) var isFlipped: Bool = false {
        didSet {
            self.flip()
        }
    }
    
    @IBInspectable
    public var text: String? {
        get {
            return labelTop.text
        }
        set {
            labelTop.text = newValue
            labelTop.sizeToFit()
            labelBottom.text = newValue
            labelBottom.sizeToFit()
        }
    }

    @IBInspectable
    public var font: UIFont! {
        get {
            return labelTop.font
        }
        set {
            labelTop.font = newValue
            labelTop.sizeToFit()
            labelBottom.font = newValue
            labelBottom.sizeToFit()
        }
    }
        
    @IBInspectable
    public var textAlignment: NSTextAlignment {
        get {
            return labelTop.textAlignment
        }
        set {
            labelTop.textAlignment = newValue
            labelTop.sizeToFit()
            labelBottom.textAlignment = newValue
            labelBottom.sizeToFit()
        }
    }
        
    @IBInspectable
    public var numberOfLines: Int {
        get {
            return labelTop.numberOfLines
        }
        set {
            labelTop.numberOfLines = newValue
            labelTop.sizeToFit()
            labelBottom.numberOfLines = newValue
            labelBottom.sizeToFit()
        }
    }
    
    public var worldMappingStatus: ARFrame.WorldMappingStatus = .notAvailable {
        didSet {
            guard worldMappingStatus != oldValue else { return }
            DispatchQueue.main.async {
                switch self.worldMappingStatus {
                    case .notAvailable:
                        self.worldMappingStatusView.backgroundColor = UIColor.red
                    case .limited:
                        self.worldMappingStatusView.backgroundColor = UIColor.yellow
                    case .extending:
                        self.worldMappingStatusView.backgroundColor = UIColor.orange
                    case .mapped:
                        self.worldMappingStatusView.backgroundColor = UIColor.green
                    default:
                        self.worldMappingStatusView.backgroundColor = UIColor.purple
                }
                self.present(message: "Mapping \(self.worldMappingStatus)")
            }
        }
    }

    // MARK: - Private methods
    private func setInitialTransforms() {
        layerTransformTop = CATransform3DIdentity
        layerTransformBottom = CATransform3DIdentity
        if isFlipped {
            layerTransformTop.m34 = ARStatusView.perpectiveCoefficient
            layerTransformTop = CATransform3DRotate(layerTransformTop, .pi / 2, 1.0, 0.0, 0.0)
            layerTransformBottom.m34 = -ARStatusView.perpectiveCoefficient
            layerTransformBottom = CATransform3DRotate(layerTransformBottom, -.pi / 2, 1.0, 0.0, 0.0)
        }
        else {
            layerTransformTop.m34 = -ARStatusView.perpectiveCoefficient
            layerTransformBottom.m34 = ARStatusView.perpectiveCoefficient
        }
    }
    
    private func setFinalTransforms() {
        layerTransformTop = CATransform3DIdentity
        layerTransformBottom = CATransform3DIdentity
        if isFlipped {
            layerTransformTop.m34 = ARStatusView.perpectiveCoefficient
            layerTransformBottom.m34 = -ARStatusView.perpectiveCoefficient
        }
        else {
            layerTransformTop.m34 = -ARStatusView.perpectiveCoefficient
            layerTransformTop = CATransform3DRotate(layerTransformTop, .pi / 2, 1.0, 0.0, 0.0)
            layerTransformBottom.m34 = ARStatusView.perpectiveCoefficient
            layerTransformBottom = CATransform3DRotate(layerTransformBottom, -.pi / 2, 1.0, 0.0, 0.0)
        }
    }
    
    private func createSubViewHierarchy(containerView: UIView, isTop: Bool) -> UILabel {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        containerView.addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            view.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            view.heightAnchor.constraint(equalTo: containerView.heightAnchor)
        ])

        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView()
        blurView.effect = blurEffect
        view.addSubview(blurView)
        if isTop {
            blurViewTop = blurView
        }
        else {
            blurViewBottom = blurView
        }

        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.translatesAutoresizingMaskIntoConstraints = true
        NSLayoutConstraint.activate([
            blurView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            blurView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            blurView.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            blurView.heightAnchor.constraint(equalTo: containerView.heightAnchor)
        ])
        
        let vibrancyView = UIVisualEffectView()
        vibrancyView.effect = UIVibrancyEffect(blurEffect: blurEffect, style: .fill)
        blurView.contentView.addSubview(vibrancyView)

        vibrancyView.translatesAutoresizingMaskIntoConstraints = false
        vibrancyView.contentView.translatesAutoresizingMaskIntoConstraints = true
        NSLayoutConstraint.activate([
            vibrancyView.centerXAnchor.constraint(equalTo: blurView.contentView.centerXAnchor),
            vibrancyView.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            vibrancyView.widthAnchor.constraint(equalTo: blurView.contentView.widthAnchor),
            vibrancyView.heightAnchor.constraint(equalTo: blurView.contentView.heightAnchor)
        ])

        let label = UILabel()
        label.numberOfLines = 3
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = false
        vibrancyView.contentView.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: vibrancyView.contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: vibrancyView.contentView.centerYAnchor),
            label.widthAnchor.constraint(equalTo: vibrancyView.contentView.widthAnchor, constant: -16),
            label.heightAnchor.constraint(equalTo: vibrancyView.contentView.heightAnchor, constant: -8),
            label.widthAnchor.constraint(lessThanOrEqualTo: containerView.widthAnchor),
        ])
        
        return label
    }
    
    private func createViewHiearchy() {
        self.backgroundColor = UIColor.clear

        worldMappingStatusView.layer.cornerRadius = 15
        worldMappingStatusView.layer.masksToBounds = true
        self.addSubview(worldMappingStatusView)
        
        worldMappingStatusView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            worldMappingStatusView.widthAnchor.constraint(equalToConstant: 30),
            worldMappingStatusView.heightAnchor.constraint(equalToConstant: 30),
            worldMappingStatusView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8),
            worldMappingStatusView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        
#if TARGET_INTERFACE_BUILDER
        // Somehow IB doesn't like images in buttons...
        restartButton.setTitle("O", for: .normal)
#else
        let bundle = Bundle(for: ARStatusView.classForCoder())
        let buttonImage = UIImage(named: "restart", in: bundle, compatibleWith: nil)
        restartButton.setImage(buttonImage, for: .normal)
        restartButton.setTitle("", for: .normal)
        restartButton.adjustsImageWhenHighlighted = true
        restartButton.adjustsImageWhenDisabled = true
        restartButton.addTarget(self, action: #selector(ARStatusView.restart(sender:)), for: .touchUpInside)
#endif
        self.labelTop = createSubViewHierarchy(containerView: statusLabel, isTop: true)
        self.labelBottom = createSubViewHierarchy(containerView: statusLabel, isTop: false)
        setInitialTransforms()
        self.blurViewTop.layer.transform = self.layerTransformTop
        self.blurViewBottom.layer.transform = self.layerTransformBottom
        statusLabel.layer.cornerRadius = 8
        statusLabel.layer.masksToBounds = true
        self.addSubview(statusLabel)
        
        self.addSubview(restartButton)
        
        restartButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            restartButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8),
            restartButton.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusLabel.leftAnchor.constraint(equalTo: worldMappingStatusView.rightAnchor, constant: 8),
            statusLabel.rightAnchor.constraint(lessThanOrEqualTo: restartButton.leftAnchor, constant: -8),
            statusLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        ])
        flip()
    }

    private func flip(completion block: (() -> Void)? = nil) {
        guard !isAnimating else { return }
        isAnimating = true
        setFinalTransforms()
        UIView.animate(
            withDuration: ARStatusView.animationDuration,
            animations: {
                self.blurViewTop.layer.transform = self.layerTransformTop;
                self.blurViewBottom.layer.transform = self.layerTransformBottom;
            }) { (finished) in
                self.isFlipped = !self.isFlipped
                self.setInitialTransforms()
                self.blurViewTop.layer.transform = self.layerTransformTop;
                self.blurViewBottom.layer.transform = self.layerTransformBottom;
                self.isAnimating = false
                if let block = block {
                    block()
                }
            }
    }

    // MARK: - Restart button handler
    @objc
    private func restart(sender: Any?) {
        if let restartBlock = restartBlock {
            restartBlock(self)
        }
    }

    // MARK: - Public interface
    public func setRestartBock(block: ARStatusDisplayerRestartBlock?) {
        restartBlock = block
    }

    public func present(message: String) {
        if !isFlipped {
            flip() {
                self.present(message: message)
            }
        }
        else {
            if let autoHideTimer = autoHideTimer {
                autoHideTimer.invalidate()
            }
            autoHideTimer = Timer.scheduledTimer(
                withTimeInterval: ARStatusView.displayDuration,
                repeats: false,
                block: { [weak self] _ in
                    self?.flip()
                    self?.autoHideTimer = nil
            })
            self.text = message
            flip()
        }
    }

    public func dismiss() {
        if !isFlipped {
            flip()
        }
    }
    
    public func schedule(message: String, in delay: TimeInterval, type: String) {
        cancelScheduledMessage(type: type)

        let timer = Timer.scheduledTimer(
            withTimeInterval: delay,
            repeats: false,
            block: { [weak self] timer in
                self?.present(message: message)
                timer.invalidate()
        })

        scheduleTimers[type] = timer
    }
    
    public func cancelScheduledMessage(type: String) {
        scheduleTimers[type]?.invalidate()
        scheduleTimers[type] = nil
    }
    
    public func cancelAllScheduledMessages() {
        for (type, _) in scheduleTimers {
            cancelScheduledMessage(type: type)
        }
    }

    public func updateWorldMappingStatus(_ status: ARFrame.WorldMappingStatus) {
        worldMappingStatus = status
    }

    // MARK: - Initialisation
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.createViewHiearchy()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.createViewHiearchy()
    }
}
