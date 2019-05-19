//
//  EditsMode.swift
//  Pneumatica-ARKit
//
//  Created by Dani Tox on 18/05/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import SceneKit

enum EditMode : String {
    case moveMode = "Move"
    case editSettingsMode = "Edit"
    case placeMode = "Place"
    case circuitMode = "Circuit"
    case saveMode = "Save"
    case loadMode = "Load"
}

enum HandsMode {
    case normal
    case handsFree
}

struct MovableEdit {
    var isActive: Bool = false
    var selectedInput : Movable? = nil
    var selectedValvolaWithMovableInput: AcceptsMovableInput? = nil
    var valueOfTrigger: Float = 0.0
    var editView: EditView
    var isSelectingFinecorsa: Bool = false
    
    init(frame: CGRect) {
        self.editView = EditView(frame: frame)
        reset()
    }
    
    mutating func reset() {
        self.editView.isHidden = true
        self.isActive = false
        self.valueOfTrigger = 0
        self.selectedInput = nil
        self.selectedValvolaWithMovableInput = nil
        self.isSelectingFinecorsa = false
    }
}
