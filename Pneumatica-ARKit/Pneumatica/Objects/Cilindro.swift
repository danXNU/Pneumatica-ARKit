//
//  TestNode.swift
//  to-remove
//
//  Created by Dani Tox on 20/04/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import SceneKit
import AVFoundation

class CilindroDoppioEffetto : ValvolaConformance, Movable {
    enum CyclinderState {
        case fuoriuscito
        case interno
        case animating
    }
    
    var id: UUID = UUID()
    
    var inputLeft : InputOutput!
    var inputRight : InputOutput!
    
    var state : CyclinderState = .interno
    
    var pistone: SCNNode!
    var objectNode: SCNNode
    var labelNode: SCNNode?
    
    var pistonAction: SCNAction!
    
    var movingObjectCurrentLocation: Float {
        return self.pistone.position.x
    }
    var movingPath: MovingPath!
    
    private lazy var exitSoundPlayer: AVAudioPlayer = {
        guard let url = Bundle.main.url(forResource: "pistonOn", withExtension: "m4a") else { fatalError() }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { fatalError() }
        player.prepareToPlay()
        return player
    }()
    
    private lazy var enterSoundPlayer: AVAudioPlayer = {
        guard let url = Bundle.main.url(forResource: "pistonOff", withExtension: "m4a") else { fatalError() }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { fatalError() }
        player.prepareToPlay()
        return player
    }()
    
    required init?() {
        guard let scene = SCNScene(named: sceneName) else { return nil }
        guard let node = scene.rootNode.childNode(withName: "cilindro", recursively: true) else { return nil }
        
        self.objectNode = node
        
        let ioLeftNode = objectNode.childNode(withName: "ioLeft", recursively: true)!
        let ioRightNode = objectNode.childNode(withName: "ioRight", recursively: true)!
        
        self.inputLeft = InputOutput(node: ioLeftNode, valvola: self)
        self.inputRight = InputOutput(node: ioRightNode, valvola: self)
        
        inputLeft.idNumber = 0
        inputRight.idNumber = 1
        
        self.pistone = node.childNode(withName: "pistone", recursively: true)!
        
        self.labelNode = self.objectNode.childNode(withName: "label", recursively: true)!
        
        let startPointPath = self.pistone.position.x
        let finishPointPath = self.pistone.position.x + pistone.height / 5
        self.movingPath = MovingPath(startPoint: startPointPath, endPoint: finishPointPath)
        
        let sceneAction = SCNAction.moveBy(x: CGFloat(pistone.height / 5.0), y: 0, z: 0, duration: 0.3)
        self.pistonAction = sceneAction
    }
    
    func update() {
        inputLeft.update()
        inputRight.update()
        
        switch state {
        case .interno:
            if inputLeft.ariaPressure > 0 && inputRight.ariaPressure <= 0 {
                self.pistone?.runAction(pistonAction)
                self.state = .fuoriuscito
                self.exitSoundPlayer.play()
            }
        case .fuoriuscito:
            if inputRight.ariaPressure > 0 && inputLeft.ariaPressure <= 0 {
                self.pistone.runAction(pistonAction.reversed())
                self.state = .interno
                self.enterSoundPlayer.play()
            }
        case .animating: break // da fare in futuro se necessario
        }
    }
    
    func enable() {}
    
    var objectType: ObjectType {
        return .cilindro
    }
}
