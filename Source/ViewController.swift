import UIKit
import QuartzCore
import SceneKit

var scenePtr:SCNScene!
var sceneView:SCNView!
var cameraNode:SCNNode!

var game = Game()
var picture:CGImage! = nil

class ViewController: UIViewController,SCNSceneRendererDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var light:SCNNode!
    var lightAngle:Float = 0
    @IBOutlet var scnView: SCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scenePtr = SCNScene()        
        sceneView = self.scnView
        sceneView.backgroundColor = UIColor.blue
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true
        sceneView.delegate = self
        sceneView.scene = scenePtr
        
        let camera = SCNCamera()
        cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.transform = SCNMatrix4Mult(SCNMatrix4MakeRotation(-Float.pi/2, 1,0,0), SCNMatrix4MakeTranslation(0,30,0))
        scenePtr.rootNode.addChildNode(cameraNode)
      
        // Skybox -----------------------------
        var sb:[UIImage] = []
        for s in [ "rt.png","lf.png","up.png","dn.png","bk.png","ft.png" ] { sb.append(UIImage.init(named:s)!) }
        scenePtr.background.contents = SCNMaterialProperty(contents:sb).contents

        let image = UIImage(named:"Mandelbrot.png")
        picture = image?.cgImage
        
        game.initialize(scenePtr.rootNode)
        game.newGame()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        Timer.scheduledTimer(withTimeInterval:0.03, repeats:true) { timer in game.update() }
    }
    
    @IBOutlet var rotateButton: UIButton!
    @IBAction func rotatePressed(_ sender: UIButton) {
        game.rotateFlag = !game.rotateFlag
        rotateButton.setTitleColor(game.rotateFlag ? .red : .white, for: .normal)
    }
    
    @IBAction func shuffle(_ sender: UIButton) { game.shuffleLayout(true) }
    @IBAction func hint(_ sender: UIButton) { game.hint() }
    
    @IBAction func selectPhoto(_ sender: UIButton) {
        let pickerController = UIImagePickerController()
        pickerController.sourceType = .photoLibrary
        pickerController.delegate = self
        self.present(pickerController, animated: true, completion: {
        })
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            picture = pickedImage.cgImage
            game.updatePicture()
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: false, completion: nil)
    }
    
    @objc func timerHandler() {
        game.update()
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        
        for i in 0 ..< hitResults.count {
            game.tappedNode(hitResults[i].node)
            return
        }
    }
    
    override var shouldAutorotate: Bool { return true }
    override var prefersStatusBarHidden: Bool { return true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .all }
}
