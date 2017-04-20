//
//  ViewController.swift
//  Connect Four
//
//  Created by Igor Zhariy on 3/22/17.
//  Copyright © 2017 Igor Zhariy. All rights reserved.
//

import UIKit

class BoardViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var playerOneLabel: UILabel!
    @IBOutlet weak var playerTwoLabel: UILabel!
    @IBOutlet weak var newGameButton: UIButton!
    @IBOutlet weak var boardCV: UICollectionView!
    @IBOutlet weak var rowsTextField: UITextField!
    @IBOutlet weak var columnsTextField: UITextField!
    @IBOutlet weak var updateBoardSizeButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var playerSelectionSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    let reuseIdentifier = "BoardCell"
    let userDefaults = UserDefaults.standard
    var boardSize = (rows: 6,columns: 7)
    var cellWidth = 0
    var boardData: BoardData?
    var keyboardShown = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let savedBoardSize = userDefaults.object(forKey: "savedBoardSize") as? [String : Int] {
            boardSize = (savedBoardSize["rows"]!, savedBoardSize["columns"]!)
        }
        
        boardData = BoardData(rows: boardSize.rows, columns: boardSize.columns)
        boardData?.delegate = self
        setupVisuals()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyBoardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyBoardDidHide), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidHide, object: nil)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return boardSize.rows * boardSize.columns
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BoardCell
        cell.itemCircle.layer.cornerRadius = CGFloat(cellWidth - 4) / 2
        
        switch boardData!.boardState[indexPath.row / boardSize.columns][indexPath.row % boardSize.columns] {
        case 1:
            cell.itemCircle.backgroundColor = UIColor.red
        case 2:
            cell.itemCircle.backgroundColor = UIColor.black
        case 3:
            cell.itemCircle.backgroundColor = UIColor.green
        default:
            cell.itemCircle.backgroundColor = UIColor.clear
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard boardData?.boardState[0][indexPath.row % boardSize.columns] == 0 else { return }
        boardData?.tappedItem = (indexPath.row / boardSize.columns, indexPath.row % boardSize.columns)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellWidth, height: cellWidth)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let leftOvers = CGFloat(Int(view.frame.size.width) - cellWidth * boardSize.columns)
        return UIEdgeInsetsMake(0, leftOvers / 2, 0, leftOvers / 2)
    }
}

extension BoardViewController: BoardDataDelegate {
        
    func endGame() {
        highlightWinner()
        showWinningCombination()
        newGameButton.setTitle("New Game", for: .normal)
        boardCV.isUserInteractionEnabled = false
    }
    
    func draw() {
        playerOneLabel.isHidden = true
        playerTwoLabel.isHidden = true
        newGameButton.setTitle("Draw. Restart?", for: .normal)
        boardCV.isUserInteractionEnabled = false
    }
    
    func switchPlayers() {
        playerSelectionSegmentedControl.isHidden = true
        newGameButton.isHidden = false
        playerOneLabel.isHidden = boardData?.userTurn != 1
        playerTwoLabel.isHidden = boardData?.userTurn != 2
    }
    
    func reloadItem() {
        boardCV.reloadItems(at: [IndexPath(row: boardData!.tappedItemIndex, section: 0)])
    }
    
    func makeTurnAI(column: Int) {
        boardCV.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
            self.collectionView(self.boardCV, didSelectItemAt: IndexPath.init(row: column, section: 0))
            self.boardCV.isUserInteractionEnabled = true
        }
    }
    
    func changeBoardSize() {
        boardData?.rows = boardSize.rows
        boardData?.columns = boardSize.columns
        boardData?.items = boardSize.rows * boardSize.columns
        boardData?.cleanBoard()
        boardData?.userTurn = 1
        setupCellSize()
        resetGame()
        boardCV.reloadData()
    }
    
    
}

extension BoardViewController {
    
    
    @IBAction func newGameButtonTapped(_ sender: Any) {
        resetGame()
        boardData?.cleanBoard()
        boardCV.reloadData()
        boardCV.isUserInteractionEnabled = true
    }
    
    
    @IBAction func playerSelectionSegmentedControlChanged(_ sender: Any) {
        boardCV.selectItem(at: IndexPath.init(row: 3, section: 0), animated: true, scrollPosition: .top)
        boardData?.gamingVersusAI = playerSelectionSegmentedControl.selectedSegmentIndex == 0
    }
    
    @IBAction func updateBoardSizeButtonTapped(_ sender: Any) {
        if (rowsTextField.text! != "" && columnsTextField.text! != "") {
            if (4 ... 10).contains(Int(rowsTextField.text!)!) && (4 ... 10).contains(Int(columnsTextField.text!)!)
            {
                let rows = Int(rowsTextField.text!)!
                let columns = Int(columnsTextField.text!)!
                boardSize = (rows, columns)
                let savedBoardSize = ["rows" : rows, "columns" : columns]
                changeBoardSize()
                userDefaults.set(savedBoardSize, forKey: "savedBoardSize")
                userDefaults.synchronize()
                self.view.endEditing(true)
            } else {
                let alert = UIAlertController(title: "Info", message: "Rows and columns should be no less than 4 and more than 10", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        } else {
            let alert = UIAlertController(title: "Info", message: "Please enter number of rows and columns first", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        
    }
    
    func setupCellSize() {
        cellWidth = min(Int(view.frame.width) / boardSize.columns, Int(boardCV.frame.height) / boardSize.rows, Int(boardCV.frame.width) / boardSize.columns)
    }
    
    func setupVisuals() {
        setupCellSize()
        resetLabelColors()
        playerOneLabel.layer.cornerRadius = 5
        playerOneLabel.layer.masksToBounds = true
        playerTwoLabel.layer.cornerRadius = 5
        playerTwoLabel.layer.masksToBounds = true
        newGameButton.layer.cornerRadius = 5
        newGameButton.layer.borderWidth = 1
        newGameButton.layer.borderColor = newGameButton.tintColor.cgColor
        newGameButton.layer.backgroundColor = newGameButton.tintColor.cgColor
        newGameButton.setTitleColor(UIColor.white, for: .normal)
        
        self.view.backgroundColor = UIColor.init(colorLiteralRed:0.998, green: 0.995, blue: 0.686, alpha: 1.00)
        boardCV.backgroundColor = UIColor.init(colorLiteralRed:0.998, green: 0.995, blue: 0.686, alpha: 1.00)
        
        let flow = boardCV.collectionViewLayout as! UICollectionViewFlowLayout
        flow.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        flow.minimumLineSpacing = 0
        flow.minimumInteritemSpacing = 0
        boardCV.setCollectionViewLayout(flow, animated: false)
    }
    
    func resetGame() {
        newGameButton.isHidden = true
        playerSelectionSegmentedControl.isHidden = false
        newGameButton.setTitle("Restart Game", for: .normal)
        playerOneLabel.text = "Player 1 Turn"
        playerOneLabel.isHidden = false
        playerTwoLabel.text = "Player 2 Turn"
        playerTwoLabel.isHidden = true
        resetLabelColors()
    }
    
    func resetLabelColors() {
        playerOneLabel.textColor = UIColor.white
        playerOneLabel.backgroundColor = UIColor.red
        playerTwoLabel.textColor = UIColor.white
        playerTwoLabel.backgroundColor = UIColor.black
    }
    
    func highlightWinner() {
        switch boardData!.userTurn {
        case 1:
            playerOneLabel.text = "Player 1 Won!"
            playerOneLabel.textColor = UIColor.red
            playerOneLabel.backgroundColor = UIColor.green
        default:
            playerTwoLabel.text = "Player 2 Won!"
            playerTwoLabel.textColor = UIColor.black
            playerTwoLabel.backgroundColor = UIColor.green
        }
    }
    
    func showWinningCombination() {
        boardData!.winningPositions.forEach( {
            let row = $0.0 * boardSize.columns + $0.1
            boardCV.reloadItems(at: [IndexPath(row: row, section: 0)])
        } )
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func keyBoardDidShow(notification: Notification) {
        if !keyboardShown {
            adjustHeight(show: true, notification: notification)
        }
        keyboardShown = true
    }
    
    func keyBoardDidHide(notification: Notification) {
        if keyboardShown {
            adjustHeight(show: false, notification: notification)
        }
        keyboardShown = false
    }
    
    func adjustHeight(show:Bool, notification:Notification) {
        let info = notification.userInfo as NSDictionary?
        let rectValue = info![UIKeyboardFrameBeginUserInfoKey] as! NSValue
        let animationDuration = info![UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
        let changeInHeight = (rectValue.cgRectValue.size.height) * (show ? 1 : -1)
        
        UIView.animate(withDuration: animationDuration, animations: { () -> Void in
            self.topConstraint.constant -= changeInHeight
            self.bottomConstraint.constant += changeInHeight
        })
    }

}

extension BoardViewController: UITextViewDelegate {
    
    func textViewDidEndEditing(_ textView: UITextView) {
        self.view.endEditing(true)
    }
    
}

class BoardCell: UICollectionViewCell {
    @IBOutlet weak var itemCircle: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.contentView.layer.borderColor = UIColor.lightGray.cgColor
        self.contentView.layer.borderWidth = 0.5
    }
}


