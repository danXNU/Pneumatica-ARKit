//
//  Packets.swift
//  ARRemote
//
//  Created by Dani Tox on 18/05/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import Foundation
import SceneKit

enum Modes: CaseIterable {
    static var allCases: [Modes] {
        return [.place(.setPlaceMode), .move(.setMoveMode), .edit(.setEditMode), .circuit(.setCircuitMode)]
    }
    
    case place(Command)
    case move(Command)
    case edit(Command)
    case circuit(Command)
}

enum Command: Int, Codable {
    case touch = 1
    
    case setPlaceMode = 2
    case setMoveMode = 3
    case setEditMode = 4
    case setCircuitMode = 5
    
    case andObject = 6
    case orObject = 7
    case pulsanteObject = 8
    case treDueMSObject = 9
    case treDueBSObject = 10
    case cinqueDueMSObject = 11
    case cinqueDueBSObject = 12
    case timerObject = 13
    case frlObject = 14
    case cilindroObject = 15
    case finecorsaObject = 16
    
}


struct Packet: Codable {
    var comand: Command
}


enum Objects: CaseIterable {
    static var allCases: [Objects] {
        return [.and(.andObject), .or(.orObject), .pulsante(.pulsanteObject),
                .treDueMS(.treDueMSObject), .treDueBS(.treDueBSObject),
                .cinqueDueMS(.cinqueDueMSObject), .cinqueDueBS(.cinqueDueBSObject),
                .timer(.timerObject), .frl(.frlObject), .cilindro(.cilindroObject),
                .finecorsa(.finecorsaObject)
        ]
    }
    
    case and(Command)
    case or(Command)
    case pulsante(Command)
    
    case treDueMS(Command)
    case treDueBS(Command)
    case cinqueDueMS(Command)
    case cinqueDueBS(Command)
    
    case timer(Command)
    case frl(Command)
    case cilindro(Command)
    case finecorsa(Command)
    
}


struct Vector3: Codable {
    var x: Float
    var y: Float
    var z: Float
    
    init(vector: SCNVector3) {
        self.x = vector.x
        self.y = vector.y
        self.z = vector.z
    }
    
}
extension SCNVector3 {
    init(cvector: Vector3) {
        self.init()
        x = cvector.x
        y = cvector.y
        z = cvector.z
    }
}

enum ObjectType: Int, Codable {
    case and = 1
    case or = 2
    case pulsante = 3
    case treDueMS = 4
    case treDueBS = 5
    case cinqueDueMS = 6
    case cinqueDueBS = 7
    case timer = 8
    case frl = 9
    case cilindro = 10
    case finecorsa = 11
}

struct MoveCommand: Codable {
    var objectID: UUID
    var newPosition: Vector3
}

struct RotateCommand: Codable {
    var objectIDs: [UUID]
    var newEulerAngles: Vector3
}

struct RemoveCommand: Codable {
    var objectIDs: [UUID]
    var removeCommand : String = "remove"
}

struct AddCommand: Codable {
    var newID: UUID
    var objectType: ObjectType
    var position: Vector3
    var eulerAngles: Vector3
}

class CustomEncoder {
    class func encode<T:Encodable>(object: T) -> Data? {
        if let data = try? JSONEncoder().encode(object) { return data }
        else { return nil }
    }
}
