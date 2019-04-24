//
//  TreDueBistabile.swift
//  Pneumatica-SpriteKit-iOS
//
//  Created by Dani Tox on 18/04/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import SceneKit

class TreDueBistabile: ValvolaConformance {
    enum ValvolaState {
        case aperta
        case riposo
    }
    
    var id : UUID = UUID()
    
    var state : ValvolaState = .riposo {
        didSet {
            if state == .aperta {
                self.outputMain.ariaPressure = self.inputAria.getMostHightInput()?.ariaPressure ?? 0
            } else {
                self.outputMain.ariaPressure = 0
            }
        }
    }
    
    var inputAria : InputOutput!
    
    var inputLeft: InputOutput!
    var inputRight: InputOutput!
    
    var outputMain: InputOutput!
    
    var objectNode: SCNNode
    var labelNode: SCNNode?
    
    required init?() {
        guard let scene = SCNScene(named: sceneName) else { return nil }
        guard let node = scene.rootNode.childNode(withName: "3/2 BS", recursively: true) else { return nil }
        
        self.objectNode = node
        let inAriaNode = self.objectNode.childNode(withName: "inputAria", recursively: true)!
        self.inputAria = InputOutput(node: inAriaNode, valvola: self)
        
        let inLeftNode = self.objectNode.childNode(withName: "inputLeft", recursively: true)!
        self.inputLeft = InputOutput(node: inLeftNode, valvola: self)
        
        let inRightNode = self.objectNode.childNode(withName: "inputRight", recursively: true)!
        self.inputRight = InputOutput(node: inRightNode, valvola: self)
        
        let mainOutNode = self.objectNode.childNode(withName: "mainOutput", recursively: true)!
        self.outputMain = InputOutput(node: mainOutNode, valvola: self)
        
        
        inputAria.idNumber = 0
        inputLeft.idNumber = 1
        inputRight.idNumber = 2
        outputMain.idNumber = 3
        
        self.labelNode = self.objectNode.childNode(withName: "label", recursively: true)
        
    }
    
    func update() {
        if self.state == .riposo {
            if self.inputLeft.ariaPressure > 0 && self.inputRight.ariaPressure <= 0 {
                self.state = .aperta
            } else {
                self.state = .riposo
            }
        } else {
            if self.inputRight.ariaPressure > 0 && self.inputLeft.ariaPressure <= 0 {
                self.state = .riposo
            } else {
                self.state = .aperta
            }
        }
    }
    
}
