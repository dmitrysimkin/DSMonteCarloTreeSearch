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
    
    var findNextToVisitReturnFunc: (([DSNode]) -> DSNode)?
    override func findNextToVisit(fromNodes nodes: [DSNode]) -> DSNode {
        if self.findNextToVisitReturnFunc != nil {
            return self.findNextToVisitReturnFunc!(nodes)
        } else {
            return super.findNextToVisit(fromNodes: nodes)
        }
    }
    
    var shouldCallIterateSearch = false
    let iterateExpectation = XCTestExpectation(description: "Iterate")
    override func iterate(iterationsCount: UInt?, completion: (() -> Void)?) {
        self.iterateExpectation.fulfill()
        if self.shouldCallIterateSearch {
            super.iterate(iterationsCount: iterationsCount, completion: completion)
        }
    }
    
    let stopExpectation = XCTestExpectation(description: "Stop")
    override func stop() {
        self.stopExpectation.fulfill()
        super.stop()
    }
    
    let selectExpectation = XCTestExpectation(description: "Select")
    var selectReturnValue: DSNode?
    override func select(_ node: DSNode) -> DSNode {
        self.selectExpectation.fulfill()
        if self.selectReturnValue != nil {
            return self.selectReturnValue!
        } else {
            return super.select(node)
        }
    }
    
    let backpropagateExpectation = XCTestExpectation(description: "Backpropagate")
    override func backpropogate(node: DSNode, value: Double, visits: Int, shouldChangeValueSign: Bool) {
        self.backpropagateExpectation.fulfill()
        super.backpropogate(node: node, value: value, visits: visits, shouldChangeValueSign: shouldChangeValueSign)
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
        
        wait(for: [expectation, search.stopExpectation], timeout: 2.1)
    }
    
    func testSearchStoppedAfterDeadline() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let expectation = XCTestExpectation(description: "Search expectation")
        search.start(timeFrame: DispatchTimeInterval.seconds(1)) { (_) in
            expectation.fulfill()
        }
        
        wait(for: [search.stopExpectation, expectation], timeout: 1.1)
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
    
    func testNextToVisitFromNotVisited() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = DSMonterCarloTreeSearch(initialState: initialState)

        let child1 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child2 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child3 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        search.root.children = [child1, child2, child3]
        child1.visits = 1
        child1.value = 1
        
        let next = search.findNextToVisit(fromNodes: search.root.children)
        XCTAssertTrue([child2, child3].contains(next))
    }
    
    func testNextToVisitFromIsOneNotVisited() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = DSMonterCarloTreeSearch(initialState: initialState)
        
        let child1 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child2 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child3 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        search.root.children = [child1, child2, child3]
        child1.visits = 1
        child1.value = 1
        child3.visits = 2
        child3.value = -1
        
        let next = search.findNextToVisit(fromNodes: search.root.children)
        XCTAssertTrue(child2 == next) 
    }
    
    
    func testNextToVisitIsAmongOnesWithSameUCB() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = DSMonterCarloTreeSearch(initialState: initialState)
        let child1 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child2 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child3 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        child1.visits = 10
        child2.visits = 20
        child3.visits = 312
        search.root.children = [child1, child2, child3]

        search.ucb1 = { (node, rootNode) in
            switch node {
            case child1:
                return 15.123
            case child2:
                return 3.21
            case child3:
                return 15.123
            default:
                return 0
            }
        }
        
        let next = search.findNextToVisit(fromNodes: search.root.children)
        XCTAssertTrue([child1, child3].contains(next))
    }
    
    
    func testNextToVisitWhenUCBIsAllNegative() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = DSMonterCarloTreeSearch(initialState: initialState)
        let child1 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child2 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child3 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        child1.visits = 10
        child2.visits = 20
        child3.visits = 312
        search.root.children = [child1, child2, child3]
        
        search.ucb1 = { (node, rootNode) in
            switch node {
            case child1:
                return -20.123
            case child2:
                return -1323440.123
            case child3:
                return -1
            default:
                return 0
            }
        }
        
        let next = search.findNextToVisit(fromNodes: search.root.children)
        XCTAssertTrue(next == child3)
    }
    
    
    func testFindNodeByStateNotFoundOnRootWithoutChildren() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = DSMonterCarloTreeSearch(initialState: initialState)
        
        let someState = DSFakeState(transition: DSFakeTransition())
        
        let node = search.findNode(by: someState)
        XCTAssertNil(node)
    }
    
    func testFindNodeByStateNotFoundWhenThereIsNoSuchStateInHierarchy() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = DSMonterCarloTreeSearch(initialState: initialState)
        let child1 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child2 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child3 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child4 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child5 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        search.root.children = [child1, child2, child3, child4, child5]
        
        let child21 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        let child22 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        let child23 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        child2.children = [child21, child22, child23]
        
        let child51 = DSNode(state: DSFakeState(transition: transition), parent: child5)
        let child52 = DSNode(state: DSFakeState(transition: transition), parent: child5)
        child5.children = [child51, child52]
        
        let someState = DSFakeState(transition: DSFakeTransition())

        let node = search.findNode(by: someState)
        XCTAssertNil(node)
    }
    
    
    func testFindNodeByStateFoundOnFirstLevel() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = DSMonterCarloTreeSearch(initialState: initialState)
        
        let stateThatFaveToBeFound = DSFakeState(transition: DSFakeTransition())

        let child1 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child2 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child3 = DSNode(state: stateThatFaveToBeFound, parent: search.root)
        let child4 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child5 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        search.root.children = [child1, child2, child3, child4, child5]
        
        let child21 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        let child22 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        let child23 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        child2.children = [child21, child22, child23]
        
        let child51 = DSNode(state: DSFakeState(transition: transition), parent: child5)
        let child52 = DSNode(state: DSFakeState(transition: transition), parent: child5)
        child5.children = [child51, child52]
        
        let node = search.findNode(by: stateThatFaveToBeFound)
        XCTAssertTrue(node == child3)
    }
    
    func testFindNodeByStateFoundOnSecondLevel() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = DSMonterCarloTreeSearch(initialState: initialState)
        
        let stateThatFaveToBeFound = DSFakeState(transition: DSFakeTransition())
        
        let child1 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child2 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child3 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child4 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child5 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        search.root.children = [child1, child2, child3, child4, child5]
        
        let child21 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        let child22 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        let child23 = DSNode(state: stateThatFaveToBeFound, parent: child2)
        child2.children = [child21, child22, child23]
        
        let child51 = DSNode(state: DSFakeState(transition: transition), parent: child5)
        let child52 = DSNode(state: DSFakeState(transition: transition), parent: child5)
        child5.children = [child51, child52]
        
        let node = search.findNode(by: stateThatFaveToBeFound)
        XCTAssertTrue(node == child23)
    }
    
    func testFindNodeByStateFoundOnThirdLevel() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = DSMonterCarloTreeSearch(initialState: initialState)
        
        let stateThatFaveToBeFound = DSFakeState(transition: DSFakeTransition())
        
        let child1 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child2 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child3 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child4 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child5 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        search.root.children = [child1, child2, child3, child4, child5]
        
        let child21 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        let child22 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        let child23 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        child2.children = [child21, child22, child23]
        
        let child51 = DSNode(state: DSFakeState(transition: transition), parent: child5)
        let child52 = DSNode(state: DSFakeState(transition: transition), parent: child5)
        child5.children = [child51, child52]
        
        let child511 = DSNode(state: stateThatFaveToBeFound, parent: child51)
        child51.children = [child511]
        
        let node = search.findNode(by: stateThatFaveToBeFound)
        XCTAssertTrue(node == child511)
    }
    
    func testFindNodeByStateWhenRootIsWhatIsLookedFor() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = DSMonterCarloTreeSearch(initialState: initialState)
        
        let child1 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child2 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child3 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child4 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child5 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        search.root.children = [child1, child2, child3, child4, child5]
        
        let child21 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        let child22 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        let child23 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        child2.children = [child21, child22, child23]
        
        let child51 = DSNode(state: DSFakeState(transition: transition), parent: child5)
        let child52 = DSNode(state: DSFakeState(transition: transition), parent: child5)
        child5.children = [child51, child52]

        let node = search.findNode(by: initialState)
        XCTAssertTrue(node == search.root)
    }
    
    func testDefaultUCB1Calculation() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = DSMonterCarloTreeSearch(initialState: initialState)
        search.root.value = 30
        search.root.visits = 3
        let node1 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        node1.value = 20
        node1.visits = 2

        var value = search.ucb1(node1, search.root)
        XCTAssertLessThan(fabs(value - 11.48) , 0.01)
        
        let node2 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        node2.value = 10
        node2.visits = 1
        
        value = search.ucb1(node2, search.root)
        XCTAssertLessThan(fabs(value - 12.10) , 0.01)
    }
    
    func testUcbFormulaCanBeChanged() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = DSMonterCarloTreeSearch(initialState: initialState)
        
        let expectation1 = XCTestExpectation(description: "UCB node1")
        let expectation2 = XCTestExpectation(description: "UCB node2")
        let expectation3 = XCTestExpectation(description: "UCB node3")
        
        let child1 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child2 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child3 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        child1.visits = 1
        child2.visits = 1
        child3.visits = 1
        search.root.children = [child1, child2, child3]

        search.ucb1 = { (node, rootNode) in
            switch node {
            case child1:
                expectation1.fulfill()
            case child2:
                expectation2.fulfill()
            case child3:
                expectation3.fulfill()
            default:
                print()
            }
            return 0
        }
        
        let _ = search.findNextToVisit(fromNodes: search.root.children)
        wait(for: [expectation1, expectation2, expectation3], timeout: 1)
    }
    
    func testSelectInitialNodeWhenItsLeaf() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = DSMonterCarloTreeSearch(initialState: initialState)
        
        let initialNode = search.root
        XCTAssertTrue(initialNode.isLeaf)
        let node = search.select(initialNode)
        XCTAssertTrue(initialNode.isLeaf)
        XCTAssertTrue(node == initialNode)
    }
    
    func testSelectNodeFromSecondLevel() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let initialNode = search.root
        let child1 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child2 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child3 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        search.root.children = [child1, child2, child3]
        
        search.findNextToVisitReturnFunc = { (nodes) in
            return child2
        }
        
        XCTAssertFalse(initialNode.isLeaf)
        let node = search.select(initialNode)
        XCTAssertTrue(child2.isLeaf)
        XCTAssertTrue(node == child2)
    }
    
    func testSelectNodeFromSecondLevelWhenThereIsMoreLevels() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let initialNode = search.root
        let child1 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child2 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child3 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child4 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child5 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        search.root.children = [child1, child2, child3, child4, child5]
        
        let child21 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        let child22 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        let child23 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        child2.children = [child21, child22, child23]
        
        let child51 = DSNode(state: DSFakeState(transition: transition), parent: child5)
        let child52 = DSNode(state: DSFakeState(transition: transition), parent: child5)
        child5.children = [child51, child52]

        let child511 = DSNode(state: DSFakeState(transition: transition), parent: child51)
        child51.children = [child511]

        search.findNextToVisitReturnFunc = { (nodes) in
            return child4
        }
        
        XCTAssertFalse(initialNode.isLeaf)
        let node = search.select(initialNode)
        XCTAssertTrue(child4.isLeaf)
        XCTAssertTrue(node == child4)
    }
    
    func testSelectNodeFromThirdLevel() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let initialNode = search.root
        let child1 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child2 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child3 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child4 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child5 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        search.root.children = [child1, child2, child3, child4, child5]
        
        let child21 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        let child22 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        let child23 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        child2.children = [child21, child22, child23]
        
        let child51 = DSNode(state: DSFakeState(transition: transition), parent: child5)
        let child52 = DSNode(state: DSFakeState(transition: transition), parent: child5)
        child5.children = [child51, child52]
        
        let child511 = DSNode(state: DSFakeState(transition: transition), parent: child51)
        child51.children = [child511]
        
        var numberCalled = 0
        search.findNextToVisitReturnFunc = { (nodes) in
            numberCalled = numberCalled + 1
            switch numberCalled {
            case 1:
                return child5
                
            case 2:
                return child52
            default:
                fatalError()
            }
        }
        
        XCTAssertFalse(initialNode.isLeaf)
        let node = search.select(initialNode)
        XCTAssertFalse(child5.isLeaf)
        XCTAssertTrue(child52.isLeaf)
        XCTAssertTrue(node == child52)
    }
    
    
    func testSelectNodeFromFourthLevel() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let initialNode = search.root
        let child1 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child2 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child3 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child4 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child5 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        search.root.children = [child1, child2, child3, child4, child5]
        
        let child21 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        let child22 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        let child23 = DSNode(state: DSFakeState(transition: transition), parent: child2)
        child2.children = [child21, child22, child23]
        
        let child51 = DSNode(state: DSFakeState(transition: transition), parent: child5)
        let child52 = DSNode(state: DSFakeState(transition: transition), parent: child5)
        child5.children = [child51, child52]
        
        let child511 = DSNode(state: DSFakeState(transition: transition), parent: child51)
        child51.children = [child511]
        
        var numberCalled = 0
        search.findNextToVisitReturnFunc = { (nodes) in
            numberCalled = numberCalled + 1
            switch numberCalled {
            case 1:
                return child5
            case 2:
                return child51
            case 3:
                return child511
            default:
                fatalError()
            }
        }
        
        XCTAssertFalse(initialNode.isLeaf)
        let node = search.select(initialNode)
        XCTAssertFalse(child5.isLeaf)
        XCTAssertFalse(child51.isLeaf)
        XCTAssertTrue(child511.isLeaf)
        XCTAssertTrue(node == child511)
    }
    
    func testUpdateAllParentsWithoutChangingSign() {
        
        let value = 3.0
        let visits = 1
        
        let transition = DSFakeTransition()
        let state = DSFakeState(transition: transition)
        let search = DSMonterCarloTreeSearch(initialState: state)
        let nodeLevel1_1 = DSFakeNode(state: state, parent: search.root)
        let nodeLevel1_2 = DSFakeNode(state: state, parent: search.root)
        search.root.children = [nodeLevel1_1, nodeLevel1_2]
        
        let nodeLevel2_1 = DSFakeNode(state: state, parent: nodeLevel1_1)
        nodeLevel1_1.children = [nodeLevel2_1]
        
        XCTAssertEqual(search.root.visits, 0)
        XCTAssertEqual(search.root.value, 0)
        XCTAssertEqual(nodeLevel1_1.visits, 0)
        XCTAssertEqual(nodeLevel1_1.value, 0)
        XCTAssertEqual(nodeLevel1_2.visits, 0)
        XCTAssertEqual(nodeLevel1_2.value, 0)
        XCTAssertEqual(nodeLevel2_1.visits, 0)
        XCTAssertEqual(nodeLevel2_1.value, 0)
        
        search.backpropogate(node: nodeLevel1_2, value: value, visits: visits, shouldChangeValueSign: false)
        XCTAssertEqual(search.root.visits, 1)
        XCTAssertEqual(search.root.value, 3)
        XCTAssertEqual(nodeLevel1_1.visits, 0)
        XCTAssertEqual(nodeLevel1_1.value, 0)
        XCTAssertEqual(nodeLevel1_2.visits, 1)
        XCTAssertEqual(nodeLevel1_2.value, 3)
        XCTAssertEqual(nodeLevel2_1.visits, 0)
        XCTAssertEqual(nodeLevel2_1.value, 0)
        
        search.backpropogate(node: nodeLevel2_1, value: value, visits: visits, shouldChangeValueSign: false)
        XCTAssertEqual(search.root.visits, 2)
        XCTAssertEqual(search.root.value, 6)
        XCTAssertEqual(nodeLevel1_1.visits, 1)
        XCTAssertEqual(nodeLevel1_1.value, 3)
        XCTAssertEqual(nodeLevel1_2.visits, 1)
        XCTAssertEqual(nodeLevel1_2.value, 3)
        XCTAssertEqual(nodeLevel2_1.visits, 1)
        XCTAssertEqual(nodeLevel2_1.value, 3)
        
        let nodeLevel3_1 = DSFakeNode(state: state, parent: nodeLevel2_1)
        nodeLevel2_1.children = [nodeLevel3_1]
        XCTAssertEqual(nodeLevel3_1.visits, 0)
        XCTAssertEqual(nodeLevel3_1.value, 0)
        
        search.backpropogate(node: nodeLevel3_1, value: value, visits: visits, shouldChangeValueSign: false)
        XCTAssertEqual(search.root.visits, 3)
        XCTAssertEqual(search.root.value, 9)
        XCTAssertEqual(nodeLevel1_1.visits, 2)
        XCTAssertEqual(nodeLevel1_1.value, 6)
        XCTAssertEqual(nodeLevel1_2.visits, 1)
        XCTAssertEqual(nodeLevel1_2.value, 3)
        XCTAssertEqual(nodeLevel2_1.visits, 2)
        XCTAssertEqual(nodeLevel2_1.value, 6)
        XCTAssertEqual(nodeLevel3_1.visits, 1)
        XCTAssertEqual(nodeLevel3_1.value, 3)
    }

    
    func testUpdateAllParentsWithChangingSign() {
        
        let value = 1.0
        let visits = 1
        
        let transition = DSFakeTransition()
        let state = DSFakeState(transition: transition)
        let search = DSMonterCarloTreeSearch(initialState: state)
        let nodeLevel1_1 = DSFakeNode(state: state, parent: search.root)
        let nodeLevel1_2 = DSFakeNode(state: state, parent: search.root)
        search.root.children = [nodeLevel1_1, nodeLevel1_2]
        
        let nodeLevel2_1 = DSFakeNode(state: state, parent: nodeLevel1_1)
        nodeLevel1_1.children = [nodeLevel2_1]
        
        XCTAssertEqual(search.root.visits, 0)
        XCTAssertEqual(search.root.value, 0)
        XCTAssertEqual(nodeLevel1_1.visits, 0)
        XCTAssertEqual(nodeLevel1_1.value, 0)
        XCTAssertEqual(nodeLevel1_2.visits, 0)
        XCTAssertEqual(nodeLevel1_2.value, 0)
        XCTAssertEqual(nodeLevel2_1.visits, 0)
        XCTAssertEqual(nodeLevel2_1.value, 0)
        
        search.backpropogate(node: nodeLevel1_2, value: value, visits: visits, shouldChangeValueSign: true)
        XCTAssertEqual(search.root.visits, 1)
        XCTAssertEqual(search.root.value, -1)
        XCTAssertEqual(nodeLevel1_1.visits, 0)
        XCTAssertEqual(nodeLevel1_1.value, 0)
        XCTAssertEqual(nodeLevel1_2.visits, 1)
        XCTAssertEqual(nodeLevel1_2.value, 1)
        XCTAssertEqual(nodeLevel2_1.visits, 0)
        XCTAssertEqual(nodeLevel2_1.value, 0)
        
        search.backpropogate(node: nodeLevel2_1, value: value, visits: visits, shouldChangeValueSign: true)
        XCTAssertEqual(search.root.visits, 2)
        XCTAssertEqual(search.root.value, 0)
        XCTAssertEqual(nodeLevel1_1.visits, 1)
        XCTAssertEqual(nodeLevel1_1.value, -1)
        XCTAssertEqual(nodeLevel1_2.visits, 1)
        XCTAssertEqual(nodeLevel1_2.value, 1)
        XCTAssertEqual(nodeLevel2_1.visits, 1)
        XCTAssertEqual(nodeLevel2_1.value, 1)
        
        let nodeLevel3_1 = DSFakeNode(state: state, parent: nodeLevel2_1)
        nodeLevel2_1.children = [nodeLevel3_1]
        XCTAssertEqual(nodeLevel3_1.visits, 0)
        XCTAssertEqual(nodeLevel3_1.value, 0)
        
        search.backpropogate(node: nodeLevel3_1, value: value * -1, visits: visits, shouldChangeValueSign: true)
        XCTAssertEqual(search.root.visits, 3)
        XCTAssertEqual(search.root.value, 1)
        XCTAssertEqual(nodeLevel1_1.visits, 2)
        XCTAssertEqual(nodeLevel1_1.value, -2)
        XCTAssertEqual(nodeLevel1_2.visits, 1)
        XCTAssertEqual(nodeLevel1_2.value, 1)
        XCTAssertEqual(nodeLevel2_1.visits, 2)
        XCTAssertEqual(nodeLevel2_1.value, 2)
        XCTAssertEqual(nodeLevel3_1.visits, 1)
        XCTAssertEqual(nodeLevel3_1.value, -1)
    }

    // test iterate
    func testExpandCalledOnRootWhenItsNotVisited() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let root = DSFakeNode.init(rootState: initialState)
        search._rootNode = root
        let child1 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child2 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        let child3 = DSNode(state: DSFakeState(transition: transition), parent: search.root)
        search.root.children = [child1, child2, child3]
        
        search.shouldCallIterateSearch = true
        search.stopped = false
        search.selectExpectation.expectedFulfillmentCount = 1
        search.iterate(iterationsCount: 1, completion: nil)
        
        wait(for: [root.expandExpectation, search.selectExpectation], timeout: 0.1, enforceOrder: true)
    }
    
    func testIterateNotingHappendsWhenSearchStopped() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let root = DSFakeNode.init(rootState: initialState)
        search._rootNode = root
        
        search.stopped = true
        
        search.shouldCallIterateSearch = true
        search.selectExpectation.isInverted = true
        search.backpropagateExpectation.isInverted = true
        root.expandExpectation.isInverted = true
        root.simulateExpectation.isInverted = true
        root.updateExpectation.isInverted = true
        
        search.iterate(iterationsCount: 0, completion: nil)
        
    }
    
    func testIterateNotingHappendsWhenIterationsCountIsZero() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let root = DSFakeNode.init(rootState: initialState)
        search._rootNode = root
        
        search.shouldCallIterateSearch = true
        search.stopped = false
        search.backpropagateExpectation.isInverted = true
        search.selectExpectation.isInverted = true
        root.expandExpectation.isInverted = true
        root.simulateExpectation.isInverted = true
        root.updateExpectation.isInverted = true
        search.iterate(iterationsCount: 0, completion: nil)
        
        wait(for: [root.expandExpectation, root.simulateExpectation, root.updateExpectation, search.selectExpectation, search.backpropagateExpectation], timeout: 0.1, enforceOrder: false)
    }
    
    func testNodeNotExpandedWhenNotVisited() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let node = DSFakeNode(state: DSFakeState(transition: DSFakeTransition()), parent: search.root)
        node.visits = 0
        search.selectReturnValue = node
        
        node.expandExpectation.isInverted = true
        
        search.stopped = false
        search.shouldCallIterateSearch = true
        search.iterate(iterationsCount: 1, completion: nil)
        
        wait(for: [node.expandExpectation, node.simulateExpectation, search.backpropagateExpectation], timeout: 0.1)
    }
    
    func testNonterminalNodeExpandCalledWhenVisited() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let node = DSFakeNode(state: DSFakeState(transition: DSFakeTransition()), parent: search.root)
        let child1 = DSFakeNode(state: DSFakeState(transition: DSFakeTransition()), parent: node)
        node.children = [child1]
        node.visits = 3
        node.value = 0.231
        search.selectReturnValue = node
        
        node.shouldCallExpand = false
        
        search.stopped = false
        search.shouldCallIterateSearch = true
        search.iterate(iterationsCount: 1, completion: nil)
        
        wait(for: [node.expandExpectation, child1.simulateExpectation, search.backpropagateExpectation], timeout: 0.1)
    }
    
    func testTerminalNodeExpandNotCalledWhenVisited() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let node = DSFakeNode(state: DSFakeState(transition: DSFakeTransition()), parent: search.root)
        node.fakeTerminal = true
        node.visits = 3
        node.value = 0.231
        search.selectReturnValue = node
        
        node.shouldCallExpand = false
        node.expandExpectation.isInverted = true
        
        search.stopped = false
        search.shouldCallIterateSearch = true
        search.iterate(iterationsCount: 1, completion: nil)
        
        wait(for: [node.expandExpectation, node.simulateExpectation, search.backpropagateExpectation], timeout: 0.1)
    }
    
    func testIterateCompletionCalled() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let node = DSFakeNode(state: DSFakeState(transition: DSFakeTransition()), parent: search.root)
        node.fakeTerminal = true
        search._rootNode = node
        node.shouldCallExpand = false
        search.selectReturnValue = search.root
        search.stopped = false
        search.shouldCallIterateSearch = true
        
        let completionExpectation = XCTestExpectation(description: "Completion")
        
        search.iterate(iterationsCount: 20) {
            completionExpectation.fulfill()
        }
        
        wait(for: [completionExpectation], timeout: 1)
    }
   
    func testIterateCorretctIterationsExecuted() {
        let transition = DSFakeTransition()
        let initialState = DSFakeState(transition: transition)
        let search = FakeMonterCarloTreeSearch(initialState: initialState)
        
        let node = DSFakeNode(state: DSFakeState(transition: DSFakeTransition()), parent: search.root)
        node.fakeTerminal = true
        search._rootNode = node
        node.shouldCallExpand = false
        search.selectReturnValue = search.root
        search.stopped = false
        search.shouldCallIterateSearch = true
        
        let iterations = 21
        search.backpropagateExpectation.expectedFulfillmentCount = iterations
        search.selectExpectation.expectedFulfillmentCount = iterations
        
        search.iterate(iterationsCount: UInt(iterations), completion: nil)
        
        wait(for: [search.selectExpectation, search.backpropagateExpectation], timeout: 1)

    }
}
