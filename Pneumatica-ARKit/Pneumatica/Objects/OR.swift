//
//  OR.swift
//  Pneumatica-SpriteKit-iOS
//
//  Created by Dani Tox on 15/04/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import SceneKit

class ValvolaOR : ValvolaConformance {
    var id : UUID = UUID()
    
    var inputLeft : InputOutput!
    var inputRight: InputOutput!
    var mainOutput: InputOutput!

    var objectNode: SCNNode
    var labelNode: SCNNode?
    
    required init?() {
        guard let scene = SCNScene(named: sceneName) else { return nil }
        guard let node = scene.rootNode.childNode(withName: "or", recursively: true) else { return nil }
        
        self.objectNode = node
        
        let leftNode = self.objectNode.childNode(withName: "inputLeft", recursively: true)!
        self.inputLeft = InputOutput(node: leftNode, valvola: self)
        
        let rightNode = self.objectNode.childNode(withName: "inputRight", recursively: true)!
        self.inputRight = InputOutput(node: rightNode, valvola: self)
        
        let outNode = self.objectNode.childNode(withName: "mainOutput", recursively: true)!
        self.mainOutput = InputOutput(node: outNode, valvola: self)
        
        inputLeft.idNumber = 0
        inputRight.idNumber = 1
        mainOutput.idNumber = 2
        
        let label = self.objectNode.childNode(withName: "label", recursively: true)!
        self.labelNode = label
    }
    
    func update() {
        if inputLeft.ariaPressure > 0 || inputRight.ariaPressure > 0 {
            mainOutput.ariaPressure = [inputLeft.ariaPressure, inputRight.ariaPressure].max() ?? 0.0
        } else {
            mainOutput.ariaPressure = 0.0
        }
    }
}
