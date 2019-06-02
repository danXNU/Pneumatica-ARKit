//
//  Converter.swift
//  Pneumatica-ARKit
//
//  Created by Daniel Fortesque on 02/06/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import Foundation
import SceneKit
import CoreGraphics

class Converter {
    
    var spriteCircuit: SpriteCircuit
    
    init(circuit: SpriteCircuit) {
        self.spriteCircuit = circuit
    }
    
    init(fileName: String) {
        let fileManager = FileManager.default
        let path = Folders.documentsPath.appending("/\(fileName)")
        guard let data = fileManager.contents(atPath: path) else { fatalError() }
        
        do {
            let circuit2D = try JSONDecoder().decode(SpriteCircuit.self, from: data)
            self.spriteCircuit = circuit2D
        } catch {
            fatalError("\(error)")
        }
    }
    
    func convert() {
        let spriteObjects = self.spriteCircuit.allObjects
        var sceneObjects = [Object]()
        
        for sprite in spriteObjects {
            var newSceneObject = Object(classType: ClassType(rawValue: sprite.classType.rawValue)!)
            newSceneObject.id = sprite.id
            newSceneObject.name = sprite.name
            newSceneObject.position = CustomVettore(vector3: SCNVector3(sprite.position.x / 1000, sprite.position.y / 1000, 0))
            newSceneObject.scale = CustomVettore(vector3: .init(1, 1, 1))
            
            sceneObjects.append(newSceneObject)
        }
        
        var newCircuit = Circuit(name: self.spriteCircuit.name)
        newCircuit.id = spriteCircuit.id
        newCircuit.allObjects = sceneObjects
        newCircuit.links = spriteCircuit.links
        newCircuit.version = spriteCircuit.version
//        newCircuit.centerVector = .zero
        
        let fileManager = FileManager.default
        do {
            let data = try JSONEncoder().encode(newCircuit)
            
            let filePath = Folders.documentsPath.appending("/circuit2D-3D.json")
            print("FILE PATH: \(filePath)")
            
            if fileManager.fileExists(atPath: filePath) {
                try fileManager.removeItem(atPath: filePath)
            }
            fileManager.createFile(atPath: filePath, contents: data, attributes: nil)
        } catch {
            fatalError("\(error)")
        }
    }
    
}
