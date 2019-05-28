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
    associatedtype TransitionType
    associatedtype StateType
    
    /// Possible Transitions
    ///
    /// - returns: list of possible transitions from current state
    func possibleTransitions() -> [TransitionType]
    
    
    /// Return state that happens after applying 'transition' to current state
    ///
    /// - parameters:
    ///   - afterTransition: transition to apply
    /// - return: state that happens after applying 'transition' to current state
    func state(afterTransition transition:TransitionType) -> StateType
    
    
    /// Simulate from current state to a terminal state and return value comparing to 'againstState'
    /// that represents win, loss, draw, etc. (you have to choose appropriate value)
    ///
    /// - parameters:
    ///   - againstState: root node's state to evaluate simulation
    /// - returns: simulated value
    func simulate(againstState state: StateType) -> Double
    
    
    /// Return whether state is terminal or not
    var isTerminal: Bool { get }
    
    /// Transition that led to current state
    var transition: TransitionType { get }    
}
