//
//  TreDueMonostabileNC.swift
//  Pneumatica-SpriteKit-iOS
//
//  Created by Dani Tox on 15/04/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import SceneKit

class TreDueMonostabileNC: ValvolaConformance {
    enum ValvolaState {
        case aperta
        case chiusa
    }
    
    var id : UUID = UUID()
    
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
    var inputLeft: InputOutput!
    var mainOutput: InputOutput!
    
    var objectNode: SCNNode
    var labelNode: SCNNode?
    
    required init?() {
        guard let scene = SCNScene(named: sceneName) else { return nil }
        guard let node = scene.rootNode.childNode(withName: "3/2 MS", recursively: true) else { return nil }
        
        self.objectNode = node
        
        let leftInNode = self.objectNode.childNode(withName: "inputLeft", recursively: true)!
        self.inputLeft = InputOutput(node: leftInNode, valvola: self)
        
        let inAriaNode = self.objectNode.childNode(withName: "inputAria", recursively: true)!
        self.inputAria = InputOutput(node: inAriaNode, valvola: self)
        
        let outNode = self.objectNode.childNode(withName: "mainOutput", recursively: true)!
        self.mainOutput = InputOutput(node: outNode, valvola: self)
        
        inputLeft.idNumber = 0
        inputAria.idNumber = 1
        mainOutput.idNumber = 2
        
        self.labelNode = self.objectNode.childNode(withName: "label", recursively: true)
    }
    
    func update() {
        if self.inputLeft.ariaPressure > 0 {
            self.state = .aperta
        } else {
            self.state = .chiusa
        }
    }
    
}
