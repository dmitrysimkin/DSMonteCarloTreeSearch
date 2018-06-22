//
//  DSNode.swift
//  DSMonteCarloTreeSearch
//
//  Created by Simkin Dmitry on 5/25/18.
//  Copyright © 2018 Simkin Dmitry. All rights reserved.
//

import Foundation


/// Class that represents search tree node
public class DSNode: NSObject {
    
    /// Value that was calculated by node's state and child nodes states.
    public var value: Int = 0
    
    /// How many times node was visited (simulated the node itself or its child nodes)
    public var visits: Int = 0
    
    /// Average node value. Calculated as 'self.value / self.visits'.
    /// If self.visits == 0 average value is equal to Double.infinity
    public var averageValue: Double = Double.infinity
    
    /// State that node represents in the tree
    public let state: DSState
    
    /// Parent node
    internal(set) public weak var parent: DSNode?
    
    /// Child nodes
    internal(set) public var children = [DSNode]()
    
    /// Tells whether node is a leaf node (has no child nodes) or not
    public var isLeaf: Bool {
        get {
            let leaf = self.children.count == 0
            return leaf
        }
    }
    
    /// Tells whether node was visited at least 1 time
    public var wasVisited: Bool {
        get {
            return self.visits > 0
        }
    }
    
    /// Tells whether node was expanded or not
    internal(set) public var wasExpanded: Bool = false
    
    /// Tells wherer node's state is terminal or not
    public var isTerminal: Bool {
        get {
            let terminal = self.state.isTerminal
            return terminal
        }
    }
    
    func updateAverageValue() {
        var value: Double!
        if self.visits == 0 {
            value = Double.infinity
        } else {
            value = Double(self.value / self.visits)
        }
        self.averageValue = value;
    }
    
    init(state: DSState, parent: DSNode) {
        self.state = state
        self.parent = parent
    }
    
    init(rootState state: DSState) {
        self.state = state
        self.parent = nil;
    }
    
    private override init() {
        fatalError("Init is not allowed")
    }
    
    func backpropogate(value:Int, visits:Int) {
        self.value = self.value + value
        self.visits = self.visits + visits
        self.updateAverageValue()
        self.parent?.backpropogate(value: value, visits: visits)
    }
    
    func expand() {
        guard self.wasExpanded == false else {
            return;
        }
        guard self.isTerminal == false else {
            return;
        }
        
        for transition in self.state.possibleTransitions() {
            let newState = self.state.state(afterTransition: transition)
            let node = DSNode(state: newState, parent: self)
            self.children.append(node)
        }
        self.wasExpanded = true
    }
    
    func simulate(againstState state: DSState) -> Int {
//        simulating several times
//        var value = 0
//        for _ in 0..<30 {
//            autoreleasepool { [unowned self] in
//                value = value + self.state.simulate(againstState: state)
//            }
//        }
        
        let value = self.state.simulate(againstState: state)
        
        return value;
    }
}

