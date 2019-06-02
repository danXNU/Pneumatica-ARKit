//
//  Loader.swift
//  Pneumatica-SpriteKit-iOS
//
//  Created by Dani Tox on 19/04/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import SceneKit

enum LoaderError: Error {
    case errorFileData(String)
}

class Loader {
    private var circuit: Circuit
    
    private var allNodes : [ValvolaConformance] = []
    
    private var loaderNode: SCNNode
    
    init(url: URL, loaderNode: SCNNode) throws {
        self.loaderNode = loaderNode
        
        do {
            let data = try Data(contentsOf: url)
            let circuit = try JSONDecoder().decode(Circuit.self, from: data)
            self.circuit = circuit
        } catch {
            throw error
        }
    }
    
    init(fileName: String, loaderNode: SCNNode) throws {
        self.loaderNode = loaderNode
        
        let fileManager = FileManager.default
        let path = Folders.documentsPath.appending("/\(fileName)")
        guard let data = fileManager.contents(atPath: path) else {
            throw LoaderError.errorFileData("Errore file data")
        }
        do {
            let circuit = try JSONDecoder().decode(Circuit.self, from: data)
            self.circuit = circuit
        } catch {
            throw error
        }
        
    }
    
    public func load(completion: ([ValvolaConformance], [(InputOutput, InputOutput)]) -> Void) {
        for object in circuit.allObjects {
            guard var newObject = object.classType.getNode() else { continue }
            newObject.id = object.id //SUPER IMPORTANT
            newObject.objectNode.position = self.loaderNode.position + object.position.vector3
            newObject.objectNode.scale = object.scale.vector3
            allNodes.append(newObject)
            
//            sceneRootNode.addChildNode(newObject.objectNode)
        }
        
        var wires: [(InputOutput, InputOutput)] = []
        
        for link in circuit.links {
            let io = link.currentIO
            guard let nodeIO = self.getIONode(from: io) else { continue }
            
            for ioConnected in link.connectedIOs {
                guard let newNodeIO = getIONode(from: ioConnected) else { continue }
        
                if !wires.contains(where: { (wire) -> Bool in
                    wire.0 == nodeIO && wire.1 == newNodeIO ||
                    wire.0 == newNodeIO && wire.1 == nodeIO
                }) {
                    wires.append((nodeIO, newNodeIO))
                }
            }
        }
        completion(self.allNodes, wires)
    }
    
    private func getIONode(from io: IO) -> InputOutput? {
        let objectID = io.objectID
        guard let objectNode = self.getObjectNode(from: objectID) else { return nil }
        let ios = objectNode.ios.compactMap { $0 as? InputOutput }
        return ios.first(where: { $0.idNumber == io.objectIONumber })
    }
    
    private func getObjectNode(from id: UUID) -> ValvolaConformance? {
        return self.allNodes.first(where: { $0.id == id })
    }
    
}
