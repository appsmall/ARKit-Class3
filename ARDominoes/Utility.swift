//
//  Utility.swift
//  ARDominoes
//
//  Created by apple on 11/05/19.
//  Copyright © 2019 appsmall. All rights reserved.
//

import UIKit
import ARKit

class Utility {
    
    class func distanceBetween(point1: SCNVector3, andPoint2 point2: SCNVector3) -> Float {
        // hypotf: It calculates the distance between the two points.
        return hypotf(Float(point1.x - point2.x), Float(point1.z - point2.z))
    }
    
    // We can get the angle between two dominoes using the arcTan formula.
    // This formula calculates the angle between two points relative to an axis
    class func pointPairToBearingDegrees(startingPoint: CGPoint, endingPoint: CGPoint) -> Float {
        let originPoint = CGPoint(x: startingPoint.x - endingPoint.x, y: startingPoint.y - endingPoint.y)
        let bearingRadians = atan2f(Float(originPoint.y), Float(originPoint.x))
        let bearingDegrees = bearingRadians * (180.0 / Float.pi)
        return bearingDegrees
    }
    
}
