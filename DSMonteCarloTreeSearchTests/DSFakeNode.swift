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
    let expandExpectation = XCTestExpectation(description: "Expand expectation")
    override func expand() {
        self.expandExpectation.fulfill()
        super.expand()
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
