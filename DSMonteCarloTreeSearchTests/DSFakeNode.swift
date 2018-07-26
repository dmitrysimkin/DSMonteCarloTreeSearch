//
//  DSFakeNode.swift
//  DSMonteCarloTreeSearchTests
//
//  Created by Simkin Dmitry on 6/16/18.
//  Copyright © 2018 Simkin Dmitry. All rights reserved.
//

import Foundation
import XCTest

class DSFakeNode: DSNode {
    
    var fakeTerminal = false
    override var isTerminal: Bool {
        get {
            return self.fakeTerminal
        }
    }
    
    let expandExpectation = XCTestExpectation(description: "Expand expectation")
    var shouldCallExpand = false
    override func expand() {
        self.expandExpectation.fulfill()
        if self.shouldCallExpand {
            super.expand()
        }
    }
    
    let simulateExpectation = XCTestExpectation(description: "Simulate")
    override func simulate(againstState state: DSState) -> Double {
        self.simulateExpectation.fulfill()
        return super.simulate(againstState: state)
    }
    
    let updateExpectation = XCTestExpectation(description: "Update")
    override func update(value: Double, visits: Int) {
        self.updateExpectation.fulfill()
        super.update(value: value, visits: visits)
    }
    
    let updateAverageValueExpectation = XCTestExpectation(description: "Update Average value")
    override func updateAverageValue(value: Double, visits: Int) {
        self.updateAverageValueExpectation.fulfill()
        super.updateAverageValue(value: value, visits: visits)
    }
}
