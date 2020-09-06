import UIKit
import SceneKit

let NONE:Int = -1
let pieceSize:CGFloat = 1
let psize:CGFloat = pieceSize * 1.1

var pieces:[Piece] = []
var faceParams:[FaceParam] = []

class Game {
    var baseNode:SCNNode! = nil
    var numberPieces:Int = 4
    var numberMatch:Int = 2
    var maxPieces = Int()
    var selectedIndex = Int()
    var hintIndex = Int()
    var hintDurationCount = Int()
    var rotateFlag:Bool = false

    func initialize(_ parent:SCNNode) {
        baseNode = SCNNode(geometry:nil)
        parent.addChildNode(baseNode)
    }
    
    func newGame() {
        selectedIndex = NONE
        hintIndex = NONE
        
        _ = pieces.map { $0.node.removeFromParentNode() }
        pieces.removeAll()
        faceParams.removeAll()
        
        // ensure #pieces defined is evenly divisible by the numberMatch setting
        maxPieces = (numberPieces * numberPieces * numberPieces / numberMatch) * numberMatch
        
        // allocate, assign paired idents --------------
        var index:Int = 0
        for ident in stride(from:0, to:maxPieces, by:numberMatch) {     // allocate pieces in groups of matching idents
            for _ in 0 ..< numberMatch {                                // #pieces in the current group
                pieces.append(Piece(baseNode, ident:ident))             // define a piece
                for _ in 0 ..< 6 { faceParams.append(FaceParam()) }     // and companion data for its 6 faces
                
                index += 1
            }
        }
        
        shuffleLayout(false)
    }
    
    func rotatePosition(_ pos:simd_float3, _ axis:Int, _ angle:Float) -> simd_float3 {
        let ss:Float = sin(angle)
        let cc:Float = cos(angle)
        var qt = Float()
        var pos = pos
        
        switch(axis) {
        case 0 :    // XY
            qt = pos.x
            pos.x = pos.x * cc - pos.y * ss
            pos.y =    qt * ss + pos.y * cc
        case 1 :    // XZ
            qt = pos.x
            pos.x = pos.x * cc - pos.z * ss
            pos.z =    qt * ss + pos.z * cc
        case 2 :    // YZ
            qt = pos.y
            pos.y = pos.y * cc - pos.z * ss
            pos.z =    qt * ss + pos.z * cc
        default : break
        }
        
        return pos
    }
    
    var shuffleStyle:Int = 0
    
    func shuffleLayout(_ alterShuffleStyle:Bool) {
        pieces.shuffle()
        
        switch shuffleStyle {
        case 0 :
            
            // squash down to smallest cube ---------------------
            var count:Int = 0
            var dimension:Int = 0
            for i in 0 ..< pieces.count {
                if pieces[i].ident != NONE { count += 1 }
            }
            while true {
                if dimension * dimension * dimension >= count { break }
                dimension += 1
            }
            
            var n:Int = 0
            let offset:CGFloat = psize

            _ = pieces.map {
                if $0.ident != NONE {
                    var x:Int = n
                    let y:Int = x % dimension;  x /= dimension
                    let z:Int = x % dimension;  x /= dimension
                    $0.node.position = SCNVector3(CGFloat(x - dimension) * offset, CGFloat(y - dimension) * offset, CGFloat(z - dimension) * offset)
                    n += 1
                }
            }
        case 1 :
            var n:Int = 0
            
            for i in 0 ..< pieces.count {
                if pieces[i].ident == NONE { continue }
                var x:Int = n
                let y:Int = x % numberPieces;  x /= numberPieces
                let z:Int = x % numberPieces;  x /= numberPieces
                let offset:CGFloat = psize * 1.5
                let stagger:CGFloat = (i & 1) == 0 ? offset/6 : -offset/6
                pieces[i].node.position = SCNVector3(stagger + CGFloat(x) * offset, stagger + CGFloat(y) * offset, CGFloat(z) * offset)
                n += 1
            }
        case 2 :
            var angle1:Float = 0
            var angle2:Float = 0
            var radius = Float(psize * 3)
            
            for i in 0 ..< pieces.count {
                if pieces[i].ident == NONE { continue }
                var pos = simd_float3(radius,0,0)
                pos = rotatePosition(pos,0,angle1)
                pos = rotatePosition(pos,1,angle2)
                angle1 += 0.2
                angle2 += 1
                radius += 0.02
                pieces[i].node.position = SCNVector3(CGFloat(pos.x),CGFloat(pos.y),CGFloat(pos.z))
            }
        default : break
        }
        
        if alterShuffleStyle {
            shuffleStyle += 1
            if shuffleStyle > 2 { shuffleStyle = 0 }
        }
        
        centerOfGravity(false)
    }
    
    //MARK: -
    
    var hintIdents:[Int] = []
    
    func hint() {
        func isActiveIdent(_ ident:Int) -> Bool {
            for p in pieces { if p.ident == ident { return true }}
            return false
        }
        
        hintIdents.removeAll()
        _ = pieces.map { $0.select(false) }
        
        for i in 0 ..< 216/2 {   // #idents in 6x6x6 by twos
            if isActiveIdent(i) { hintIdents.append(i) }
        }
        
        hintDurationCount = 0
        hintIndex = NONE
        if hintIdents.count > 0 { hintIndex = 0 }
    }
    
    func update() {
        if rotateFlag { baseNode.runAction(SCNAction.rotateBy(x: 0.005, y: 0.003, z: 0, duration: 0.0)) }
        
        for i in 0 ..< faceParams.count { faceParams[i].slide() }
        _ = pieces.map { $0.update() }
 
        // hint session in process? -----------------------------------
        if hintIndex != NONE {
            var displayCurrentHint:Bool = hintDurationCount == 0  // not displaying a hint right now
            
            if hintDurationCount > 0 {  // waiting for display of current hint to expire
                hintDurationCount -= 1
                if hintDurationCount == 0 { // has expired
                    _ = pieces.map { $0.select(false) } // turn off hint display
                    hintIndex += 1
                    if(hintIndex >= hintIdents.count) { hintIndex = NONE } else { displayCurrentHint = true }
                }
            }
            
            if displayCurrentHint {
                _ = pieces.map { if $0.ident == hintIdents[hintIndex] { $0.select(true) }}
                hintDurationCount = 10  // reset display duration counter
            }
        }
    }
    
    func updatePicture() { _ = pieces.map { $0.updatePicture() }}
    
    func tappedNode(_ node:SCNNode) {
        
        if hintIndex != NONE { return } // busy showing hints
        
        for i in 0 ..< pieces.count {
            if pieces[i].contains(node) {
                if selectedIndex == NONE {
                    pieces[i].select(true)
                    selectedIndex = i
                    return
                }
                
                for i in 0 ..< pieces.count {
                    pieces[i].select(false)
                }
                
                if (i != selectedIndex) && (pieces[i].ident == pieces[selectedIndex].ident) {
                    pieces[i].remove()
                    pieces[selectedIndex].remove()
                    centerOfGravity(true)
                }
                selectedIndex = NONE
            }
        }
    }
    
    func centerOfGravity(_ animate:Bool) {
        if pieces.count < 2 { return }
        
        var center = SCNVector3()
        _ = pieces.map { if $0.ident != NONE { center.add($0.node.position) }}
        center.divide(Float(pieces.count))
        
        _ = pieces.map {
            var newPos = $0.node.position
            newPos.subtract(center)
            
            if animate {
                let move = SCNAction.move(to:newPos, duration:0.2)
                move.timingMode = .easeInEaseOut
                let sequence = SCNAction.sequence([move])
                $0.node!.runAction(sequence, completionHandler: nil)
            }
            else {
                $0.node.position = newPos
            }
        }
    }
}

extension SCNVector3 {
    mutating func add(_ v:SCNVector3) {
        self.x += v.x
        self.y += v.y
        self.z += v.z
    }
    
    mutating func subtract(_ v:SCNVector3) {
        self.x -= v.x
        self.y -= v.y
        self.z -= v.z
    }
    
    mutating func divide(_ den:Float) {
        if den != 0 {
            self.x /= den
            self.y /= den
            self.z /= den
        }
    }
}





