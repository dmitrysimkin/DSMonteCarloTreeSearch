//
//  DSFakeTransition.swift
//  DSMonteCarloTreeSearchTests
//
//  Created by Simkin Dmitry on 6/16/18.
//  Copyright © 2018 Simkin Dmitry. All rights reserved.
//

import Foundation

class DSFakeTransition: DSTransition {
    override func equalTo(rhs: DSTransition) -> Bool {
        let equal = self === rhs
        return equal;
    }
}
