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
    
    var allLines : [Line] = []
    
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
    
    public func load(sceneRootNode: SCNNode, completion: ([ValvolaConformance], [Line]) -> Void) {
        for object in circuit.allObjects {
            guard var newObject = object.classType.getNode() else { continue }
            newObject.id = object.id //SUPER IMPORTANT
            newObject.objectNode.position = self.loaderNode.position + object.position.vector3//loaderNode.convertPosition(object.position.vector3, from: self.loaderNode)
//            newObject.objectNode.worldPosition.z = self.loaderNode.worldPosition.z
            newObject.objectNode.scale = object.scale.vector3
            allNodes.append(newObject)
            
            sceneRootNode.addChildNode(newObject.objectNode)
        }
        
        for link in circuit.links {
            let io = link.currentIO
            guard let nodeIO = self.getIONode(from: io) else { continue }
            
            for ioConnected in link.connectedIOs {
                guard let newNodeIO = getIONode(from: ioConnected) else { continue }
                nodeIO.addWire(to: newNodeIO)
                
                if !self.allLines.contains(where: { (line) -> Bool in
                    line.firstIO == nodeIO && line.secondIO == newNodeIO ||
                    line.firstIO == newNodeIO && line.secondIO == nodeIO
                }) {
                    self.allLines.append(Line(from: nodeIO, to: newNodeIO))
                }
            }
        }
        completion(self.allNodes, self.allLines)
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
