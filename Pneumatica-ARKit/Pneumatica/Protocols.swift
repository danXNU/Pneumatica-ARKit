//
//  Protocols.swift
//  Pneumatica-SpriteKit-iOS
//
//  Created by Dani Tox on 15/04/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import SceneKit

struct MovingPath {
    var startPoint: Float
    var endPoint: Float
}

protocol ValvolaConformance {
    var id: UUID { get set }
    
    var ios : [IOConformance] { get }
    var stringValue : String { get }
    
    static var keyStringClass: String { get }
    init?()
    
    var objectNode : SCNNode { get set }
    var labelNode : SCNNode? { get set }
    
    func update()
    var objectType: ObjectType { get }
}
extension ValvolaConformance {    
    static var keyStringClass: String {
        return String(describing: self)
    }
    
    var ios : [IOConformance] {
        var arr = [IOConformance]()
        
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let io = child.value as? InputOutput {
                arr.append(io)
            } else if let io = child.value as? PressableInput {
                arr.append(io)
            }
        }
        return arr
    }
    
    var stringValue : String {
        return String(describing: self)
    }
}

protocol Movable {
    var movingPointValue: Float { get }
    var movingObjectCurrentLocation: Float { get }
    var movingPath: MovingPath! { get set }
}
extension Movable {
    var movingPointValue : Float {
        let startPoint = self.movingPath.startPoint //20
        let endPoint = self.movingPath.endPoint // 40
        let pathLenght = (endPoint - startPoint) // 20
        
        let currentPoint = self.movingObjectCurrentLocation // 25
        let pathPercorsa = currentPoint - startPoint // 5
        
        let state = pathPercorsa / pathLenght // 5 : 20 = x : 1
        return state
    }
}

protocol Editable {}

protocol AcceptsMovableInput where Self: ValvolaConformance {
    var movableInput : Movable? { get set }
    var listenValue : Float { get set }
}



// IO
protocol IOConformance {
    var id: UUID { get set }
    var parentValvola : ValvolaConformance { get set }
    var idleColor : UIColor { get set }
    var ariaPressure : Double { get set }
    
    var ioNode: SCNNode { get set }
    
    func update()
}
extension IOConformance {
    func update() {}
}

protocol Tappable: IOConformance {
    func tapped()
}
extension Tappable {
    func tapped() {}
}



