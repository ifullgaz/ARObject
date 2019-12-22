//
//  CoachingOverlayViewIndicator.swift
//  ARObject
//
//  Created by Emmanuel Merali on 22/12/2019.
//

import UIKit

extension CoachingOverlayViewIndicator {
    func setup() {
        self.backgroundColor = UIColor.clear
    }
}

class CoachingOverlayViewIndicator: UIView {
    func bexierPath() -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 15))
        path.addLine(to: CGPoint(x: 5, y: 5))
        path.addLine(to: CGPoint(x: 15, y: 5))
        path.addLine(to: CGPoint(x: 20, y: 15))
        path.close()
        return path
    }
    
    override public func draw(_ rect: CGRect) {
        let path = bexierPath()
        path.lineWidth = 1.0
        let strokeColor = isOn ? UIColor.green : UIColor.lightGray
        let fillColor = isOn ? UIColor.green.withAlphaComponent(0.7) : UIColor.lightGray.withAlphaComponent(0.7)
        strokeColor.setStroke()
        fillColor.setFill()
        path.stroke()
        path.fill()
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
