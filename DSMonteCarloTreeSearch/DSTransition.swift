//
//  DSTransition.swift
//  DSMonteCarloTreeSearch
//
//  Created by Simkin Dmitry on 5/25/18.
//  Copyright © 2018 Simkin Dmitry. All rights reserved.
//

import Foundation

/// Generic transition interface
protocol DSTransitionProtocol: Equatable {
    /// Return wheteer transition is equal to 'rhs' transition
    ///
    /// - parameters:
    ///   - rhs: object to compare to
    /// - retunrs: equal or not
    func equalTo(rhs: DSTransition) -> Bool
}

/// Abstarct class that represents generic transitions between statee
/// Inherit from it and implement DSTransitionProtocol
open class DSTransition: DSTransitionProtocol {
    public init() { }
    
    public static func == (lhs: DSTransition, rhs: DSTransition) -> Bool {
        return lhs.equalTo(rhs: rhs)
    }
    
    open func equalTo(rhs: DSTransition) -> Bool {
        fatalError()
    }
}
