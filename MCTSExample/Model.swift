//
//  Model.swift
//  MCTSExample
//
//  Created by Simkin Dmitry on 6/19/18.
//  Copyright © 2018 Simkin Dmitry. All rights reserved.
//

import Foundation
import DSMonteCarloTreeSearch

let TopLeftItemIndex = 0
let TopMiddleItemIndex = 1
let TopRightItemIndex = 2
let MiddleLeftItemIndex = 3
let MiddleMiddleItemIndex = 4
let MiddleRightItemIndex = 5
let BottomLeftItemIndex = 6
let BottomMiddleItemIndex = 7
let BottomRightItemIndex = 8

let AllItemIndexes = [TopLeftItemIndex, TopMiddleItemIndex, TopRightItemIndex,
                      MiddleLeftItemIndex, MiddleMiddleItemIndex, MiddleRightItemIndex,
                      BottomLeftItemIndex, BottomMiddleItemIndex, BottomRightItemIndex]

let TopIndexes = [TopLeftItemIndex, TopMiddleItemIndex, TopRightItemIndex]
let MiddleIndexes = [MiddleLeftItemIndex, MiddleMiddleItemIndex, MiddleRightItemIndex]
let BottomIndexes = [BottomLeftItemIndex, BottomMiddleItemIndex, BottomRightItemIndex]


typealias Combination = (Int, Int, Int)

let TopRowCombination = (TopLeftItemIndex, TopMiddleItemIndex, TopRightItemIndex)
let MiddleRowCombination = (MiddleLeftItemIndex, MiddleMiddleItemIndex, MiddleRightItemIndex)
let BottomRowCombination = (BottomLeftItemIndex, BottomMiddleItemIndex, BottomRightItemIndex)
// colums
let LeftColumnCombination = (TopLeftItemIndex, MiddleLeftItemIndex, BottomLeftItemIndex)
let MiddleColumnCombination = (TopMiddleItemIndex, MiddleMiddleItemIndex, BottomMiddleItemIndex)
let RightColumnCombination = (TopRightItemIndex, MiddleRightItemIndex, BottomRightItemIndex)
//diagonal
let TopLeftToBottomRightCombination = (TopLeftItemIndex, MiddleMiddleItemIndex, BottomRightItemIndex)
let TopRightToBottomLeftCombination = (TopRightItemIndex, MiddleMiddleItemIndex, BottomLeftItemIndex)



let FieldItemsCombinations: [Combination] = [
    TopRowCombination, MiddleRowCombination, BottomRowCombination,
    LeftColumnCombination, MiddleColumnCombination, RightColumnCombination,
    TopLeftToBottomRightCombination, TopRightToBottomLeftCombination
]


enum Value: Int, CustomStringConvertible {
    case X = 0
    case O = 1
    
    func opposite() -> Value {
        return self == .X ? .O : .X
    }
    
    var description: String {
        return self == .X ? "X" : "O"
    }
}


class TicTacToeTransition: DSTransition, CustomStringConvertible {
    let index: Int?
    let value: Value?
    
    init(index: Int?, value: Value?) {
        self.index = index
        self.value = value
    }
    
    var description: String {
        let indexStr = self.index == nil ? "-" : "\(self.index!)"
        let valueStr = self.value == nil ? "-" : "\(self.value!)"
        return "TicTacToeTransition: index - \(indexStr), value: - \(valueStr)"
    }
    
}


class TicTacToeState: DSState {
    let field: Field
    let whosTurn: Value
    
    init(transition: TicTacToeTransition, field: Field, whosTurn: Value) {
        self.field = field
        self.whosTurn = whosTurn
        super.init(transition: transition)
    }
    
    var ticTacToeTransition: TicTacToeTransition {
        get {
            return self.transition as! TicTacToeTransition
        }
    }
    
    override func possibleTransitions() -> [DSTransition] {
        let emptyItems = self.field.emptyItems()
        let transitions = emptyItems.map { (index) -> TicTacToeTransition in
            let transition = TicTacToeTransition(index: index, value: self.whosTurn)
            return transition
        }
        return transitions;
    }
    
    override func state(afterTransition transition:DSTransition) -> DSState {
        let ticTacToeTransition = transition as! TicTacToeTransition
        var field = self.field
        field.setValue(ticTacToeTransition.value!, at: ticTacToeTransition.index!)
        let state = TicTacToeState(transition: ticTacToeTransition, field: field, whosTurn: ticTacToeTransition.value!.opposite())
        return state
    }
    
    static func value(of field: Field, againstState: TicTacToeState) -> Int {
        let value: Int!
        switch field.state {
        case .determined(let v):
            value = v == againstState.ticTacToeTransition.value! ? 5 : -5
        case .draw:
            value = 2
        default:
            value = 0
        }
        return value
    }

    
    override func simulate(againstState state: DSState) -> Int {
        let againstState = state as! TicTacToeState
        if self.isTerminal {
            let value = TicTacToeState.value(of: self.field, againstState: againstState)
            return value;
        }
        
        var field = self.field
        
        var nextPlayingValue = self.whosTurn
        
        var result: Int!
        
//        NSLog("MCTSState: simulating starting from \n\(self.field)")
        
        repeat {
            let moves = field.emptyItems()
            assert(moves.count > 0)
            let move = moves.randomElement()!
            
            let oldState = field.state
            field.setValue(nextPlayingValue, at: move)
//            NSLog("MCTSState: moved to: [\(move.squareIndex), \(move.cellIndex)]")
//            if let squareStateChange = moveChange.squareStateChange {
//                NSLog("MCTSState: square with index changed: \(squareStateChange.0) to state: \(squareStateChange.1)]")
//            }
            let newState = field.state
            if oldState != newState {
//                NSLog("MCTSState: field state changed: to state: \(fieldStateChange)")
                result = TicTacToeState.value(of: field, againstState: againstState)
                break;
            }
            
            nextPlayingValue = nextPlayingValue.opposite()
        } while true
        
        return result;

    }
    override var isTerminal: Bool {
        get {
            let terminal = self.field.state != State.undetermined;
            return terminal;
        }
    }
    override func equalTo(rhs: DSState) -> Bool {
        var equal = false
        if let tttState = rhs as? TicTacToeState {
            equal = self.field == tttState.field && self.whosTurn == tttState.whosTurn
        }
        return equal
    }
}


enum State: Equatable {
    case undetermined
    case draw
    case determined(Value)
    
    static func == (lhs: State, rhs: State) -> Bool {
        switch (lhs, rhs) {
        case (let .determined(value1), let .determined(value2)):
            return value1 == value2
            
        case (.undetermined, .undetermined):
            return true
        case (.draw, .draw):
            return true
            
        default:
            return false
        }
    }
    
    public var isDetermined: Bool {
        get {
            switch self {
            case .determined(let value):
                let result = value == .X || value == .O
                return result;
            default:
                return false;
            }
        }
    }
}



struct Field: Equatable {
    var items: [Value?]
    var state: State
    
    init() {
        self.items = [Value?].init(repeating: nil, count: 9)
        self.state = .undetermined
    }
    
    mutating func setValue(_ value: Value, at index: Int) {
        var items = self.items
        items[index] = value
        self.items = items;
        let newState = self.evaluateItems(self.items)
        if (self.state != newState) {
            self.state = newState
        }
    }
    
    
    
    func emptyItems() -> [Int] {
        var emptyItems = [Int]()
        for (index, value) in self.items.enumerated() {
            if (value == nil) {
                emptyItems.append(index)
            }
        }
        return emptyItems;
    }
    
    func evaluateItems(_ items:[Value?]) -> State {
        var state = State.undetermined
        
        var drawCombinationsCount = 0
        for combination in FieldItemsCombinations {
            let combinationState = self.evaluateCombination(combination: combination, from: items)
            if combinationState.isDetermined {
                state = combinationState;
                break
            }
            if combinationState == .draw {
                drawCombinationsCount = drawCombinationsCount + 1
            }
        }
        
        if (drawCombinationsCount == FieldItemsCombinations.count) {
            state = .draw
        }
        
        return state;
    }
    
    func evaluateCombination(combination: Combination, from items:[Value?]) -> State {
        assert(items.count == 9)
        let indexes = [combination.0, combination.1, combination.2]
        let values = indexes.compactMap { items[$0] }
        
        func getSum() -> Int {
            let sum = values.reduce(0, { result, value in
                return result + value.rawValue
            })
            return sum;
        }
        
        var result: State!
        if (values.count == 3) {
            let sum = getSum()
            switch sum {
            case Value.X.rawValue * 3:
                result = .determined(.X)
            case Value.O.rawValue * 3:
                result = .determined(.O)
            default:
                result = .draw
            }
        } else if (values.count == 2) {
            let sum = getSum()
            if (sum % 2 == 1) {
                result = .draw
            } else {
                result = .undetermined
            }
        } else {
            result = .undetermined
        }
        return result;
    }
}


