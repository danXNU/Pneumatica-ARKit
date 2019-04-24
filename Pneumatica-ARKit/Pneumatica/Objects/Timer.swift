//
//  Timer.swift
//  Pneumatica-SpriteKit-iOS
//
//  Created by Dani Tox on 15/04/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import SceneKit

class TimerObject: ValvolaConformance {
    enum TimerState {
        case isAlreadyFired
        case counting
        case isAbleToFire
    }
    
    var id : UUID = UUID()
    
    var state : TimerState = .isAbleToFire
    var timerObject : Timer?
    var duration: TimeInterval = 3
    
    var inputAria: InputOutput!
    var mainOutput: InputOutput!
    
    var objectNode: SCNNode
    var labelNode: SCNNode?
    
    required init?() {
        guard let scene = SCNScene(named: sceneName) else { return nil }
        guard let node = scene.rootNode.childNode(withName: "timer", recursively: true) else { return nil }
        
        self.objectNode = node
        
        let inNode = self.objectNode.childNode(withName: "mainInput", recursively: true)!
        self.inputAria = InputOutput(node: inNode, valvola: self)
        
        let outNode = self.objectNode.childNode(withName: "mainOutput", recursively: true)!
        self.mainOutput = InputOutput(node: outNode, valvola: self)
        
        inputAria.idNumber  = 0
        mainOutput.idNumber = 1
        
        let labelNode = self.objectNode.childNode(withName: "label", recursively: true)!
        self.labelNode = labelNode
        
    }

    
    func update() {
        if self.inputAria.ariaPressure > 0 {
            if self.state == .isAbleToFire {
                startTimer()
            } else if self.state == .isAlreadyFired {
                self.mainOutput.ariaPressure = self.inputAria.getMostHightInput()?.ariaPressure ?? 0
            }
        } else if inputAria.ariaPressure <= 0 {
            self.mainOutput.ariaPressure = 0
            self.timerObject?.invalidate()
            self.state = .isAbleToFire
        }
    }
    
    func startTimer() {
        self.state = .counting
        self.timerObject = Timer.scheduledTimer(withTimeInterval: self.duration, repeats: false, block: { (timer) in
            if self.state == .counting {
                self.mainOutput.ariaPressure = self.inputAria.getMostHightInput()?.ariaPressure ?? 0
                self.state = .isAlreadyFired
            }
        })
    }

}
