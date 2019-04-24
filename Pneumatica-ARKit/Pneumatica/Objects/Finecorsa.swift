//
//  Finecorsa.swift
//  Pneumatica-SpriteKit-iOS
//
//  Created by Dani Tox on 15/04/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import SceneKit

class Finecorsa: ValvolaConformance, AcceptsMovableInput, Editable {
    enum ValvolaState {
        case aperta
        case chiusa
    }
    
    var id : UUID = UUID()
    
    var listenValue: Float = 0
    
    var state : ValvolaState = .chiusa {
        didSet {
            switch state {
            case .chiusa:
                self.mainOutput.ariaPressure = 0
            case .aperta:
                self.mainOutput.ariaPressure = self.inputAria.getMostHightInput()?.ariaPressure ?? 0
            }
        }
    }
    
    var inputAria : InputOutput!
    var movableInput: Movable?
    var mainOutput: InputOutput!
    
    var objectNode: SCNNode
    var labelNode: SCNNode?
    
    required init?() {
        guard let scene = SCNScene(named: sceneName) else { return nil }
        guard let node = scene.rootNode.childNode(withName: "finecorsa", recursively: true) else { return nil }
        
        self.objectNode = node
        let inAriaNode = self.objectNode.childNode(withName: "inputAria", recursively: true)!
        self.inputAria = InputOutput(node: inAriaNode, valvola: self)
        
        let mainOutNode = self.objectNode.childNode(withName: "mainOutput", recursively: true)!
        self.mainOutput = InputOutput(node: mainOutNode, valvola: self)
        
        inputAria.idNumber = 0
        mainOutput.idNumber = 1
        
        self.labelNode = self.objectNode.childNode(withName: "label", recursively: true)
    }
    
    func update() {
        guard let movableInput = self.movableInput else {
            self.state = .chiusa
            return
        }
        var movingPoint = movableInput.movingPointValue
        if movingPoint < 0 { movingPoint = 0 }
        if movingPoint > 1 { movingPoint = 1 }
        let roundedValue = roundf(Float(10.0 * movingPoint)) / 10.0
        
        
        if roundedValue == listenValue {
            self.state = .aperta
        } else {
            self.state = .chiusa
        }
    }
    
}

