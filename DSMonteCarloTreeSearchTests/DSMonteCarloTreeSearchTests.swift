//
//  DSMonteCarloTreeSearchTests.swift
//  DSMonteCarloTreeSearchTests
//
//  Created by Simkin Dmitry on 5/25/18.
//  Copyright © 2018 Simkin Dmitry. All rights reserved.
//

import XCTest
@testable import DSMonteCarloTreeSearch

class DSMonteCarloTreeSearchTests: XCTestCase {
    
    var mcts: DSMonterCarloTreeSearch!
    
    override func setUp() {
        super.setUp()
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        self.mcts = DSMonterCarloTreeSearch(initialState: initialState)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInit() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let mcts = DSMonterCarloTreeSearch(initialState: initialState)
        XCTAssertEqual(mcts.initialState, initialState)
        XCTAssertEqual(mcts.root.state, initialState)
    }
    
    func testUCB() {
        let transition = DSFakeTransition()
        let state = DSFakeState(transition: transition)
        let node = DSFakeNode.init(state: state, parent: self.mcts.root)
        node.value = 20
        node.visits = 1
        
        self.mcts.root.value = 30
        self.mcts.root.visits = 2
//        let x = self.mcts.calculateUCB(node: node)
//        print(x)
    }
    
}
