//
//  DSFakeState.swift
//  DSMonteCarloTreeSearchTests
//
//  Created by Simkin Dmitry on 6/16/18.
//  Copyright © 2018 Simkin Dmitry. All rights reserved.
//

import Foundation

class DSFakeState: DSState {
    let identifier : UUID
    
    var terminal: Bool = false
    override var isTerminal: Bool {
        get {
            return self.terminal
        }
    }
    
    override func possibleTransitions() -> [DSTransition] {
        return self.fakePossibleTransitions
    }
    
    var stateAfterTransitionCallsCount = 0
    var fakePossibleTransitions = [DSTransition]()
    override func state(afterTransition transition: DSTransition) -> DSState {
        let transition = self.fakePossibleTransitions[self.stateAfterTransitionCallsCount]
        let state = DSFakeState(transition: transition)
        self.stateAfterTransitionCallsCount = self.stateAfterTransitionCallsCount + 1
        return state;
    }
    
    override init(transition: DSTransition) {
        self.identifier = UUID()
        super.init(transition: transition)
    }    
    
    override func equalTo(rhs: DSState) -> Bool {
        guard rhs is DSFakeState else {
            return false
        }
        let rhs = rhs as! DSFakeState
        let equal = self.identifier == rhs.identifier
        return equal;
    }
    
    var simulateReturnValue: Double = 0
    override func simulate(againstState state: DSState) -> Double {
        return self.simulateReturnValue
    }
}
