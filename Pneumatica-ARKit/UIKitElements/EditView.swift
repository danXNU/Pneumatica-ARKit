//
//  BaseInfoView.swift
//  Pneumatica-SpriteKit-iOS
//
//  Created by Dani Tox on 18/04/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import UIKit

class EditView : UIView {
    
    var slider: UISlider = {
        let slider = UISlider()
        slider.maximumValue = 1
        slider.value = 0
        return slider
    }()
    
    var valueLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.text = "0"
        return label
    }()
    
    var sliderValue : Float {
        let value = slider.value
        let roundedValue = Float(roundf(10.0 * value) / 10.0)
        return roundedValue
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .blue
        
        slider.addTarget(self, action: #selector(sliderMoved(_:)), for: .valueChanged)
        
        let sliderWidth = Int(self.frame.width - 20)
        let sliderHeight = 50
        slider.frame = CGRect(x: 10, y: 5, width: sliderWidth, height: sliderHeight)
        addSubview(slider)
        
        let labelWidth = 100
        let labelHeight = 50
        let labelX = Int(self.frame.width / 2) - labelWidth / 2
        let labelY = 20
        
        valueLabel.frame = CGRect(x: labelX, y: labelY, width: labelWidth, height: labelHeight)
        addSubview(valueLabel)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func sliderMoved(_ sender: UISlider) {
        let value = sender.value
        let roundedValue = Float(roundf(10.0 * value) / 10.0)
        valueLabel.text = "\(roundedValue)"
    }
    
}
