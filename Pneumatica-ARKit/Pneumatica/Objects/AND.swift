//
//  Objects.swift
//  Pneumatica
//
//  Created by Dani Tox on 02/04/2019.
//

import SceneKit

class ValvolaAnd : ValvolaConformance {
    var id : UUID = UUID()
    
    var inputLeft : InputOutput!
    var inputRight: InputOutput!
    var mainOutput: InputOutput!
    
    var objectNode: SCNNode
    var labelNode: SCNNode?
    
    required init?() {
        guard let scene = SCNScene(named: sceneName) else { return nil }
        guard let node = scene.rootNode.childNode(withName: "and", recursively: true) else { return nil }
        
        self.objectNode = node
        
        let inLeftNode = self.objectNode.childNode(withName: "inputLeft", recursively: true)!
        self.inputLeft = InputOutput(node: inLeftNode, valvola: self)
        
        let inRightNode = self.objectNode.childNode(withName: "inputRight", recursively: true)!
        self.inputRight = InputOutput(node: inRightNode, valvola: self)
        
        let outNode = self.objectNode.childNode(withName: "mainOutput", recursively: true)!
        self.mainOutput = InputOutput(node: outNode, valvola: self)
        
        inputLeft.idNumber = 0
        inputRight.idNumber = 1
        mainOutput.idNumber = 2
        
        let label = self.objectNode.childNode(withName: "label", recursively: true)!
        self.labelNode = label
    }
    
    func update() {
        if self.inputLeft.ariaPressure > 0 && self.inputRight.ariaPressure > 0 {
            mainOutput.ariaPressure = [inputLeft.ariaPressure, inputRight.ariaPressure].max() ?? 0.0
        } else {
            mainOutput.ariaPressure = 0.0
        }
    }
    
}
