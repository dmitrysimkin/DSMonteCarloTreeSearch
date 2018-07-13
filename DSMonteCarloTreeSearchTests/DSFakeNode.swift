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
}
