import UIKit

class NewGameViewController: UIViewController {
    @IBOutlet var numberPieces: UISegmentedControl!
    @IBOutlet var numberMatching: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        numberPieces.selectedSegmentIndex = game.numberPieces - 3
        numberMatching.selectedSegmentIndex = (game.numberMatch - 2)/2
    }
    
    @IBAction func newGamePressed(_ sender: UIButton) {
        game.numberPieces = 3 + numberPieces.selectedSegmentIndex
        game.numberMatch = 2 + numberMatching.selectedSegmentIndex * 2
        game.newGame()
        cancelPressed(sender)
    }
    
    @IBAction func cancelPressed(_ sender: UIButton) {
        self.dismiss(animated:true, completion:nil)
    }
}
