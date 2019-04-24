//
//  InputOutput.swift
//  Pneumatica-SpriteKit-iOS
//
//  Created by Dani Tox on 15/04/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import SceneKit

class InputOutput: IOConformance, Hashable {
    static func == (lhs: InputOutput, rhs: InputOutput) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(self.ioNode)
    }
    
    var id : UUID = UUID()
    var parentValvola : ValvolaConformance
    var idleColor: UIColor = .red
    
    var inputsConnected : Set<InputOutput> = []
    
    var ariaPressure : Double = 0.0 {
        didSet {
            DispatchQueue.main.async {
                if self.ariaPressure == 0 {
                    self.ioNode.geometry?.firstMaterial?.diffuse.contents = self.idleColor
                } else {
                    self.ioNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                }
            }
        }
    }
    
    var idNumber: Int = -1
    var ioNode: SCNNode
    
    var isPressureMandatory : Bool = false
    
    init(node: SCNNode, valvola: ValvolaConformance){
        self.parentValvola = valvola
        self.ioNode = node
        
        //da rimuovere
//        self.ioNode.geometry?.firstMaterial?.transparency = 0.3
    }
    
    func update() {
        if isPressureMandatory { return }
        if inputsConnected.isEmpty {
            self.ariaPressure = 0
            return
        }
        
        if let mostPowerInput = self.getMostHightInput() {
            self.ariaPressure = mostPowerInput.ariaPressure
        } else {
            self.ariaPressure = 0
        }
    }
    
    func addWire(to io: InputOutput) {
        io.inputsConnected.insert(self)
        self.inputsConnected.insert(io)
    }
    
    func removeWire(_ wire: InputOutput) {
        self.inputsConnected.remove(wire)
        wire.inputsConnected.remove(self)
    }
    
    func getMostHightInput() -> InputOutput? {
        return self.inputsConnected.max(by: { $0.ariaPressure < $1.ariaPressure })
    }
}
