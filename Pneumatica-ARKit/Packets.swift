//
//  Packets.swift
//  ARRemote
//
//  Created by Dani Tox on 18/05/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import Foundation

enum Command: Int, Codable {
    case touch = 1
}


struct Packet: Codable {
    var comand: Command
}
