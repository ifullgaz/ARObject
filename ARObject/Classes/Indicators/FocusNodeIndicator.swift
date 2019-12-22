//
//  FocusNodeIndicator.swift
//  ARFocusSquare
//
//  Created by Emmanuel Merali on 22/12/2019.
//

import UIKit

extension FocusNodeIndicator {
    func setup() {
        self.backgroundColor = UIColor.clear
    }
}

public class FocusNodeIndicator: UIView {
    func bexierPath() -> UIBezierPath {
        let path = UIBezierPath()
        // Top left
        path.move(to: CGPoint(x: 8, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 8))

        // Top right
        path.move(to: CGPoint(x: 12, y: 0))
        path.addLine(to: CGPoint(x: 20, y: 0))
        path.addLine(to: CGPoint(x: 20, y: 8))

        // Bottom left
        path.move(to: CGPoint(x: 8, y: 20))
        path.addLine(to: CGPoint(x: 0, y: 20))
        path.addLine(to: CGPoint(x: 0, y: 12))

        // Bottom right
        path.move(to: CGPoint(x: 12, y: 20))
        path.addLine(to: CGPoint(x: 20, y: 20))
        path.addLine(to: CGPoint(x: 20, y: 12))

        return path
    }
    
    override public func draw(_ rect: CGRect) {
        let path = bexierPath()
        path.lineWidth = 2.0
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
