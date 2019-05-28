//
//  DSFakeState.swift
//  DSMonteCarloTreeSearchTests
//
//  Created by Simkin Dmitry on 6/16/18.
//  Copyright © 2018 Simkin Dmitry. All rights reserved.
//

import Foundation

class DSFakeState: DSStateProtocol {
    
    typealias StateType = DSFakeState
    typealias TransitionType = DSFakeTransition
    
    let identifier : UUID
    var transition: DSFakeTransition
    
    var terminal: Bool = false
    var isTerminal: Bool {
        get {
            return self.terminal
        }
    }
    
    func possibleTransitions() -> [DSFakeTransition] {
        return self.fakePossibleTransitions
    }
    
    var stateAfterTransitionCallsCount = 0
    var fakePossibleTransitions = [DSFakeTransition]()
    func state(afterTransition transition: DSFakeTransition) -> DSFakeState {
        let transition = self.fakePossibleTransitions[self.stateAfterTransitionCallsCount]
        let state = DSFakeState(transition: transition)
        self.stateAfterTransitionCallsCount = self.stateAfterTransitionCallsCount + 1
        return state;
    }
    
    init(transition: DSFakeTransition) {
        self.identifier = UUID()
        self.transition = transition
    }
    
    static func == (lhs: DSFakeState, rhs: DSFakeState) -> Bool {
        let equal = lhs.identifier == rhs.identifier
        return equal;
    }
    
    var simulateReturnValue: Double = 0
    func simulate(againstState state: DSFakeState) -> Double {
        return self.simulateReturnValue
    }
}
