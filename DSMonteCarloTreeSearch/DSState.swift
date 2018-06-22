//
//  DSState.swift
//  DSMonteCarloTreeSearch
//
//  Created by Simkin Dmitry on 5/25/18.
//  Copyright © 2018 Simkin Dmitry. All rights reserved.
//

import Foundation

/// Interface describing state that can be passed to Monte Carlo Tree Search algorithm
public protocol DSStateProtocol: Equatable {

    /// Possible Transitions
    ///
    /// - returns: list of possible transitions from current state
    func possibleTransitions() -> [DSTransition]
    
    
    /// Return state that happens after applying 'transition' to current state
    ///
    /// - parameters:
    ///   - afterTransition: transition to apply
    /// - return: state that happens after applying 'transition' to current state
    func state(afterTransition transition:DSTransition) -> DSState
    
    
    /// Simulate from current state to a terminal state and return value comparing to 'againstState'
    /// that represents win, loss, draw, etc. (you have to choose appropriate value)
    ///
    /// - parameters:
    ///   - againstState: root node's state to evaluate simulation
    /// - returns: simulated value
    func simulate(againstState state: DSState) -> Int
    
    
    /// Return whether state is terminal or not
    var isTerminal: Bool { get }
    
    /// Transition that led to current state
    var transition: DSTransition { get }
    
    /// Return wheteer current state is equal to 'rhs' state
    ///
    /// - parameters:
    ///   - rhs: object to compare to
    /// - retunrs: equal or not
    func equalTo(rhs: DSState) -> Bool
}


/// Abstact class to inherit from and adapt to your domain
/// Make a subclass and implement 'DSStateProtocol' methods
open class DSState: DSStateProtocol {

    /// Designated initializer
    ///
    /// - parameters:
    ///   - transition: transition that led to that state
    public init(transition: DSTransition) {
        self.transition = transition
    }
    
    open func possibleTransitions() -> [DSTransition] {
        fatalError("can not be called on the DSState class")
    }
    
    open func state(afterTransition transition: DSTransition) -> DSState {
        fatalError("can not be called on the DSState class")
    }
    
    open func simulate(againstState state: DSState) -> Int {
        fatalError("can not be called on the DSState class")
    }
    
    open var transition: DSTransition
    
    open var isTerminal: Bool { get { fatalError("can not be called on the DSState class") } }
    
    public static func == (lhs: DSState, rhs: DSState) -> Bool {
        return lhs.equalTo(rhs: rhs)
    }
    
    open func equalTo(rhs: DSState) -> Bool {
        fatalError("can not be called on the DSState class")
    }
}
