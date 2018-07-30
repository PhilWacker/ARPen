//
//  ARPenBox.swift
//  ARPen
//
//  Created by Philipp Wacker on 30.07.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation

struct ARPenBox {
    //position and corners are in world coordinates
    let position : SCNVector3
    let dimension : Float
    //l = left, r = right, b = back, f = front, d = down, h = high
    let corners : (lbd : SCNVector3, lfd : SCNVector3, rbd : SCNVector3, rfd : SCNVector3, lbh : SCNVector3, lfh : SCNVector3, rbh : SCNVector3, rfh : SCNVector3)
    let boxNode : SCNNode
    
    init(withPosition thePosition : SCNVector3, andDimension theDimension : Float) {
        self.position = thePosition
        self.dimension = theDimension
        
        let halfDimension = self.dimension/2
        
        self.corners.lbd = SCNVector3Make(self.position.x - halfDimension, self.position.y - halfDimension, self.position.z - halfDimension)
        self.corners.lfd = SCNVector3Make(self.position.x - halfDimension, self.position.y - halfDimension, self.position.z + halfDimension)
        self.corners.rbd = SCNVector3Make(self.position.x + halfDimension, self.position.y - halfDimension, self.position.z - halfDimension)
        self.corners.rfd = SCNVector3Make(self.position.x + halfDimension, self.position.y - halfDimension, self.position.z + halfDimension)
        self.corners.lbh = SCNVector3Make(self.position.x - halfDimension, self.position.y + halfDimension, self.position.z - halfDimension)
        self.corners.lfh = SCNVector3Make(self.position.x - halfDimension, self.position.y + halfDimension, self.position.z + halfDimension)
        self.corners.rbh = SCNVector3Make(self.position.x + halfDimension, self.position.y + halfDimension, self.position.z - halfDimension)
        self.corners.rfh = SCNVector3Make(self.position.x + halfDimension, self.position.y + halfDimension, self.position.z + halfDimension)
        
        let boxGeometry = SCNBox.init(width: CGFloat(self.dimension), height: CGFloat(self.dimension), length: CGFloat(self.dimension), chamferRadius: 0.0)
        self.boxNode = SCNNode.init(geometry: boxGeometry)
        self.boxNode.name = "Box"
        self.boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white
    }
    
    func distance(ofPoint point : SCNVector3) -> Float {
        switch (point.x, point.y, point.z) {
        //inside the box
        case (self.corners.lbd.x...self.corners.rbd.x, self.corners.lbd.y...self.corners.lbh.y, self.corners.lbd.z...self.corners.lfd.z):
            return 0
        //right of left of the box
        case (_, self.corners.lbd.y...self.corners.lbh.y, self.corners.lbd.z...self.corners.lfd.z):
            return min(abs(point.x - self.corners.lbd.x), abs(point.x - self.corners.rbd.x))
        //over or under the box
        case (self.corners.lbd.x...self.corners.rbd.x, _, self.corners.lbd.z...self.corners.lfd.z):
            return min(abs(point.y - self.corners.lbd.y), abs(point.y - self.corners.lbh.y))
        //in front or behind of the box
        case (self.corners.lbd.x...self.corners.rbd.x, self.corners.lbd.y...self.corners.lbh.y, _):
            return min(abs(point.z - self.corners.lbd.z), abs(point.z - self.corners.lfd.z))
        //depth is within the range
        case (_, _, self.corners.lbd.z...self.corners.lfd.z):
            return distance(ofPoint: (point.x, point.y), andDim1Borders: (self.corners.lbd.x, self.corners.rbd.x), andDim2Borders: (self.corners.lbd.y, self.corners.lbh.y))
        //height is within the range
        case (_, self.corners.lbd.y...self.corners.lbh.y, _):
            return distance(ofPoint: (point.x, point.z), andDim1Borders: (self.corners.lbd.x, self.corners.rbd.x), andDim2Borders: (self.corners.lbd.z, self.corners.lfd.z))
        //width is within the range
        case (self.corners.lbd.x...self.corners.rbd.x, _, _):
            return distance(ofPoint: (point.y, point.z), andDim1Borders: (self.corners.lbd.y, self.corners.lbh.y), andDim2Borders: (self.corners.lbd.z, self.corners.lfd.z))
        default:
            let xDistance = min(abs(point.x - self.corners.lbd.x), abs(point.x - self.corners.rbd.x))
            let yDistance = min(abs(point.y - self.corners.lbd.y), abs(point.y - self.corners.lbh.y))
            let zDistance = min(abs(point.z - self.corners.lbd.z), abs(point.z - self.corners.lfd.z))
            
            return sqrtf(powf(xDistance, 2) + powf(yDistance, 2) + powf(zDistance, 2))
        }
    }
    
    func distance(ofPoint point : (dim1 : Float, dim2 : Float), andDim1Borders dim1Borders : (min : Float, max : Float), andDim2Borders dim2Borders : (min: Float, max : Float)) -> Float {
        let dim1Distance = min(abs(point.dim1 - dim1Borders.min), abs(point.dim1 - dim1Borders.max))
        let dim2Distance = min(abs(point.dim2 - dim2Borders.min), abs(point.dim2 - dim2Borders.max))
        
        return sqrtf(powf(dim1Distance, 2) + powf(dim2Distance, 2))
    }
}