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
    var boardState = [[Int]]()
    var winningIndexes = [(Int, Int)]()
    var tappedItem = (row: 0,column: 0) {
        didSet {
            for row in (0 ..< rows).reversed() {
                tappedItemIndex = row * columns + tappedItem.column
                if boardState[row][tappedItem.column] == 0 {
                    tappedItem.row = row
                    boardState[row][tappedItem.column] = userTurn
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
        userTurn = 1
        winningIndexes.removeAll()
        boardState = Array(repeatElement(Array(repeating: 0, count: columns), count: rows))
    }
    
    func updateUserTurn() {
        userTurn = userTurn == 2 ? 1 : 2
        delegate?.switchPlayers()
    }
    
    func checkIfUserWon() {
        //print ("New tapped item")
        checkArray(arrayOfPositions: getHorizontalLine())
        checkArray(arrayOfPositions: getVerticalLine())
        checkArray(arrayOfPositions: getDiagonalLine(reversed: false))
        checkArray(arrayOfPositions: getDiagonalLine(reversed: true))
        switch gameStatus {
        case .someoneWon:
            //print ("Player \(userTurn) won")
            delegate?.endGame()
        default:
            self.updateUserTurn()
        }
    }
    
    func getHorizontalLine() -> [(Int, Int)] {
        return Array(zip(Array.init(repeating: tappedItem.row, count: columns), (0 ..< columns).map { $0 }))
    }
    
    func getVerticalLine() -> [(Int, Int)] {
        return Array(zip((0 ..< rows).map { $0 }, Array.init(repeating: tappedItem.column, count: rows) ))
    }
    
    func getDiagonalLine(reversed: Bool) -> [(Int, Int)] {
        
        let reversedIndex = reversed ? -1 : 1
        let firstBorder = reversed ? columns - 1 : 0
        let secondBorder = reversed ? 0 : columns - 1
        var firstItemPosition = (row : tappedItem.row, column: tappedItem.column)
        
        while firstItemPosition.row != 0 && firstItemPosition.column != firstBorder {
            firstItemPosition.row -= 1
            firstItemPosition.column -= reversedIndex
        }
        var array = Array.init(arrayLiteral: (firstItemPosition.row,firstItemPosition.column))
        while firstItemPosition.row < rows - 1 && firstItemPosition.column != secondBorder {
            firstItemPosition.row += 1
            firstItemPosition.column += reversedIndex
            array.append((firstItemPosition.row, firstItemPosition.column))
        }
        return array
    }
    
    func checkArray(arrayOfPositions: [(row: Int, column: Int)]) {
        //print (arrayOfPositions)
        var arrayOfItems = [Int]()
        arrayOfPositions.forEach( { arrayOfItems.append(boardState[$0.row][$0.column]) } )
        
        //print (arrayOfItems)
        guard arrayOfItems.count >= 4 else { return }
        for i in 0 ... arrayOfItems.count - 4 {
            if Set(arrayOfItems[i ..< i + 4]).count == 1 && arrayOfItems[i] != 0 {
                gameStatus = .someoneWon
                winningIndexes = Array(arrayOfPositions[i ..< i + 4])
                winningIndexes.forEach( { boardState[$0.0][$0.1] = 3 } )
            }
        }
    }
}
