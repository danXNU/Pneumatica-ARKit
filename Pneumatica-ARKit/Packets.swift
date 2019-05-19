//
//  Packets.swift
//  ARRemote
//
//  Created by Dani Tox on 18/05/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import Foundation

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
