//
//  TypeHelper.swift
//  SwiftFlow
//
//  Created by Benjamin Encz on 11/27/15.
//  Copyright © 2015 DigiTales. All rights reserved.
//

import Foundation

func withSpecificTypes<SpecificStateType, Action>(
    state: StateType,
    action: Action,
    function: (_ state: SpecificStateType, _ action: Action) -> SpecificStateType
) -> StateType {

    guard let specificStateType = state as? SpecificStateType else { return state }

    return function(specificStateType, action) as! StateType
}