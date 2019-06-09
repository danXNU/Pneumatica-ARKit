//
//  Pulsante.swift
//  Pneumatica-SpriteKit-iOS
//
//  Created by Dani Tox on 15/04/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import SceneKit
import AVFoundation

class Pulsante: ValvolaConformance {
    enum PulsanteState {
        case premuto
        case riposo
    }
    
    var id : UUID = UUID()
    
    var state : PulsanteState = .riposo {
        didSet {
            if state == .premuto {
                self.outputMain.ariaPressure = inputAria.getMostHightInput()?.ariaPressure ?? 0
            } else {
                self.outputMain.ariaPressure = 0
            }
        }
    }
    
    var inputAria : InputOutput!
    var outputMain: InputOutput!
    var inputPulsante : PressableInput!
    
    var objectNode: SCNNode
    var labelNode: SCNNode?
    
    private lazy var onPlayer: AVAudioPlayer = {
        guard let url = Bundle.main.url(forResource: "buttonOn", withExtension: "m4a") else { fatalError() }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { fatalError() }
        player.prepareToPlay()
        return player
    }()
    
    private lazy var offPlayer: AVAudioPlayer = {
        guard let url = Bundle.main.url(forResource: "buttonOff", withExtension: "m4a") else { fatalError() }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { fatalError() }
        player.prepareToPlay()
        return player
    }()
    
    required init?() {
        guard let scene = SCNScene(named: sceneName) else { return nil }
        guard let node = scene.rootNode.childNode(withName: "pulsante", recursively: true) else { return nil }
        
        self.objectNode = node
        
        let inAriaNode = self.objectNode.childNode(withName: "inputAria", recursively: true)!
        self.inputAria = InputOutput(node: inAriaNode, valvola: self)
        
        let outMainNode = self.objectNode.childNode(withName: "mainOutput", recursively: true)!
        self.outputMain = InputOutput(node: outMainNode, valvola: self)
        
        
        let pulsanteNode = self.objectNode.childNode(withName: "button", recursively: true)!
        self.inputPulsante = PressableInput(node: pulsanteNode, valvola: self)
        
        inputAria.idNumber = 0
        outputMain.idNumber = 1
        
        
        self.labelNode = self.objectNode.childNode(withName: "label", recursively: true)
        
        self.inputPulsante.stateDidChange = {
            if self.inputPulsante.ariaPressure > 0 {
                self.onPlayer.play()
            } else {
                self.offPlayer.play()
            }
        }
    }
    
    func update() {
        if self.inputPulsante.ariaPressure > 0 {
            self.state = .premuto
        } else {
            self.state = .riposo
        }
    }
    
    func playClickedSound() {
        onPlayer.play()
    }
    
    func playReleaseSound() {
        offPlayer.play()
    }
    
    var objectType: ObjectType {
        return .pulsante
    }
}
