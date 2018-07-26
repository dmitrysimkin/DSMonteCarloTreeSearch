//
//  DSNodeTests.swift
//  DSMonteCarloTreeSearchTests
//
//  Created by Simkin Dmitry on 6/16/18.
//  Copyright © 2018 Simkin Dmitry. All rights reserved.
//

import XCTest
@testable import DSMonteCarloTreeSearch

class DSNodeTests: XCTestCase {
    
    var rootTransition: DSFakeTransition!
    var rootState: DSFakeState!
    var rootNode: DSFakeNode!
    
    override func setUp() {
        super.setUp()
        self.rootTransition = DSFakeTransition()
        self.rootState = DSFakeState(transition: self.rootTransition)
        self.rootNode = DSFakeNode(rootState: self.rootState)
    }
    
    func testInitRootNode() {
        XCTAssertEqual(rootNode.parent, nil)
        XCTAssertEqual(rootNode.state, rootState)
        XCTAssertEqual(rootNode.visits, 0)
        XCTAssertEqual(rootNode.value, 0)
        XCTAssertEqual(rootNode.children.count, 0)
    }
    
    func testInit() {
        let state = DSFakeState(transition: DSFakeTransition())
        let node = DSFakeNode(state: state, parent: self.rootNode)
        XCTAssertEqual(node.parent, self.rootNode)
        XCTAssertEqual(node.state, state)
        XCTAssertEqual(node.visits, 0)
        XCTAssertEqual(node.value, 0)
        XCTAssertEqual(node.children.count, 0)
    }
    
    func testWasVisted() {
        self.rootNode.visits = 0
        XCTAssertEqual(self.rootNode.wasVisited, false)
        self.rootNode.visits = 1
        XCTAssertEqual(self.rootNode.wasVisited, true)
        
        self.rootNode.visits = 3
        XCTAssertEqual(self.rootNode.wasVisited, true)
        
        self.rootNode.visits = 10
        XCTAssertEqual(self.rootNode.wasVisited, true)
        
        self.rootNode.visits = Int.max
        XCTAssertEqual(self.rootNode.wasVisited, true)
    }
    
    func testIsLeaf() {
        XCTAssertTrue(self.rootNode.isLeaf)
        
        let transition = DSFakeTransition()
        let state = DSFakeState(transition: transition)
        let node1 = DSFakeNode(state: state, parent: self.rootNode)
        let node2 = DSFakeNode(state: state, parent: self.rootNode)
        let node3 = DSFakeNode(state: state, parent: self.rootNode)
        let node4 = DSFakeNode(state: state, parent: self.rootNode)
        let node5 = DSFakeNode(state: state, parent: self.rootNode)
        
        self.rootNode.children = [node1]
        XCTAssertFalse(self.rootNode.isLeaf)
        XCTAssertTrue(node1.isLeaf)
        
        self.rootNode.children = [node1, node2]
        XCTAssertFalse(self.rootNode.isLeaf)
        XCTAssertTrue(node1.isLeaf)
        XCTAssertTrue(node2.isLeaf)
        
        self.rootNode.children = [node1, node2]
        node1.children = [node3, node4]
        XCTAssertFalse(self.rootNode.isLeaf)
        XCTAssertFalse(node1.isLeaf)
        XCTAssertTrue(node2.isLeaf)
        XCTAssertTrue(node3.isLeaf)
        XCTAssertTrue(node4.isLeaf)
        
        node4.children = [node5]
        XCTAssertFalse(self.rootNode.isLeaf)
        XCTAssertFalse(node1.isLeaf)
        XCTAssertTrue(node2.isLeaf)
        XCTAssertTrue(node3.isLeaf)
        XCTAssertFalse(node4.isLeaf)
    }
    
    func testIsTerminal() {
        let transition = DSFakeTransition()
        let state = DSFakeState(transition: transition)
        let node = DSNode(state: state, parent: self.rootNode)
        XCTAssertFalse(node.isTerminal)
        state.terminal = true
        XCTAssertTrue(node.isTerminal)
    }
    
    func testUpdateNode() {
        XCTAssertEqual(self.rootNode.visits, 0)
        XCTAssertEqual(self.rootNode.value, 0)

        let value = 2.0
        let visits = 1
        self.rootNode.update(value: value, visits: visits)
        
        XCTAssertEqual(self.rootNode.value, 2)
        XCTAssertEqual(self.rootNode.visits, 1)
    }
    
    func testUpdateWhenMoreThen1Visits() {
        XCTAssertEqual(self.rootNode.visits, 0)
        XCTAssertEqual(self.rootNode.value, 0)
        
        let value = 5.0
        let visits = 3
        self.rootNode.update(value: value, visits: visits)
        
        XCTAssertEqual(self.rootNode.value, value)
        XCTAssertEqual(self.rootNode.visits, visits)
    }
    
    func testAverageIsZeroAtBegining() {
        let state = DSFakeState(transition: self.rootTransition)
        let node = DSNode(rootState: state)
        
        XCTAssertEqual(node.averageValue, 0)
    }
    
    func testUpdateAverageCalled() {
        XCTAssertEqual(self.rootNode.averageValue, 0)
        self.rootNode.update(value: 5.0, visits: 2)
        wait(for: [self.rootNode.updateAverageValueExpectation], timeout: 0.1)
    }
    
    func testUpdateAverageValueCorrectly() {
        var node: DSNode
        
        node = DSNode(rootState: self.rootState)
        XCTAssertEqual(node.averageValue, 0)
        node.update(value: 5.0, visits: 2)
        XCTAssertEqual(node.averageValue, 2.5)
        
        node = DSNode(rootState: self.rootState)
        node.update(value: 0, visits: 3123321)
        XCTAssertEqual(node.averageValue, 0)
        
        node = DSNode(rootState: self.rootState)
        node.update(value: -20, visits: 4)
        XCTAssertEqual(node.averageValue, -5.0)
        
        node = DSNode(rootState: self.rootState)
        node.update(value: 21354.324, visits: 1223)
        XCTAssertEqual(node.averageValue, 17.460608340147179)
    }
    
    
    func testExpand() {
        let transition = DSFakeTransition()
        let state = DSFakeState(transition: transition)
        let node = DSNode(state: state, parent: self.rootNode)
        
        let possibleTransition1 = DSFakeTransition()
        let possibleTransition2 = DSFakeTransition()
        let possibleTransition3 = DSFakeTransition()
        state.fakePossibleTransitions = [possibleTransition1, possibleTransition2, possibleTransition3]
        
        XCTAssertEqual(node.wasExpanded, false)
        XCTAssertEqual(node.children.count, 0)
        
        node.expand()
        
        XCTAssertEqual(node.wasExpanded, true)
        XCTAssertEqual(node.children.count, 3)
        let transitions = node.children.map({ (node) -> DSFakeTransition in
            return node.state.transition as! DSFakeTransition
        })
        XCTAssertEqual(transitions, state.fakePossibleTransitions)
    }
    
    func testExpandFailedWhenAlreadyExpanded() {
        let transition = DSFakeTransition()
        let state = DSFakeState(transition: transition)
        let node = DSFakeNode(state: state, parent: self.rootNode)
        
        let possibleTransition1 = DSFakeTransition()
        let possibleTransition2 = DSFakeTransition()
        let possibleTransition3 = DSFakeTransition()
        state.fakePossibleTransitions = [possibleTransition1, possibleTransition2, possibleTransition3]
        
        XCTAssertEqual(node.wasExpanded, false)
        XCTAssertEqual(node.children.count, 0)
        
        node.wasExpanded = true
        node.expand()

        XCTAssertEqual(node.wasExpanded, true)
        XCTAssertEqual(node.children.count, 0)
    }
    
    func testExpandFailedWhenStateIsTerminal() {
        let transition = DSFakeTransition()
        let state = DSFakeState(transition: transition)
        let node = DSNode(state: state, parent: self.rootNode)
        
        XCTAssertEqual(node.wasExpanded, false)
        XCTAssertEqual(node.children.count, 0)
        
        state.terminal = true
        node.expand()
        
        XCTAssertEqual(node.isTerminal, true)
        XCTAssertEqual(node.wasExpanded, false)
        XCTAssertEqual(node.children.count, 0)
    }

    func testSimulate() {
        let transition = DSFakeTransition()
        let state = DSFakeState(transition: transition)
        let node = DSFakeNode(state: state, parent: self.rootNode)

        state.simulateReturnValue = 10
        XCTAssertEqual(node.simulate(againstState: state), 10)
        
        state.simulateReturnValue = 234541
        XCTAssertEqual(node.simulate(againstState: state), 234541)
        
        state.simulateReturnValue = -200
        XCTAssertEqual(node.simulate(againstState: state), -200)
        
        state.simulateReturnValue = 0
        XCTAssertEqual(node.simulate(againstState: state), 0)
    }
    
}
