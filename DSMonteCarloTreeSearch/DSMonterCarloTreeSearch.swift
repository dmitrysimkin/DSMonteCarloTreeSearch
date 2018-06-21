//
//  MonterCarloTreeSearch.swift
//  MCTS
//
//  Created by Simkin Dmitry on 5/16/18.
//  Copyright © 2018 Simkin Dmitry. All rights reserved.
//

import Foundation


public typealias DSSearchResult = (nodes:[DSNode], bestNode:DSNode)

public class DSMonterCarloTreeSearch: NSObject {
    
    private var stopped = true
    
    private(set) var initialState: DSState
    public let root: DSNode
    
    public init(initialState state: DSState) {
        self.initialState = state
        self.root = DSNode(rootState: self.initialState)
    }
    
    public func start(timeFrame: DispatchTimeInterval, completion: @escaping (DSSearchResult) -> Void) {
        self.stopped = false
        DispatchQueue.global().async { [unowned self] in
            if self.root.wasVisited == false {
                self.root.expand()
            }
            self.iterate()
        }
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + timeFrame) { [weak self] in
            if let s = self {
                // do not call completion if search was already stopped
                let shouldCallCompletion = s.stopped == false
                if shouldCallCompletion {
                    s.stop()
                    let results = s.results()
                    DispatchQueue.main.async {
                        completion(results)
                    }
                }
            }
            
        }
    }
    
    public func stop() {
        self.stopped = true
    }
    
    func iterate() {
        guard self.stopped == false else {
            return
        }
        NSLog("MCTS: iterate")

        
        var currentNode = self.root
        repeat {
            autoreleasepool { () -> Void in
                if (currentNode.isLeaf) {
                    if (currentNode.wasVisited && currentNode.isTerminal == false) {
                        NSLog("MCTS: expanding node \(currentNode)")
                        currentNode.expand()
                        NSLog("MCTS: expanded")
                        let nextNode = currentNode.children.randomElement()!
                        currentNode = nextNode
                        NSLog("MCTS: next node is \(nextNode)")
                    } else {
                        let value = currentNode.simulate(againstState: self.root.state)
                        NSLog("MCTS: simulating node \(currentNode) - value: \(value)")
                        currentNode.backpropogate(value: value, visits: 1)
//                        currentNode.backpropogate(value: value, visits: 30)
                        currentNode = self.root
                        NSLog("MCTS: starting next iterationg from root node")
                    }
                } else {
                    NSLog("MCTS: cur node is not leaf, finding next node...")
                    let nextNode = self.findNextToVisit(fromNodes: currentNode.children)
                    currentNode = nextNode
                    NSLog("MCTS: next node is \(nextNode)")
                }
            }
        } while self.stopped == false
    }
    
    func findNextToVisit(fromNodes nodes:[DSNode]) -> DSNode {
        let notVisited = nodes.filter( { $0.visits == 0 })
        if notVisited.count > 0 {
            return notVisited.randomElement()!
        }
        
        var nextNode: DSNode!
        var maxValue = Double(Int.min)
        
        let _ = nodes.map { (node) -> Double in
            let ucb = self.ucb1(node, self.root)
            NSLog("MCTS: calculating UCB - \(ucb) for \(node.state.transition) - average value: \(node.averageValue), value: \(node.value), visits: \(node.visits)")
            return ucb
        }.sorted()
//        let ucbValues = nodes.map( { self.calculateUCB(node: $0) }).sorted()
//        NSLog("MCTS:: findNextToVisit: from values: \(ucbValues)\n")
        
        for node in nodes {
            let ucb = self.ucb1(node, self.root)
            if ucb > maxValue {
                maxValue = ucb
                nextNode = node
            }
        }
        NSLog("MCTS:: findNextToVisit: chosen: \(maxValue), \(nextNode.state.transition) - average value: \(nextNode.averageValue), value: \(nextNode.value), visits: \(nextNode.visits)\n")
        return nextNode
    }
    
    public var ucb1: (_ node:DSNode, _ rootNode:DSNode) -> Double = { (node, rootNode) in
        let value = Double(node.value / node.visits) + 2.0 * sqrt(log(Double(rootNode.visits)) / Double(node.visits))
        return value
    }
    
    // TODO: return all results for all possible moves
    // user have to decide what is best for him
    public func results() -> DSSearchResult {
        let children = self.root.children
        let sorted = children.sorted(by: { (left, right) -> Bool in
            return left.averageValue >= right.averageValue
        })
        NSLog("MCTS: results")
        NSLog("MCTS: all possible moves")
        for item in sorted {
            NSLog("MCTS: possible move: \(item.state.transition) - average value: \(item.averageValue), value: \(item.value), visits: \(item.visits)")
        }
        let max = sorted.first!
        let threshold = 0.1
        NSLog("MCTS: close moves to chose random from")
        let closeCondidates = children.filter { (n) -> Bool in
            let isClose = Double(abs(max.averageValue - n.averageValue)) < threshold || (max.averageValue == Double.infinity && n.averageValue == Double.infinity)
            return isClose
        }
//        for item in closeCondidates {
//            NSLog("MCTS: close move: \(item.state.transition) - average value: \(item.averageValue), value: \(item.value), visits: \(item.visits)")
//        }
        var resultNode = max
        if let close = closeCondidates.randomElement() {
            resultNode = close
        }
        NSLog("MCTS: result node: \(resultNode.state.transition) - average value: \(resultNode.averageValue), value: \(resultNode.value), visits: \(resultNode.visits)")
        NSLog("MCTS: root node: average value: \(self.root.averageValue), value: \(self.root.value), visits: \(self.root.visits)")
        NSLog("MCTS: end of results\n")
        return (sorted, resultNode)
    }
}
