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
    
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    let reuseIdentifier = "BoardCell"
    var boardSize = (rows: 6,columns: 7)
    var cellWidth = 0
    var boardData: BoardData?
    var keyboardShown = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        
        switch boardData!.boardState[indexPath.row] {
        case 1:
            cell.itemCircle.backgroundColor = UIColor.red
        case 2:
            cell.itemCircle.backgroundColor = UIColor.black
        default:
            cell.itemCircle.backgroundColor = UIColor.clear
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard boardData?.boardState[indexPath.row % boardSize.columns] == 0 else { return }
        boardData?.tappedItem = (indexPath.row / boardSize.columns, indexPath.row % boardSize.columns)
        boardCV.reloadItems(at: [IndexPath(row: boardData!.tappedItemIndex, section: 0)])
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
        newGameButton.isHidden = false
        boardCV.isUserInteractionEnabled = false
    }
    
    func switchPlayers() {
        playerOneLabel.isHidden = boardData?.userTurn != 1
        playerTwoLabel.isHidden = boardData?.userTurn != 2
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
    
    @IBAction func updateBoardSizeButtonTapped(_ sender: Any) {
        if (rowsTextField.text! != "" && columnsTextField.text! != "") {
            if (4 ... 10).contains(Int(rowsTextField.text!)!) && (4 ... 10).contains(Int(columnsTextField.text!)!)
            {
                boardSize = (Int(rowsTextField.text!)!, Int(columnsTextField.text!)!)
                changeBoardSize()
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
        playerOneLabel.text = "Player 1 Turn"
        playerOneLabel.backgroundColor = UIColor.clear
        playerTwoLabel.text = "Player 2 Turn"
        playerTwoLabel.backgroundColor = UIColor.clear
        playerOneLabel.isHidden = false
        playerTwoLabel.isHidden = true
    }
    
    func highlightWinner() {
        switch boardData!.userTurn {
        case 1:
            playerOneLabel.text = "Player 1 Won!"
            playerOneLabel.backgroundColor = UIColor.green
        default:
            playerTwoLabel.text = "Player 2 Won!"
            playerTwoLabel.backgroundColor = UIColor.green
        }
        
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


