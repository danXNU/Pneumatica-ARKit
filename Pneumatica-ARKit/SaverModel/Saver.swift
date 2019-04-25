//
//  Saver.swift
//  Pneumatica-SpriteKit-iOS
//
//  Created by Dani Tox on 19/04/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import SceneKit

class Saver {
    var virtualObjects : [Object] = []
    var nodes: [ValvolaConformance] = []
    
    var links: [Link] = []
    
    var circuit: Circuit
    
    var nodeSaver: SCNNode
    
    init(circuitName: String, nodes: [ValvolaConformance], nodeSaver: SCNNode) {
        self.circuit = Circuit(name: circuitName)
        self.circuit.centerVector = .zero
        self.nodes = nodes
        self.nodeSaver = nodeSaver
        calculate()
    }
    
    public func save(to fileName: String) throws {
        self.circuit.name = fileName
        self.circuit.allObjects = self.virtualObjects
        self.circuit.links = self.links
        
        let fileManager = FileManager.default
        do {
            let data = try JSONEncoder().encode(self.circuit)
            
            let filePath = Folders.documentsPath.appending("/\(fileName)")
            print("FILE PATH: \(filePath)")
            
            if fileManager.fileExists(atPath: filePath) {
                try fileManager.removeItem(atPath: filePath)
            }
            fileManager.createFile(atPath: filePath, contents: data, attributes: nil)
        } catch {
            throw error
        }
    }
    
    
    private func calculate() {
        for node in self.nodes {
            guard let classType = ClassType.get(from: node) else { continue }
            
            let nodePosition = node.objectNode.convertPosition(node.objectNode.position, to: self.nodeSaver)
            
            var newObject = Object(classType: classType)
            newObject.id = node.id
            newObject.position = CustomVettore(vector3: nodePosition)
            newObject.scale = CustomVettore(vector3: node.objectNode.scale)
            
            self.virtualObjects.append(newObject)
        }
    
        
        for node in self.nodes {
            let nodeIOs = node.ios.compactMap { $0 as? InputOutput }
            
            for io in nodeIOs {
                guard let currentIO = self.createVirtualIO(from: io) else { continue }
                let connectedIOs = self.createMultipleVirtualIOs(from: io.inputsConnected)
                guard connectedIOs.count > 0 else { continue }
                
                let newLink = Link(currentIO: currentIO, connectedIOs: connectedIOs)
                self.links.append(newLink)
            }
            
        }
        
    }
    
    private func createVirtualIO(from io: InputOutput) -> IO? {
        let ioParentValvola = io.parentValvola
        guard let parentObject = self.virtualObjects.first(where: { $0.id == ioParentValvola.id }) else { return nil }
        
        return IO(ioID: io.id, objectIONumber: io.idNumber, objectID: parentObject.id)
    }
    
    private func createMultipleVirtualIOs(from collection: Set<InputOutput>) -> [IO] {
        let ios : [IO] = collection.compactMap { self.createVirtualIO(from: $0) }
//        for nodeIo in collection {
//            if let temp = self.createVirtualIO(from: nodeIo) {
//                ios.append(temp)
//            }
//        }
        return ios
    }
    
}
