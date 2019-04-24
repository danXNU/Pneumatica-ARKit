//
//  CreationObjectDataSource.swift
//  Pneumatica-SpriteKit-iOS
//
//  Created by Dani Tox on 16/04/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import UIKit
import SpriteKit

class ObjectCreationDataSource : NSObject, UITableViewDataSource {
    
    var types: [ValvolaConformance.Type] = [
        ValvolaAnd.self,
        ValvolaOR.self,
        GruppoFRL.self,
        CilindroDoppioEffetto.self,
        TreDueMonostabileNC.self,
        TreDueBistabile.self,
        TimerObject.self,
        CinqueDueBistabile.self,
        CinqueDueMonostabile.self,
        Pulsante.self,
        Finecorsa.self
    ]
    
    func createInstanceOf(index: Int) -> ValvolaConformance? {
        let type = types[index]
        return type.init()
    }
    
    func getType(at index: Int) -> ValvolaConformance.Type {
        return types[index]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return types.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "boldCell") as! BoldCell
        cell.mainLabel.text = types[indexPath.row].keyStringClass
        return cell
    }
    
}
