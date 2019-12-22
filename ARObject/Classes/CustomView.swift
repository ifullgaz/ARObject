//
//  CustomView.swift
//  ARFocusSquare
//
//  Created by Emmanuel Merali on 22/12/2019.
//

import UIKit
import IFGExtensions

extension CustomView {
    func showFocusSquareIndicator() {
#if TARGET_INTERFACE_BUILDER
        useFocusNodeIndicator.isOn = useFocusNode
#endif
    }

    func showCoachingOverlayViewIndicator() {
#if TARGET_INTERFACE_BUILDER
        useCoachingOverlayViewindicator.isOn = useCoachingOverlayView
#endif
    }
}


@IBDesignable
class CustomView: UIView, LoadableFromNib {

    @IBOutlet weak var contentView: UIView!

    @IBOutlet weak var squareView: UIView!

    @IBOutlet weak var button: UIButton!

    @IBInspectable
    var squareIsHidden: Bool {
        get { return squareView.isHidden }
        set { squareView.isHidden = newValue; self.setNeedsDisplay() }
    }

    @IBInspectable var cornerRadius: CGFloat = 2.0 {
        didSet {
            contentView.layer.cornerRadius = cornerRadius
            contentView.layer.masksToBounds = cornerRadius > 0
        }
    }

    @IBInspectable
    open var useFocusNode: Bool = true {
        didSet {
            showFocusSquareIndicator()
        }
    }

    @IBInspectable
    open var useCoachingOverlayView: Bool = true {
        didSet {
            showCoachingOverlayViewIndicator()
        }
    }

#if TARGET_INTERFACE_BUILDER
    var useFocusNodeIndicator: FocusNodeIndicator = FocusNodeIndicator(frame: CGRect(x: 2, y: 5, width: 20, height: 20))
    var useCoachingOverlayViewindicator: CoachingOverlayViewIndicator = CoachingOverlayViewIndicator(frame: CGRect(x: 2, y: 30, width: 20, height: 20))
#endif

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadFromNib()
#if TARGET_INTERFACE_BUILDER
        self.addSubview(useFocusNodeIndicator)
        useFocusNodeIndicator.isOn = useFocusNode
        self.addSubview(useCoachingOverlayViewindicator)
        useCoachingOverlayViewindicator.isOn = useCoachingOverlayView
#endif
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadFromNib()
#if TARGET_INTERFACE_BUILDER
        self.addSubview(useFocusNodeIndicator)
        useFocusNodeIndicator.isOn = useFocusNode
        self.addSubview(useCoachingOverlayViewindicator)
        useCoachingOverlayViewindicator.isOn = useCoachingOverlayView
#endif
    }
}
