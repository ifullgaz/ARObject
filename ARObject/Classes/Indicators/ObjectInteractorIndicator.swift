//
//  ObjectInteractionIndicator.swift
//  ARObject
//
//  Created by Emmanuel Merali on 24/12/2019.
//

import UIKit

extension ObjectInteractorIndicator {
    func setup() {
        self.backgroundColor = UIColor.clear
    }
}

class ObjectInteractorIndicator: UIView {
    func bexierPath() -> UIBezierPath {
        let path = UIBezierPath()
        path.addArc(withCenter: CGPoint(x: 10, y: 10), radius: 9, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        path.addArc(withCenter: CGPoint(x: 10, y: 10), radius: 6, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        path.addArc(withCenter: CGPoint(x: 10, y: 10), radius: 3, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        return path
    }
    
    override public func draw(_ rect: CGRect) {
        let path = bexierPath()
        path.lineWidth = 1.0
        let strokeColor = isOn ? UIColor.green : UIColor.lightGray
        strokeColor.setStroke()
        path.stroke()
    }

    public var isOn: Bool = false
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
}
