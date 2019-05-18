//
//  PointerView.swift
//  Pneumatica-ARKit
//
//  Created by Dani Tox on 18/05/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import UIKit

class PointerView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isOpaque = false
        self.backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        UIColor.yellow.setStroke()
        
        let centerX = rect.midX
        let centerY = rect.midY
        
        let centerPoint = CGPoint(x: centerX, y: centerY)
        
        context.move(to: centerPoint)
        
        var pos = CGPoint(x: rect.maxX, y: centerY)
        context.addLine(to: pos)
        context.move(to: centerPoint)
        
        pos = CGPoint(x: centerX, y: rect.minY)
        context.addLine(to: pos)
        context.move(to: centerPoint)
        
        pos = CGPoint(x: rect.minX, y: centerY)
        context.addLine(to: pos)
        context.move(to: centerPoint)
        
        pos = CGPoint(x: centerX, y: rect.maxX)
        context.addLine(to: pos)
        
        context.strokePath()
        
    }
}
