//
//  CinqueDueMonostabili.swift
//  Pneumatica-SpriteKit-iOS
//
//  Created by Dani Tox on 18/04/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import SceneKit

class CinqueDueMonostabile: ValvolaConformance {
    enum ValvolaState {
        case aperta
        case riposo
    }
    
    var id : UUID = UUID()
    
    var state : ValvolaState = .riposo {
        didSet {
            if state == .aperta {
                self.outputLeft.ariaPressure = self.inputAria.getMostHightInput()?.ariaPressure ?? 0
                self.outputRight.ariaPressure = 0
            } else {
                self.outputRight.ariaPressure = self.inputAria.getMostHightInput()?.ariaPressure ?? 0
                self.outputLeft.ariaPressure = 0
            }
        }
    }
    
    var inputAria : InputOutput!
    
    var inputLeft: InputOutput!
    
    var outputLeft: InputOutput!
    var outputRight: InputOutput!
    
    var objectNode: SCNNode
    var labelNode: SCNNode?
    
    required init?() {
        guard let scene = SCNScene(named: sceneName) else { return nil }
        guard let node = scene.rootNode.childNode(withName: "5/2 MS", recursively: true) else { return nil }
        
        self.objectNode = node
        
        let inAriaNode = self.objectNode.childNode(withName: "inputAria", recursively: true)!
        self.inputAria = InputOutput(node: inAriaNode, valvola: self)
        
        let inLeftNode = self.objectNode.childNode(withName: "inputLeft", recursively: true)!
        self.inputLeft = InputOutput(node: inLeftNode, valvola: self)
        
        let outLeftNode = self.objectNode.childNode(withName: "outputLeft", recursively: true)!
        self.outputLeft = InputOutput(node: outLeftNode, valvola: self)
        
        let outRightNode = self.objectNode.childNode(withName: "outputRight", recursively: true)!
        self.outputRight = InputOutput(node: outRightNode, valvola: self)
        
        inputAria.idNumber = 0
        inputLeft.idNumber = 1
        outputLeft.idNumber = 2
        outputRight.idNumber = 3
        
        self.labelNode = self.objectNode.childNode(withName: "label", recursively: true)
    }
    
    func update() {
        if self.state == .riposo {
            if self.inputLeft.ariaPressure > 0 {
                self.state = .aperta
            } else {
                self.state = .riposo
            }
        } else {
            if self.inputLeft.ariaPressure <= 0 {
                self.state = .riposo
            } else {
                self.state = .aperta
            }
        }
    }
    
    var objectType: ObjectType {
        return .cinqueDueMS
    }
}
