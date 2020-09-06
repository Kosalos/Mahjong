import UIKit
import SceneKit
import Foundation
import SceneKit

let NUMPT = 20
let NUMLINE = 12

var d1:Float = (1 + sqrt(5.0)) / 2
var d2:Float = 1.0 / d1

var dVertices:[SCNVector3] = []

let indices:[Int32] = [
    0,1,
    1,2,
    2,3,
    3,4,
    0,4,
    
    0,5,
    5,14,
    9,14,
    4,9,
    //4,0,
    
    1,6,
    6,10,
    5,10,
    //0,5,
    //0,1,
    
    2,7,
    7,11,
    6,11,
    //6,1,
    //1,2,
    
    3,8,
    8,12,
    7,12,
    //2,7,
    //2,3,
    
    //4,9,
    9,13,
    8,13,
    //3,8,
    //3,4,
    
    14,19,
    //9,14,
    //9,13,
    13,18,
    //18,19,
    
    //13,18,
    //8,13,
    //8,12,
    12,17,
    //17,18,
    
    //12,17,
    //7,12,
    //7,11,
    11,16,
    //16,17,
    
    //11,16,
    //6,11,
    //6,10,
    10,15,
    //15,16,
    
    //10,15,
    //5,10,
    //5,14,
    14,19,
    15,19,

    15,16,
    16,17,
    17,18,
    18,19,
    //15,19
]

let iv2:[Int32] = [
    0,1,1,2,2,3,3,4,4,0,
  
    0,9,9,10,10,11,11,5,5,0,
    1,12,12,13,13,14,14,9,9,1,
    2,15,15,16,16,17,17,12,12,2,
    3,8,8,18,18,19,19,15,15,3,
    4,5,5,6,6,7,7,8,8,4,
    
    27,28,28,29,29,30,30,26,26,27,
    13,17,17,22,22,28,28,23,23,13,
    16,19,19,21,21,29,29,22,22,16,
    14,23,23,27,27,24,24,10,10,14,
    18,21,21,30,30,20,20,7,7,18,
    6,11,11,24,24,26,26,20,20,6
]

func createGeometry(_ vertices:[SCNVector3], _ indices:[Int32], _ primitiveType:SCNGeometryPrimitiveType) -> SCNGeometry {
    
    var primitiveCount:Int {
        get {
            switch primitiveType {
            case SCNGeometryPrimitiveType.line:     return indices.count / 2
            case SCNGeometryPrimitiveType.point:    return indices.count
            case SCNGeometryPrimitiveType.triangles,
                 SCNGeometryPrimitiveType.triangleStrip:  return indices.count / 3
            default: return 0
            }
        }
    }
    
    let data = NSData(bytes: vertices, length: MemoryLayout<SCNVector3>.size * vertices.count)
    let vertexSource = SCNGeometrySource(
        data: data as Data, semantic: SCNGeometrySource.Semantic.vertex,
        vectorCount: vertices.count, usesFloatComponents: true, componentsPerVector: 3,
        bytesPerComponent: MemoryLayout<Float>.size, dataOffset: 0, dataStride: MemoryLayout<SCNVector3>.size)
    let indexData = NSData(bytes: indices, length: MemoryLayout<Int32>.size * indices.count)
    let element = SCNGeometryElement(
        data: indexData as Data, primitiveType: primitiveType,
        primitiveCount: primitiveCount, bytesPerIndex: MemoryLayout<Int32>.size)
    
    return SCNGeometry(sources: [vertexSource], elements: [element])
}

// MARK: Dodecahedron

var shrink:Float = 0.7

class Dodecahedron {
    var iv = Array<Int32>()
    var mv1 = Array<SCNVector3>()
    var mv2 = Array<SCNVector3>()
    var mv1Node = Array<SCNNode>()
    var mv2Node = Array<SCNNode>()
    var light:SCNNode!
    var lightAngle:Float = 0
    var base:SCNVector3
    
    init(_ nBase:SCNVector3) {
        base = nBase
        
        for i in 0 ..< 20 {  dVertices.append(SCNVector3()) }
        
        for i in 0 ..< 31 {
            let box = SCNSphere(radius:0.2)
            box.firstMaterial?.diffuse.contents = UIColor(red: 1, green:0.6, blue:0.1, alpha:1.0)

            mv1Node.append(SCNNode(geometry:box))
            scenePtr.rootNode.addChildNode(mv1Node[i])

            mv2Node.append(SCNNode(geometry:box))
            scenePtr.rootNode.addChildNode(mv2Node[i])

            mv1.append(base)
            mv2.append(base)
        }
        
        var index = 0
        let aDelta:Float = 72.0 * Float(Float.pi) / 180.0
        
        func addPentagon(_ startAngle:Float, _ size:Float, _ yCoord:Float) {
            var angle = startAngle
            for _ in 0 ..< 5 {
                dVertices[index].x = base.x + cosf(angle) * size
                dVertices[index].y = base.y + yCoord
                dVertices[index].z = base.z + sinf(angle) * size
                angle += aDelta
                index += 1
            }
        }
        
        addPentagon(0,1.0,-1.2)
        addPentagon(0,1.6,-0.3)
        addPentagon(aDelta/2,1.6,+0.3)
        addPentagon(aDelta/2,1.0,+1.2)
        
        for i in 0 ..< NUMPT {
            addBall(dVertices[i])
        }
        
        drawLines(dVertices,indices)
       
        //drawLine(p1:SCNVector3(x:0, y:0, z:0), base)

        // midpoints ----------------------------
        var iIndex:Int32 = 0

        for i in 0 ..< indices.count/2  {
            let p1 = dVertices[Int(indices[i*2])]
            let p2 = dVertices[Int(indices[i*2+1])]

            var v1 = SCNVector3()
            v1.x = (p1.x+p2.x)/2
            v1.y = (p1.y+p2.y)/2
            v1.z = (p1.z+p2.z)/2

            mv1[i] = v1
            mv2[i] = v1

            mv1Node[i].position = mv1[i]
            mv2Node[i].position = mv2[i]

            iv.append(iIndex); iIndex += 1
            iv.append(iIndex); iIndex += 1

        }

        let box = SCNSphere(radius:0.3)
        box.firstMaterial?.diffuse.contents = UIColor(red: 1, green:0.6, blue:0.1, alpha:1.0)

        let myFloor = SCNFloor()
        myFloor.reflectivity = 0.5
        let myFloorNode = SCNNode(geometry: myFloor)
        myFloorNode.position = SCNVector3(x: 0, y: -3, z: 0)
        scenePtr.rootNode.addChildNode(myFloorNode)

        let spotLight = SCNLight()
        spotLight.type = SCNLight.LightType.spot
        spotLight.castsShadow = true
        spotLight.spotOuterAngle = 90.0
        spotLight.zFar = 600

        light = SCNNode()
        light.light = spotLight
        light.position = SCNVector3(x:0, y: 30, z:200) // 0 30 200    0 50 160
        scenePtr.rootNode.addChildNode(light)
    }
    
    func updateMv2(_ scale:Float) {
        for i in 0..<31 {
            var v = mv2[i]
            
            v.x -= base.x
            v.y -= base.y
            v.z -= base.z
            
            v.x *= scale
            v.y *= scale
            v.z *= scale
            
            v.x += base.x
            v.y += base.y
            v.z += base.z
            
            mv2Node[i].position = v
            mv2Node[i].geometry!.firstMaterial?.diffuse.contents = UIColor(red:1, green:CGFloat(scale), blue:0.1, alpha:1.0)
        }
    }
    
    
    var scale:Float = 1
    var scaleAngle:Float = 0
    
    func update() {
        scale = 0.9 + cosf(scaleAngle) * 0.7
        scaleAngle += 0.1
        updateMv2(scale)
    }
    
    func addBall(_ v:SCNVector3) {
        let box = SCNSphere(radius:0.3)
        box.firstMaterial?.diffuse.contents = UIColor(red: 1, green:0.7, blue:0.1, alpha:1.0)
        
        let bn = SCNNode(geometry:box)
        bn.position = v
        scenePtr.rootNode.addChildNode(bn)
    }
    
    func drawLines(_ v:[SCNVector3], _ indices:[Int32])  {
        let w1 = createGeometry(v,indices,SCNGeometryPrimitiveType.line)
        w1.firstMaterial?.diffuse.contents = UIColor(red:1, green:1, blue:1, alpha:1.0)
        w1.firstMaterial?.emission.contents = UIColor.white
        let w2 = SCNNode(geometry:w1)
        scenePtr.rootNode.addChildNode(w2)
    }
    
    func drawLine(p1:SCNVector3, _ p2:SCNVector3)
    {
        let v:[SCNVector3] = [ p1,p2 ]
        let indices:[Int32] = [ 0,1 ]
        drawLines(v,indices)
    }
    
    required init(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
}

//class Dodecahedron {
//    var iv = Array<Int32>()
//    var mv1 = Array<SCNVector3>()
//    var mv2 = Array<SCNVector3>()
//    var mv1Node = Array<SCNNode>()
//    var mv2Node = Array<SCNNode>()
//    var light:SCNNode!
//    var lightAngle:Float = 0
//    var base:SCNVector3
//
//    init(_ nBase:SCNVector3) {
//        base = nBase
//
//        //       for i in 0 ..< 20 {  dVertices[i] = SCNVector3Normalize(dVertices[i]) }
//
//        for i in 0 ..< 31 {
//            let box = SCNSphere(radius:0.2)
//            box.firstMaterial?.diffuse.contents = UIColor(red: 1, green:0.6, blue:0.1, alpha:1.0)
//
//            mv1Node.append(SCNNode(geometry:box))
//            scenePtr.rootNode.addChildNode(mv1Node[i])
//
//            mv2Node.append(SCNNode(geometry:box))
//            scenePtr.rootNode.addChildNode(mv2Node[i])
//
//            mv1.append(base)
//            mv2.append(base)
//        }
//
//        var index = 0
//        let aDelta:Float = 72.0 * Float(Float.pi) / 180.0
//
//        func addPentagon(_ startAngle:Float, _ size:Float, _ yCoord:Float)
//        {
//            var angle = startAngle
//
//            for _ in 0 ..< 5 {
//                dVertices[index].x = base.x + cosf(angle) * size
//                dVertices[index].y = base.y + yCoord
//                dVertices[index].z = base.z + sinf(angle) * size
//                angle += aDelta
//                index += 1
//            }
//        }
//
//        addPentagon(0,1.0,-1.2)
//        addPentagon(0,1.6,-0.3)
//        addPentagon(aDelta/2,1.6,+0.3)
//        addPentagon(aDelta/2,1.0,+1.2)
//
//        for i in 0 ..< NUMPT {
//            addBall(dVertices[i])
//        }
//
//        drawLines(dVertices,indices)
//
//        // midpoints ----------------------------
//        var iIndex:Int32 = 0
//
//        for i in 0 ..< indices.count/2  {
//            let p1 = dVertices[Int(indices[i*2])]
//            let p2 = dVertices[Int(indices[i*2+1])]
//
//            var v1 = SCNVector3()
//            v1.x = (p1.x+p2.x)/2
//            v1.y = (p1.y+p2.y)/2
//            v1.z = (p1.z+p2.z)/2
//
//            v1.x += base.x
//            v1.y += base.y
//            v1.z += base.z
//
//            mv1[i] = v1
//            mv2[i] = v1
//
//            mv1Node[i].position = mv1[i]
//            mv2Node[i].position = mv2[i]
//
//            iv.append(iIndex); iIndex += 1
//            iv.append(iIndex); iIndex += 1
//
//        }
//
//        let box = SCNSphere(radius:0.3)
//        box.firstMaterial?.diffuse.contents = UIColor(red: 1, green:0.6, blue:0.1, alpha:1.0)
//
//        let myFloor = SCNFloor()
//        myFloor.reflectivity = 0.5
//        let myFloorNode = SCNNode(geometry: myFloor)
//        myFloorNode.position = SCNVector3(x: 0, y: -3, z: 0)
//        scenePtr.rootNode.addChildNode(myFloorNode)
//
//        let spotLight = SCNLight()
//        spotLight.type = SCNLight.LightType.spot
//        spotLight.castsShadow = true
//        spotLight.spotOuterAngle = 90.0
//        spotLight.zFar = 600
//
//        light = SCNNode()
//        light.light = spotLight
//        light.position = SCNVector3(x:0, y: 30, z:200) // 0 30 200    0 50 160
//        scenePtr.rootNode.addChildNode(light)
//    }
//
//    func updateMv2(_ scale:Float) {
//        for i in 0..<31 {
//            var v = mv2[i]
//            v.x *= scale
//            v.y *= scale
//            v.z *= scale
//
//            mv2Node[i].position = v
//
//            mv2Node[i].position.x += base.x
//            mv2Node[i].position.y += base.y
//            mv2Node[i].position.z += base.z
//
//            mv2Node[i].geometry!.firstMaterial?.diffuse.contents = UIColor(red:1, green:CGFloat(scale), blue:0.1, alpha:1.0)
//        }
//    }
//
//
//    var scale:Float = 1
//    var scaleAngle:Float = 0
//
//    func update() {
//        scale = 0.9 + cosf(scaleAngle) * 0.7
//        scaleAngle += 0.1
//        updateMv2(scale)
//    }
//
//    func addBall(_ v:SCNVector3) {
//        let box = SCNSphere(radius:0.3)
//        box.firstMaterial?.diffuse.contents = UIColor(red: 1, green:0.7, blue:0.1, alpha:1.0)
//
//        let bn = SCNNode(geometry:box)
//        bn.position = v
//
//        bn.position.x += base.x
//        bn.position.y += base.y
//        bn.position.z += base.z
//
//        scenePtr.rootNode.addChildNode(bn)
//    }
//
//    func drawLines(_ v:[SCNVector3], _ indices:[Int32])
//    {
//        let w1 = createGeometry(v,indices,SCNGeometryPrimitiveType.line)
//        let w2 = SCNNode(geometry:w1)
//        scenePtr.rootNode.addChildNode(w2)
//    }
//
//    func drawLine(p1:SCNVector3, _ p2:SCNVector3)
//    {
//        let v:[SCNVector3] = [ p1,p2 ]
//        let indices:[Int32] = [ 0,1 ]
//        drawLines(v,indices)
//    }
//
//
//    //    func timerHandler()
//    //    {
//    //    }
//
//    required init(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
//
//}

extension SCNVector3 {
    mutating func add(v:SCNVector3) {
        self.x += v.x
        self.y += v.y
        self.z += v.z
    }
}

func SCNVector3Normalize(_ v1:SCNVector3) -> SCNVector3
{
    var v = v1
    let dist = sqrtf(v.x*v.x + v.y*v.y + v.z*v.z)
    if dist > 0.0 {
        v.x /= dist
        v.y /= dist
        v.z /= dist
    }
    
    return v
}

class Geometry : NSObject {
    internal func createGeometry(vertices:[SCNVector3], indices:[Int32], primitiveType:SCNGeometryPrimitiveType) -> SCNGeometry {
        
        // Computed property that indicates the number of primitives to create based on primitive type
        var primitiveCount:Int {
            get {
                switch primitiveType {
                case SCNGeometryPrimitiveType.line:
                    return indices.count / 2
                case SCNGeometryPrimitiveType.point:
                    return indices.count
                case SCNGeometryPrimitiveType.triangles,
                     SCNGeometryPrimitiveType.triangleStrip:
                    return indices.count / 3
                default : return 0
                }
            }
        }
        
        let data = NSData(bytes: vertices, length: MemoryLayout<SCNVector3>.size * vertices.count)
        let vertexSource = SCNGeometrySource(
            data: data as Data, semantic: SCNGeometrySource.Semantic.vertex,
            vectorCount: vertices.count, usesFloatComponents: true, componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size, dataOffset: 0, dataStride: MemoryLayout<SCNVector3>.size)
        let indexData = NSData(bytes: indices, length: MemoryLayout<Int32>.size * indices.count)
        let element = SCNGeometryElement(
            data: indexData as Data, primitiveType: primitiveType,
            primitiveCount: primitiveCount, bytesPerIndex: MemoryLayout<Int32>.size)
        
        return SCNGeometry(sources: [vertexSource], elements: [element])
    }
}

