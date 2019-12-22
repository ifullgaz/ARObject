//
//  ViewController.swift
//  ARObject
//
//  Created by Emmanuel Merali on 12/19/2019.
//  Copyright (c) 2019 Emmanuel Merali. All rights reserved.
//

import UIKit
import ARObject

class ViewController: ARObjectViewController {
    @IBAction func useFocusSquarteChanged(_ sender: UISwitch) {
        sceneView?.useFocusNode = sender.isOn
    }
    
    @IBAction func useCoachingViewChanged(_ sender: UISwitch) {
        sceneView?.useCoachingOverlayView = sender.isOn
    }
}

