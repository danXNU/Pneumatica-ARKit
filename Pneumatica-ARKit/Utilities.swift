/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience extensions on system types.
*/

import ARKit

var sceneName = "Assets.scnassets/objects.scn"

@available(iOS 12.0, *)
extension ARPlaneAnchor.Classification {
    var description: String {
        switch self {
        case .wall:
            return "Wall"
        case .floor:
            return "Floor"
        case .ceiling:
            return "Ceiling"
        case .table:
            return "Table"
        case .seat:
            return "Seat"
        case .none(.unknown):
            return "Unknown"
        default:
            return ""
        }
    }
}

extension SCNNode {
    func centerAlign() {
        let (min, max) = boundingBox
        let extents = float3(max) - float3(min)
        simdPivot = float4x4(translation: ((extents / 2) + float3(min)))
    }
}

extension float4x4 {
    init(translation vector: float3) {
        self.init(float4(1, 0, 0, 0),
                  float4(0, 1, 0, 0),
                  float4(0, 0, 1, 0),
                  float4(vector.x, vector.y, vector.z, 1))
    }
}

extension SCNNode {
    var width : Float {
        let min = self.boundingBox.min.x
        let max = self.boundingBox.max.x
        
        return max - min
    }
    
    var height : Float {
        let min = self.boundingBox.min.y
        let max = self.boundingBox.max.y
        
        return max - min
    }
    
    var lenght : Float {
        let min = self.boundingBox.min.z
        let max = self.boundingBox.max.z
        
        return max - min
    }
}

extension FloatingPoint {
    var degreesToRadians : Self {
        return self * .pi / 180
    }
    
    var radiansToDegrees : Self {
        return self * 180 / .pi
    }
}

extension SCNNode {
    func completeCopy() -> SCNNode {
        let newNode = self.clone()
        newNode.geometry = self.geometry!.copy() as? SCNGeometry
        
        for child in newNode.childNodes {
            guard let nodeName = child.name else { continue }
            let oldNode = self.childNode(withName: nodeName, recursively: true)!
            child.geometry = oldNode.geometry?.copy() as? SCNGeometry
        }
        
        return newNode
    }
}
