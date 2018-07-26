//
//  MonterCarloTreeSearch.swift
//  MCTS
//
//  Created by Simkin Dmitry on 5/16/18.
//  Copyright © 2018 Simkin Dmitry. All rights reserved.
//

import Foundation

/// Result of the Monte Carlo Tree Search
/// - nodes: all (possible) nodes storing result of the search (visits, value, average value)
/// - best node: node is considered as best out of all possible nodes when it has max 'average value'
public typealias DSSearchResult = (nodes:[DSNode], bestNode:DSNode)


/// Main Class that implemets Monte Carlo Tree Search
public class DSMonterCarloTreeSearch: NSObject {
    
    /// Root node of the tree
    public var root: DSNode { get {
        return _rootNode;
        }
    }
    
    /// Designated initializer
    ///
    /// - parameters:
    ///    - initialState: state to start search from
    public init(initialState state: DSState) {
        self._rootNode = DSNode(rootState: state)
    }
    
    /// Updates root node. Usefull to reuse data from previous searches
    ///
    /// - parameters:
    ///    - node: node to be new root node of the search tree
    public func updateRootState(_ state: DSState) {
        if let node = self.findNode(by: state) {
            self._rootNode = node;
        } else {
            self._rootNode = DSNode(rootState: state)
        }
    }
    
    /// Starts search asynchronously from root node and fires back after 'time frame'
    /// - parameters:
    ///    - timeFrame: a time frame algorithm to operate
    ///    - completion: completion to call back with search result
    public func start(timeFrame: DispatchTimeInterval, completion: @escaping (DSSearchResult?) -> Void) {
        self.stopped = false
        DispatchQueue.global().async { [weak self] in
            self?.iterate()
        }
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + timeFrame) { [weak self] in
            if let s = self {
                // do not call completion if search was already stopped
                if s.stopped == false {
                    s.stop()
                    let results = s.results()
                    DispatchQueue.main.async {
                        completion(results)
                    }
                }
            }
        }
    }
    
    public func start(iterationsCount: UInt, completion: @escaping (DSSearchResult?) -> Void) {
        self.stopped = false
        DispatchQueue.global().async { [weak self] in
            self?.iterate(iterationsCount: iterationsCount, completion: { [weak self] in
                if let s = self {
                    s.stop()
                    let results = s.results()
                    DispatchQueue.main.async {
                        completion(results)
                    }
                }
            })
        }
    }
    
    var stopped = true
    
    /// Stops search
    public func stop() {
        self.stopped = true
    }
    
    /// UCB1 formula. Used at 'selection' step of the algorithm. Node that maximizes this value is choosen for next iteration.
    /// By default UCB1 is calculated with formula: Double(node.value / node.visits) + 2.0 * sqrt(log(Double(rootNode.visits)) / Double(node.visits))
    ///
    /// - parameters
    ///   - node: node for which to calculate UCB1 value
    ///   - rootNode: root node of the tree, might be used to get total number of visits or other parameters
    /// - returns: UCB1 value
    public var ucb1: (_ node:DSNode, _ rootNode:DSNode) -> Double = { (node, rootNode) in
        let value = Double(node.value / node.visits) + 2.0 * sqrt(log(Double(rootNode.visits)) / Double(node.visits))
        return value
    }
    /// Flag that contols 'Backpropagation' step behaviour and says whether negative value ('value = value * -1') should be passed to parent node on each iteration up to root node.
    /// For example, if set to 'true' and in case of tree 'root -> node_level1 -> node_level2' when backpropogating 'node_level2' with value '-2',
    /// 'node_level1' will be update with value '2' and 'root' - with value -2.
    /// Setting to 'true' might be the case for two players games.
    /// Default is 'false'.
    public var shouldChangeValueSignDuringBackpropagation = false
    
    /// Returns results that algorithm produces up to this point
    public func results() -> DSSearchResult? {
        guard self.root.children.count > 0 else {
            return nil;
        }
        
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
            let isClose = Double(abs(max.averageValue - n.averageValue)) < threshold
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

    
    
    // MARK - Internal
    
    var _rootNode: DSNode
    
    func iterate(iterationsCount: UInt? = nil, completion: (() -> Void)? = nil) {
        guard self.stopped == false else {
            return
        }
        if iterationsCount != nil && iterationsCount! <= 0 {
            return
        }
        NSLog("MCTS: iterate")
        
        if self.root.wasExpanded == false {
            self.root.expand()
        }
        
        var iterationsLeft = iterationsCount ?? UInt.max
        
        repeat {
            autoreleasepool { () -> Void in
                NSLog("MCTS: starting iteration from root node")
                var node = self.select(self.root)
                if (node.isTerminal == false && node.wasVisited) {
                    // expand only after nide itself was simalated at least once
                    NSLog("MCTS: expanding node \(node)")
                    node.expand()
                    NSLog("MCTS: expanded")
                    node = node.children.randomElement()!
                    NSLog("MCTS: next node is \(node)")
                }
                
                let value = node.simulate(againstState: self.root.state)
                NSLog("MCTS: simulating node \(node) - value: \(value)")
                self.backpropogate(node: node, value: value, visits: 1, shouldChangeValueSign: self.shouldChangeValueSignDuringBackpropagation)
                
                if iterationsCount != nil {
                    iterationsLeft = iterationsLeft - 1
                    if (iterationsLeft <= 0) {
                        completion?()
                        return;
                    }
                }
            }
        } while self.stopped == false && iterationsLeft > 0
    }
    
    func backpropogate(node: DSNode, value:Int, visits:Int, shouldChangeValueSign: Bool) {
        var nodeToUpdate: DSNode? = node
        var valueToUpdate = value
        repeat {
            nodeToUpdate!.update(value: valueToUpdate, visits: visits)
            if shouldChangeValueSign {
                valueToUpdate = valueToUpdate * -1
            }
            
            nodeToUpdate = nodeToUpdate!.parent
        } while nodeToUpdate != nil
    }
    
    func select(_ node:DSNode) -> DSNode {
        var condidate = node
        repeat {
            if (condidate.isLeaf) {
                NSLog("MCTS: selecting node is \(condidate)")
                return condidate
            } else {
                NSLog("MCTS: cur node is not leaf, finding next node...")
                condidate = self.findNextToVisit(fromNodes: condidate.children)
                NSLog("MCTS: next node is \(condidate)")
            }
        } while true
    }
    
    func findNextToVisit(fromNodes nodes:[DSNode]) -> DSNode {
        for node in nodes {
            if node.visits == 0 {
                return node
            }
        }
        
        var possibleNextNodes = [DSNode]()
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
                possibleNextNodes = [node]
            } else if ucb == maxValue {
                possibleNextNodes.append(node)
            }
        }
        let nextNode = possibleNextNodes.randomElement()!
        NSLog("MCTS:: findNextToVisit: chosen: \(maxValue), \(nextNode.state.transition) - average value: \(nextNode.averageValue), value: \(nextNode.value), visits: \(nextNode.visits)\n")
        return nextNode
    }
    
    func findNode(by state:DSState) -> DSNode? {
        func findMatchingNode(by state: DSState, from node:DSNode) -> DSNode? {
            
            for child in node.children {
                if child.state.equalTo(rhs: state) {
                    return child
                }
            }

            for child in node.children {
                let matchingNode = findMatchingNode(by: state, from: child)
                
                if matchingNode != nil {
                    return matchingNode
                }
            }
            return nil;
        }
        
        if self._rootNode.state == state {
            return self._rootNode;
        }
        
        return findMatchingNode(by: state, from: self._rootNode)
    }
}
