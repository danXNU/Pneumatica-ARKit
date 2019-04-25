//
//  DiskObjects.swift
//  Pneumatica-SpriteKit-iOS
//
//  Created by Dani Tox on 19/04/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import Foundation
import CoreGraphics
import SceneKit

struct Circuit : Codable {
    var id: UUID
    var version : String = "0.1"
    var name: String
    var centerVector: CustomVettore
    var allObjects: [Object]
    var links: [Link]
    
    init(name: String) {
        self.name = name
        self.id = UUID()
        self.centerVector = .zero
        self.allObjects = []
        self.links = []
    }
}

struct Object : Codable {
    var id: UUID
    var classType : ClassType
    var name: String = ""
    var position: CustomVettore
    var scale: CustomVettore
    
    init(classType: ClassType) {
        self.id = UUID()
        self.name = ""
        self.classType = classType
        self.position = CustomVettore.zero
        self.scale = CustomVettore.zero
    }
}

struct IO : Codable {
    var id: UUID
    var objectIONumber: Int
    var name: String?
    var objectID: UUID
    
    init(ioID: UUID, objectIONumber: Int, objectID: UUID) {
        self.id = ioID
        self.objectIONumber = objectIONumber
        self.objectID = objectID
    }
}

struct Link : Codable {
    var currentIO : IO
    var connectedIOs : [IO]
}

struct CustomVettore: Codable {
    var x: Float
    var y: Float
    var z: Float
    
    init(vector3: SCNVector3) {
        self.x = vector3.x
        self.y = vector3.y
        self.z = vector3.z
    }
    
    var vector3: SCNVector3 {
        return SCNVector3(x: x, y: y, z: z)
    }
    
    static var zero : CustomVettore {
        return CustomVettore(vector3: SCNVector3.init(x: 0, y: 0, z: 0))
    }
}


enum ClassType : Int, Codable {
    case And = 1
    case Or = 2
    case Frl = 3
    case CilindroDE = 4
    case TreDueMS = 5
    case Timer = 6
    case CinqueDueBS = 7
    case pulsante = 8
    case finecorsa = 9
    case CinqueDueMS = 10
    case TreDueBS = 11
    
    static func get(from obj: ValvolaConformance) -> ClassType? {
        if obj is ValvolaAnd {
            return .And
        } else if obj is ValvolaOR {
            return .Or
        } else if obj is GruppoFRL {
            return .Frl
        } else if obj is CilindroDoppioEffetto {
            return .CilindroDE
        } else if obj is TreDueMonostabileNC {
            return .TreDueMS
        } else if obj is TimerObject {
            return .Timer
        } else if obj is CinqueDueBistabile {
            return .CinqueDueBS
        } else if obj is Pulsante {
            return .pulsante
        } else if obj is Finecorsa {
            return .finecorsa
        } else if obj is CinqueDueMonostabile {
            return .CinqueDueMS
        } else if obj is TreDueBistabile {
            return .TreDueBS
        } else {
            return nil
        }
    }
    
    func getNode() -> ValvolaConformance? {
        switch self {
        case .And:
            return ValvolaAnd()
        case .CilindroDE:
            return CilindroDoppioEffetto()
        case .CinqueDueBS:
            return CinqueDueBistabile()
        case .CinqueDueMS:
            return CinqueDueMonostabile()
        case .finecorsa:
            return Finecorsa()
        case .Frl:
            return GruppoFRL()
        case .Or:
            return ValvolaOR()
        case .pulsante:
            return Pulsante()
        case .Timer:
            return TimerObject()
        case .TreDueBS:
            return TreDueBistabile()
        case .TreDueMS:
            return TreDueMonostabileNC()
        }
    }
}
