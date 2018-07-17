//
//  DSMonteCarloTreeSearchTests.swift
//  DSMonteCarloTreeSearchTests
//
//  Created by Simkin Dmitry on 5/25/18.
//  Copyright © 2018 Simkin Dmitry. All rights reserved.
//

import XCTest
@testable import DSMonteCarloTreeSearch


class FakeMonterCarloTreeSearch: DSMonterCarloTreeSearch {
    var findNodeReturnValue: DSNode?
    override func findNode(by state: DSState) -> DSNode? {
        return self.findNodeReturnValue
    }
    
    var shoildCallIterateSearch = false
    let iterateExpectation = XCTestExpectation(description: "Iterate")
    override func iterate() {
        self.iterateExpectation.fulfill()
        if self.shoildCallIterateSearch {
            super.iterate()
        }
    }
    
    let stopExpectation = XCTestExpectation(description: "Stop")
    override func stop() {
        self.stopExpectation.fulfill()
        super.stop()
    }
    
    
}

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
        XCTAssertEqual(mcts.root.state, initialState)
    }
    
    func testRootStateUpdatedWhenFound() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let child1 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child2 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        
        search.root.children = [child1, child2]
        search.findNodeReturnValue = child2
        
        search.updateRootState(child2.state)
        XCTAssertNotEqual(search.root, child1)
        XCTAssertEqual(search.root, child2)

        
        let child21 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        let child22 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        let child23 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        child2.children = [child21, child22, child23]
        search.findNodeReturnValue = child21
        
        search.updateRootState(child21.state)
        XCTAssertNotEqual(search.root, child22)
        XCTAssertNotEqual(search.root, child23)
        XCTAssertEqual(search.root, child21)
    }
    
    func testRootStateNotUpdatedWhenStateNotFound() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let child1 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child2 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child3 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        
        let randomState = DSFakeState(transition: DSFakeTransition())
        
        search.root.children = [child1, child2, child3]
        search.findNodeReturnValue = nil;
        
        search.updateRootState(randomState)
        XCTAssertNotEqual(search.root, child1)
        XCTAssertNotEqual(search.root, child2)
        XCTAssertNotEqual(search.root, child3)
    
        XCTAssertEqual(search.root.state, randomState)

    }
    
    
    func testStoppedChangedToFalseAfterStartCalled() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let expectation = XCTestExpectation(description: "Search expectation")

        search.stopped = true
        search.start(timeFrame: DispatchTimeInterval.seconds(1)) { (_) in
            expectation.fulfill()
        }
        XCTAssertFalse(search.stopped)
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testIterateCalled() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        search.start(timeFrame: DispatchTimeInterval.seconds(1)) { (_) in }
        wait(for: [search.iterateExpectation], timeout: 2)
    }
    
    func testExpandCalledOnRootWhenItsNotVisited() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let root = DSFakeNode.init(rootState: initialState)
        search._rootNode = root
        search.start(timeFrame: DispatchTimeInterval.seconds(1), completion: { (_) in} )
        
        wait(for: [root.expandExpectation, search.iterateExpectation], timeout: 2, enforceOrder: true)
    }
    
    func testExpandNotCalledOnRootWhenItAlreadyExpanded() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let root = DSFakeNode.init(rootState: initialState)
        root.wasExpanded = true
        root.expandExpectation.isInverted = true // should not be fullfilled
        search._rootNode = root
        search.start(timeFrame: DispatchTimeInterval.seconds(1), completion: { (_) in} )
        
        wait(for: [root.expandExpectation], timeout: 2, enforceOrder: true)
    }
    
    func testSearchCompletionIsnotCalledWhenSearchInstanceNoLongerNeeded() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        var search: DSMonterCarloTreeSearch? = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let expectation = XCTestExpectation(description: "Search expectation")
        expectation.isInverted = true
        
        search!.start(timeFrame: DispatchTimeInterval.seconds(3)) { (_) in
            expectation.fulfill()
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
            search = nil;
        }
        
        wait(for: [expectation], timeout: 4)
    }
    
    func testSearchCompletionNotCalledWhenStoppedBefore() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let expectation = XCTestExpectation(description: "Search expectation")
        expectation.isInverted = true
        
        search.start(timeFrame: DispatchTimeInterval.seconds(2)) { (_) in
            expectation.fulfill()
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
            search.stop()
        }
        
        wait(for: [expectation, search.stopExpectation], timeout: 3)
    }
    
    func testSearchStoppedAfterDeadline() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let expectation = XCTestExpectation(description: "Search expectation")
        search.start(timeFrame: DispatchTimeInterval.seconds(5)) { (_) in
            expectation.fulfill()
        }
        
        wait(for: [search.stopExpectation, expectation], timeout: 5.1)
        XCTAssertTrue(search.stopped)
    }
    
    func testStoppedChangedAfterStopCalled() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = DSMonterCarloTreeSearch(initialState: initialState)

        search.stopped = false
        search.stop()
        XCTAssertTrue(search.stopped)
    }
    
    func testResultAreNilWhenNoRootChildrenNodes() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = DSMonterCarloTreeSearch(initialState: initialState)
        
        let result = search.results()
        XCTAssertTrue(result == nil)
    }
    
    func testResultsSorted() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = DSMonterCarloTreeSearch(initialState: initialState)
        let child1 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child2 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child3 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        search.root.children = [child1, child2, child3]
        child1.averageValue = 0.1231
        child2.averageValue = -34.23
        child3.averageValue = 23.0
        
        let result = search.results()
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.bestNode, child3)
        XCTAssertEqual(result!.nodes.count, 3)
        XCTAssertEqual(result!.nodes[0], child3)
        XCTAssertEqual(result!.nodes[1], child1)
        XCTAssertEqual(result!.nodes[2], child2)
    }
    
    
    
    
}
