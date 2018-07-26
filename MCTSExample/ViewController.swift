//
//  ViewController.swift
//  MCTSExample
//
//  Created by Simkin Dmitry on 6/19/18.
//  Copyright © 2018 Simkin Dmitry. All rights reserved.
//

import UIKit
import DSMonteCarloTreeSearch


class CollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
}

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var whosTurn = Value.X
    var field: Field!
    var mcts: DSMonterCarloTreeSearch!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.field = Field()
    }
    @IBAction func retryButtonPressed(_ sender: Any) {
        self.field = Field()
        self.whosTurn = .X
        self.collectionView.reloadData()
        if self.mcts != nil {
            self.mcts.stop()
            self.mcts = nil;
        }
    }
    
    var rootNode: DSNode?
    var lastMove: Int!
    
    func makeAIMove() {
        if self.mcts == nil {
            let transition = TicTacToeTransition(index: nil, value: .O)
            let state = TicTacToeState(transition: transition, field: self.field, whosTurn: self.whosTurn)
            self.mcts = DSMonterCarloTreeSearch(initialState: state)
            self.mcts.shouldChangeValueSignDuringBackpropagation = true
//        let C = 1.41
            let C = 30.0
//        let C = 100.0
            self.mcts.ucb1 = { (node, rootNode) in
                let value = node.value / Double(node.visits) + C * sqrt(log(Double(rootNode.visits)) / Double(node.visits))
                return value
            }
        } else {
            let transition = TicTacToeTransition(index: self.lastMove, value: .X)
            let state = TicTacToeState(transition: transition, field: self.field, whosTurn: self.whosTurn)
            self.mcts.updateRootState(state)
        }
        
        let timeFrame = DispatchTimeInterval.seconds(3)
//        let timeFrame = DispatchTimeInterval.seconds(2)
//        let timeFrame = DispatchTimeInterval.milliseconds(300)
        self.mcts.start(timeFrame: timeFrame) { (result) in
            self.rootNode = result!.bestNode
            let tttTransition = result!.bestNode.state.transition as! TicTacToeTransition
            guard self.whosTurn == .O else {
                return
            }
            if self.field.items[tttTransition.index!] == nil {
                self.field.setValue(Value.O, at: tttTransition.index!)
                self.whosTurn = self.whosTurn.opposite()
                self.collectionView.reloadData()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CollectionViewCell
        let item = self.field.items[indexPath.row]
        var text = ""
        if let item = item {
            text = item == .X ? "X" : "O"
        }
        cell.label.text = text
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard self.whosTurn == .X, self.field.state == .undetermined else {
            return
        }
        if self.field.items[indexPath.row] == nil {
            self.field.setValue(Value.X, at: indexPath.row)
            self.whosTurn = self.whosTurn.opposite()
            self.lastMove = indexPath.row
            self.collectionView.reloadData()
            if self.field.state == .undetermined {
                self.makeAIMove()
            }
        }
    }
}

