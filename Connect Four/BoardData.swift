//
//  BoardData.swift
//  Connect Four
//
//  Created by Igor Zhariy on 3/28/17.
//  Copyright © 2017 Igor Zhariy. All rights reserved.
//

import UIKit

protocol BoardDataDelegate {
    func endGame()
    func switchPlayers()
}

class BoardData: NSObject {
    
    enum GameStatus {
        case new
        case inProgress
        case someoneWon
        case draw
    }
    
    var delegate: BoardDataDelegate?
    var gameStatus = GameStatus.new
    var items: Int = 0
    var rows: Int = 0
    var columns: Int = 0
    var tappedItemIndex: Int = 0
    var userTurn: Int = 1
    var boardState = [Int]()
    var winningIndexes = [Int]()
    var tappedItem = (row: 0,column: 0) {
        didSet {
            for row in (0 ..< rows).reversed() {
                tappedItemIndex = row * columns + tappedItem.column
                if boardState[tappedItemIndex] == 0 {
                    boardState[tappedItemIndex] = userTurn
                    break
                }
            }
            self.checkIfUserWon()
        }
    }
    
    init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
        self.items = rows * columns
        super.init()
        self.cleanBoard()
    }
    
    func cleanBoard() {
        gameStatus = .new
        boardState = Array(repeating: 0, count: items)
    }
    
    func updateUserTurn() {
        userTurn = userTurn == 2 ? 1 : 2
        delegate?.switchPlayers()
    }
    
    func checkIfUserWon() {
        print ("New tapped item")
        checkArray(array: getHorizontalLine())
        checkArray(array: getVerticalLine())
        checkArray(array: getDiagonalLine(reversed: false))
        checkArray(array: getDiagonalLine(reversed: true))
        switch gameStatus {
        case .someoneWon:
            print ("Player \(userTurn) won")
            delegate?.endGame()
        default:
            self.updateUserTurn()
        }
    }
    
    func getHorizontalLine() -> [Int] {
        let tappedItemIndexRow = tappedItemIndex / columns
        return Array(boardState[tappedItemIndexRow * columns ..< (tappedItemIndexRow + 1) * columns])
    }
    
    func getVerticalLine() -> [Int] {
        var array = [Int]()
        for row in 0 ..< rows {
            array.append(boardState[columns * row + tappedItem.column])
        }
        return array
    }
    
    func getDiagonalLine(reversed: Bool) -> [Int] {
        let firstBorder = reversed ? columns - 1 : 0
        let secondBorder = reversed ? 0 : columns - 1
        
        var firstDiagLineItemIndex = tappedItemIndex
        let directionIndex = reversed ? -1 : 1
        while firstDiagLineItemIndex - columns - directionIndex >= 0 && firstDiagLineItemIndex % columns != firstBorder {
            firstDiagLineItemIndex -= columns + directionIndex
        }
        var array = Array.init(arrayLiteral: boardState[firstDiagLineItemIndex])
        while firstDiagLineItemIndex + columns + directionIndex < boardState.count && firstDiagLineItemIndex % columns != secondBorder {
            firstDiagLineItemIndex += columns + directionIndex
            array.append(boardState[firstDiagLineItemIndex])
        }
        return array
    }
    
    func checkArray(array: [Int]) {
        print (array)
        guard array.count >= 4 else { return }
        for i in 0 ... array.count - 4 {
            if Set(array[i..<i+4]).count == 1 && array[i] != 0 {
                gameStatus = .someoneWon
                
            }
        }
    }
}
