//
//  DSTransition.swift
//  DSMonteCarloTreeSearch
//
//  Created by Simkin Dmitry on 5/25/18.
//  Copyright © 2018 Simkin Dmitry. All rights reserved.
//

import Foundation


open class DSTransition: Equatable {
    public init() { }
    
    public static func == (lhs: DSTransition, rhs: DSTransition) -> Bool {
        return lhs.equalTo(rhs: rhs)
    }
    
    open func equalTo(rhs: DSTransition) -> Bool {
        fatalError()
    }
}
