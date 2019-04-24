//
//  GruppooFRL.swift
//  Pneumatica-SpriteKit-iOS
//
//  Created by Dani Tox on 15/04/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import SceneKit

class GruppoFRL: ValvolaConformance {
    var id: UUID = UUID()
    
    var isActive : Bool = true
    var onlyOutput : InputOutput!
    
    var labelNode: SCNNode?
    var objectNode: SCNNode

    required init?() {
        guard let scene = SCNScene(named: sceneName) else { return nil }
        guard let node = scene.rootNode.childNode(withName: "frl", recursively: true) else { return nil }
        
        self.objectNode = node
        
        let outNode = self.objectNode.childNode(withName: "mainOut", recursively: true)!
        self.onlyOutput = InputOutput(node: outNode, valvola: self)
        onlyOutput.idNumber = 0
        onlyOutput.isPressureMandatory = true
        
        self.labelNode = self.objectNode.childNode(withName: "label", recursively: true)!
        
    }
    
    func update() {
        onlyOutput.ariaPressure = 2.0
    }
    
}
