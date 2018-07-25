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
    override func simulate(againstState state: DSState) -> Int {
        self.simulateExpectation.fulfill()
        return super.simulate(againstState: state)
    }
    
    let backpropagateExpectation = XCTestExpectation(description: "Backpropagate")
    override func backpropogate(value: Int, visits: Int) {
        self.backpropagateExpectation.fulfill()
        super.backpropogate(value: value, visits: visits)
    }
}
