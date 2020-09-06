import UIKit
import SceneKit

struct FaceParam {
    var offset = simd_float2()
    var speed = simd_float2()
    var direction = simd_float2()
    var imageSubset = Float()
    var maxOffset = Float()
    
    init() { randomize() }
    
    mutating func changeSpeed() {
        let maxSpeed:Float = 0.003
        speed.x = Float.random(in: 0.0005 ... maxSpeed)
        speed.y = Float.random(in: 0.0005 ... maxSpeed)
    }
    
    mutating func randomize() {
        imageSubset = Float.random(in: 0.01 ... 0.5)
        maxOffset = 1 - imageSubset
        
        offset.x = Float.random(in: 0 ..< maxOffset)
        offset.y = Float.random(in: 0 ..< maxOffset)
        direction.x = 1
        direction.y = 1
        
        changeSpeed()
        slide()
    }
    
    mutating func slide() {
        offset += speed * direction
        
        if offset.x < 0 { offset.x = 0; direction.x = -direction.x; changeSpeed() }
        if offset.x > maxOffset { offset.x = maxOffset; direction.x = -direction.x; changeSpeed() }
        
        if offset.y < 0 { offset.y = 0; direction.y = -direction.y; changeSpeed() }
        if offset.y > maxOffset { offset.y = maxOffset; direction.y = -direction.y; changeSpeed() }
    }
}

struct FaceData {
    var index = Int()
    var node:SCNNode! = nil
    
    func update() {
        node.geometry!.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Mult(
            SCNMatrix4MakeScale(faceParams[index].imageSubset, faceParams[index].imageSubset, 0),
            SCNMatrix4MakeTranslation(faceParams[index].offset.x,faceParams[index].offset.y,0) )
    }
}

struct PieceData {
    var position = SCNVector3()
    var face:[FaceData] = Array(repeating:FaceData(), count:6) // stickers
    
    mutating func initializeStickers(_ parentNode:SCNNode, _ parentIdent:Int) {
        func sticker(_ index:Int, _ angle:Float, _ rotate:simd_float3, _ translate:simd_float3) {
            let f = SCNPlane(width:pieceSize * 0.9, height:pieceSize * 0.9)
            f.firstMaterial?.diffuse.contents = picture
            
            face[index].index = parentIdent * 6 + index       // reference 6 faces assigned to piece
            face[index].node = SCNNode(geometry:f)
            face[index].node.transform = SCNMatrix4Mult(
                SCNMatrix4MakeRotation(angle, rotate.x,rotate.y,rotate.z),
                SCNMatrix4MakeTranslation(translate.x,translate.y,translate.z))
            
            parentNode.addChildNode(face[index].node)
        }
        
        let a:Float = Float.pi/2
        let q:Float = Float(pieceSize)/2+0.01
        
        sticker(0,a,    simd_float3(-1,0,0),simd_float3(0,+q,0))
        sticker(1,a,    simd_float3(+1,0,0),simd_float3(0,-q,0))
        sticker(2,a,    simd_float3(0,+1,0),simd_float3(+q,0,0))
        sticker(3,a,    simd_float3(0,-1,0),simd_float3(-q,0,0))
        sticker(4,a,    simd_float3(0,0,+1),simd_float3(0,0,+q))
        sticker(5,a*2,  simd_float3(+1,0,0),simd_float3(0,0,-q))
    }
    
    func update() { _ = face.map { $0.update() }}
    
    func contains(_ n:SCNNode) -> Bool {
        for f in face { if f.node == n { return true }}
        return false
    }

    func updatePicture() {
        _ = face.map { $0.node.geometry!.firstMaterial?.diffuse.contents = picture }
    }
}

class Piece {
    var ident = Int()
    var node:SCNNode! = nil  // piece body
    var pd = PieceData()

    var selected:Bool = false
    
    init(_ parent:SCNNode, ident:Int) {
        self.ident = ident
        
        let box = SCNBox(width:pieceSize, height:pieceSize, length:pieceSize, chamferRadius:CGFloat(0.02) )
        box.firstMaterial?.diffuse.contents = UIColor.darkGray

        node = SCNNode(geometry:box)
        parent.addChildNode(node)
        
        pd.initializeStickers(node,ident)
    }
    
    func update() { pd.update() }
    func updatePicture() { pd.updatePicture() }
    
    func contains(_ n:SCNNode) -> Bool {
        if node == n { return true }
        return pd.contains(n)
    }

    func select(_ onoff:Bool) {
        selected = onoff
        
        let m = SCNMaterial()
        m.diffuse.contents = selected ? UIColor.white : UIColor.darkGray
        node.geometry?.firstMaterial = m
    }
    
    func remove() {
        node.runAction(SCNAction.sequence([SCNAction.scale(to: 0, duration: 0.3)]), completionHandler: { () in
            self.node.removeFromParentNode()
            self.ident = NONE
        })
    }
}

