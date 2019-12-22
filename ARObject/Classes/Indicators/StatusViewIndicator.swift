//
//  statusViewIndicator.swift
//  ARObject
//
//  Created by Emmanuel Merali on 22/12/2019.
//

import UIKit

extension StatusViewIndicator {
    func setup() {
        self.backgroundColor = UIColor.clear
        label = UILabel(frame: CGRect(x: 20, y: 3, width: 100, height: 14))
        label!.text = "Status"
        label!.font = UIFont.systemFont(ofSize: 12, weight: .light)
        self.addSubview(label!)
    }
}

class StatusViewIndicator: UIView {
    var label: UILabel?
    
    func bexierPath() -> UIBezierPath {
        let path = UIBezierPath()
        path.addArc(withCenter: CGPoint(x: 10, y: 10), radius: 8, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
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
        let textColor = isOn ? UIColor.darkGray : UIColor.lightGray
        label!.textColor = textColor
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
