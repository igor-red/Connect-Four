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
    func draw()
    func switchPlayers()
    func reloadItem()
    func makeTurnAI(column: Int)
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
    var gamingVersusAI = true
    var winningPositions = [(Int, Int)]()
    var possibleTurnPositions = [(Int, Int)]()
    var loosingThreatPosition: (Int, Int) = (-1, -1)
    var winningOpportunityPosition: (Int, Int) = (-1, -1)
    var tappedItem = (row: 0,column: 0) {
        didSet {
            for row in (0 ..< rows).reversed() {
                if boardState[row][tappedItem.column] == 0 {
                    tappedItem.row = row
                    boardState[row][tappedItem.column] = userTurn
                    tappedItemIndex = row * columns + tappedItem.column
                    delegate?.reloadItem()
                    break
                }
            }
            possibleTurnPositions = getPossibleTurnPositions()
            if !self.checkIfAnyoneWon() {
                if gamingVersusAI && userTurn == 2 {
                    self.checkIfThreatOpportunity()
                    self.makeTurnAI()
                }
            }
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
        loosingThreatPosition = (-1, -1)
        winningOpportunityPosition = (-1, -1)
        userTurn = 1
        winningPositions.removeAll()
        boardState = Array(repeatElement(Array(repeating: 0, count: columns), count: rows))
    }
    
    func updateUserTurn() {
        userTurn = userTurn == 2 ? 1 : 2
        delegate?.switchPlayers()
    }
    
    func checkIfAnyoneWon() -> Bool {
        if possibleTurnPositions.count == 0 { gameStatus = .draw }
        let tappedItemLocation = (tappedItem.row, tappedItem.column)
        checkWinningPosition(arrayOfPositions: getHorizontalLine(fromLocation: tappedItemLocation))
        checkWinningPosition(arrayOfPositions: getVerticalLine(fromLocation: tappedItemLocation))
        checkWinningPosition(arrayOfPositions: getDiagonalLine(fromLocation: tappedItemLocation, reversed: false))
        checkWinningPosition(arrayOfPositions: getDiagonalLine(fromLocation: tappedItemLocation, reversed: true))
        switch gameStatus {
        case .someoneWon:
            delegate?.endGame()
            return true
        case .draw:
            delegate?.draw()
            return true
        default:
            self.updateUserTurn()
            return false
        }
    }
    
    func checkIfThreatOpportunity() {
        loosingThreatPosition = (-1, -1)
        winningOpportunityPosition = (-1, -1)
        possibleTurnPositions.forEach({ position in
            checkThreatOpportunityPosition(arrayOfPositions: getHorizontalLine(fromLocation: (position.0, position.1)))
            checkThreatOpportunityPosition(arrayOfPositions: getVerticalLine(fromLocation: (position.0, position.1)))
            checkThreatOpportunityPosition(arrayOfPositions: getDiagonalLine(fromLocation: (position.0, position.1), reversed: false))
            checkThreatOpportunityPosition(arrayOfPositions: getDiagonalLine(fromLocation: (position.0, position.1), reversed: true))
        })
    }
    
    func makeTurnAI() {
        var column = -1
        if loosingThreatPosition != (-1, -1) && winningOpportunityPosition == (-1, -1) { column = loosingThreatPosition.1 }
        if winningOpportunityPosition != (-1, -1) && winningOpportunityPosition != (-1, -1) { column = winningOpportunityPosition.1 }
        if column == -1 { column = generateRandomColumn() }
        delegate?.makeTurnAI(column: column)
    }
    
    func generateRandomColumn() -> Int {
        var possibleColumn = -1
        var columnGenerated = false
        while !columnGenerated {
            possibleColumn = Int(arc4random_uniform(UInt32(columns)))
            possibleTurnPositions.forEach({ if possibleColumn == $0.1 { columnGenerated = true } })
        }
        return possibleColumn
    }
    
    func getHorizontalLine(fromLocation: (row: Int, column: Int)) -> [(Int, Int)] {
        return Array(zip(Array.init(repeating: fromLocation.row, count: columns), (0 ..< columns).map { $0 }))
    }
    
    func getVerticalLine(fromLocation: (row: Int, column: Int)) -> [(Int, Int)] {
        return Array(zip((0 ..< rows).map { $0 }, Array.init(repeating: fromLocation.column, count: rows) ))
    }
    
    func getDiagonalLine(fromLocation: (row: Int, column: Int), reversed: Bool) -> [(Int, Int)] {
        
        let reversedIndex = reversed ? -1 : 1
        let firstBorder = reversed ? columns - 1 : 0
        let secondBorder = reversed ? 0 : columns - 1
        var firstItemPosition = (row : fromLocation.row, column: fromLocation.column)
        
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
    
    func getPossibleTurnPositions() -> [(Int, Int)] {
        var array = [(Int, Int)]()
        for column in 0 ..< columns {
            for row in (0 ..< rows).reversed() {
                if boardState[row][column] == 0 {
                    array.append((row, column))
                    break
                }
            }
        }
        return array
    }
    
    func checkWinningPosition(arrayOfPositions: [(row: Int, column: Int)]) {
        var arrayOfItems = [Int]()
        arrayOfPositions.forEach( { arrayOfItems.append(boardState[$0.row][$0.column]) } )
        
        guard arrayOfItems.count >= 4 else { return }
        for i in 0 ... arrayOfItems.count - 4 {
            if Set(arrayOfItems[i ..< i + 4]).count == 1 && arrayOfItems[i] != 0 {
                gameStatus = .someoneWon
                winningPositions = Array(arrayOfPositions[i ..< i + 4])
                winningPositions.forEach({ boardState[$0.0][$0.1] = 3 })
            }
        }
    }
    
    func checkThreatOpportunityPosition(arrayOfPositions: [(row: Int, column: Int)]) {
        var arrayOfItems = [Int]()
        arrayOfPositions.forEach( { arrayOfItems.append(boardState[$0.row][$0.column]) } )
        
        guard arrayOfItems.count >= 4 else { return }
        for i in 0 ... arrayOfItems.count - 4 {
            if arrayOfItems[i ..< i + 4] == [0, 1, 1, 1] { loosingThreatPosition = arrayOfPositions[i] }
            if arrayOfItems[i ..< i + 4] == [1, 0, 1, 1] { loosingThreatPosition = arrayOfPositions[i + 1] }
            if arrayOfItems[i ..< i + 4] == [1, 1, 0, 1] { loosingThreatPosition = arrayOfPositions[i + 2] }
            if arrayOfItems[i ..< i + 4] == [1, 1, 1, 0] { loosingThreatPosition = arrayOfPositions[i + 3] }
            if arrayOfItems[i ..< i + 4] == [0, 2, 2, 2] { winningOpportunityPosition = arrayOfPositions[i] }
            if arrayOfItems[i ..< i + 4] == [2, 0, 2, 2] { winningOpportunityPosition = arrayOfPositions[i + 1] }
            if arrayOfItems[i ..< i + 4] == [2, 2, 0, 2] { winningOpportunityPosition = arrayOfPositions[i + 2] }
            if arrayOfItems[i ..< i + 4] == [2, 2, 2, 0] { winningOpportunityPosition = arrayOfPositions[i + 3] }
        }
    }
}
