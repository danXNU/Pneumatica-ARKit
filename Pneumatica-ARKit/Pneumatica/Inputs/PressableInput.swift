//
//  Valvola+Inputs.swift
//  Pneumatica
//
//  Created by Dani Tox on 02/04/2019.
//

import SceneKit

class PressableInput: IOConformance, Tappable {
    var id : UUID = UUID()
    var parentValvola : ValvolaConformance
    var idleColor: UIColor = .red
    
    var ioNode: SCNNode
    
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
    
    init(node: SCNNode, valvola: ValvolaConformance) {
        self.ioNode = node
        self.parentValvola = valvola
        
        self.ariaPressure = 0
    }
    
    func tapped() {
        if self.ariaPressure <= 0 {
            self.ariaPressure = 2
        } else {
            self.ariaPressure = 0
        }
    }
    
}
