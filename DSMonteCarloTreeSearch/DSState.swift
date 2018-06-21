//
//  DSState.swift
//  DSMonteCarloTreeSearch
//
//  Created by Simkin Dmitry on 5/25/18.
//  Copyright © 2018 Simkin Dmitry. All rights reserved.
//

import Foundation

public protocol DSStateProtocol: Equatable {
    func possibleTransitions() -> [DSTransition]
    func state(afterTransition transition:DSTransition) -> DSState
    func simulate(againstState state: DSState) -> Int
    var isTerminal: Bool { get }
    var transition: DSTransition { get }
    func equalTo(rhs: DSState) -> Bool
}

open class DSState: DSStateProtocol {
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
