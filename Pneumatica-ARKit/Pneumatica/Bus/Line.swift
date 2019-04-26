//
//  Line.swift
//  Pneumatica-SceneKit
//
//  Created by Dani Tox on 23/04/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import SceneKit
import CoreGraphics

class Line: Equatable {
    static func == (lhs: Line, rhs: Line) -> Bool {
        return lhs.lineNode == rhs.lineNode
    }
    
    var lineNode : SCNNode
    var firstIO : InputOutput!
    var secondIO: InputOutput!
  
    init(from firstIO: InputOutput, to secondIO: InputOutput) {
        self.firstIO = firstIO
        self.secondIO = secondIO
        self.lineNode = SCNNode()
    }
    
    func update() {
        if self.firstIO.ariaPressure > 0 && self.secondIO.ariaPressure > 0 {
            self.lineNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            self.lineNode.childNodes.forEach { $0.geometry?.firstMaterial?.diffuse.contents = UIColor.green  }
        } else {
            self.lineNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            self.lineNode.childNodes.forEach { $0.geometry?.firstMaterial?.diffuse.contents = UIColor.red  }
        }
    }
    
    func draw() {
        self.lineNode.childNodes.forEach { $0.removeFromParentNode() }
        
        let startPosition = firstIO.ioNode.worldPosition
        let endPosition = secondIO.ioNode.worldPosition
        
        let zPos = startPosition.z
//        let zPos = firstIO.ioNode.position.z
        
        var currentPosition = startPosition
        
        var allVectors: [(SCNVector3, SCNVector3)] = []
        
        
        let firstSegmentLenght = abs(startPosition.y - endPosition.y) / 2
        if startPosition.y > endPosition.y {
            currentPosition = SCNVector3(currentPosition.x, currentPosition.y - firstSegmentLenght, zPos)
        } else {
            currentPosition = SCNVector3(currentPosition.x, currentPosition.y + firstSegmentLenght, zPos)
        }
        allVectors.append((startPosition, currentPosition))
        
        
        var temp = currentPosition
        let secondSegmentLenght = abs(currentPosition.x - endPosition.x)
        if currentPosition.x > endPosition.x {
            currentPosition = SCNVector3(currentPosition.x - secondSegmentLenght, currentPosition.y, zPos)
        } else {
            currentPosition = SCNVector3(currentPosition.x + secondSegmentLenght, currentPosition.y, zPos)
        }
        allVectors.append((temp, currentPosition))
        
        
        temp = currentPosition
        let thirdSegmentLenght = abs(currentPosition.y - endPosition.y)
        if currentPosition.y > endPosition.y {
            currentPosition = SCNVector3(currentPosition.x, currentPosition.y - thirdSegmentLenght, zPos)
        } else {
            currentPosition = SCNVector3(currentPosition.x, currentPosition.y + thirdSegmentLenght, zPos)
        }
        allVectors.append((temp, currentPosition))
        
        
        for (firstV, secondV) in allVectors {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: CGFloat(firstV.x), y: CGFloat(firstV.y)))
            path.addLine(to: CGPoint(x: CGFloat(secondV.x), y: CGFloat(secondV.y)))
            
            let geometry = SCNShape(path: path, extrusionDepth: 0.005)
            
            geometry.firstMaterial?.diffuse.contents = UIColor.red
            let node = SCNNode(geometry: geometry)
            node.position.z = zPos
            self.lineNode.addChildNode(node)
        }
    }
    
//    func draw() {
//        let startPosition = firstIO.ioNode.worldPosition
//        let finishPosition = secondIO.ioNode.worldPosition
//
//        var currentPosition = startPosition
//
//        let firstSegmentLenght = abs(startPosition.y - finishPosition.y)
//
//        let firstCylinder = SCNCylinder(radius: 0.1, height: firstSegmentLenght / 2)
//        let firstXSegmentNode = SCNNode(geometry: firstCylinder)
//        self.lineNode.addChildNode(firstXSegmentNode)
//        firstXSegmentNode.position.x = startPosition.x
//
//        if startPosition.y > finishPosition.y {
//            currentPosition.y -= firstSegmentLenght
//            firstXSegmentNode.position.y = startPosition.y - firstXSegmentNode.height / 2
//        } else if startPosition.y < finishPosition.y {
//            currentPosition.y += firstSegmentLenght
//            firstXSegmentNode.position.y = startPosition.y + firstXSegmentNode.height / 2
//        }
//
//        let secondSegementLenght = abs(currentPosition.x - finishPosition.x)
//        let secondSegmentGeometry = SCNCylinder(radius: 0.1, height: secondSegementLenght)
//        let secondSegmentNode = SCNNode(geometry: secondSegmentGeometry)
//
//
//        secondSegmentNode.position = firstXSegmentNode.position
//        secondSegmentNode.worldPosition.y = firstXSegmentNode.worldPosition.y + firstXSegmentNode.height / 2
//
//        if currentPosition.x > finishPosition.x {
//            currentPosition.x -= secondSegementLenght
//            secondSegmentNode.eulerAngles.z = CGFloat(90.0).degreesToRadians
//            secondSegmentNode.worldPosition.x -= secondSegementLenght / 2
//        } else if currentPosition.y < finishPosition.y {
//            currentPosition.x += secondSegementLenght
//            secondSegmentNode.eulerAngles.z = CGFloat(270.0).degreesToRadians
//            secondSegmentNode.worldPosition.x += secondSegementLenght / 2
//        }
//        self.lineNode.addChildNode(secondSegmentNode)
//
//
//        let lastNodeLenght = currentPositionr
//
//        let lastGeometry = SCNCylinder(radius: 0.1, height: firstSegmentLenght / 2)
//        let lastNode = SCNNode(geometry: lastGeometry)
//        lastNode.worldPosition = secondSegmentNode.worldPosition
//
//
//        if currentPosition.y > finishPosition.y {
//            lastNode.worldPosition.y -= lastNode.height / 2
//
//        } else if currentPosition.y < finishPosition.y {
//            lastNode.worldPosition.y += lastNode.height / 2
//        }
//        self.lineNode.addChildNode(lastNode)
//    }
    
}
