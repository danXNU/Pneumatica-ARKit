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
}


struct Packet: Codable {
    var comand: Command
}
