//
//  SwiftFlowTests.swift
//  SwiftFlowTests
//
//  Created by Benjamin Encz on 11/27/15.
//  Copyright © 2015 DigiTales. All rights reserved.
//

import XCTest
@testable import SwiftFlow

struct TestAppState: StateType {
    var testValue: Int?

    init() {
        testValue = nil
    }
}

struct SetValueAction: ActionConvertible {

    let value: Int
    static let type = "SetValueAction"
    
    init (_ value: Int) {
        self.value = value
    }

    init(_ action: Action) {
        self.value = action.payload!["value"] as! Int
    }

    func toAction() -> Action {
        return Action(type: SetValueAction.type, payload: ["value": value as AnyObject])
    }

}

struct TestReducer: Reducer {
    typealias ReducerStateType = TestAppState
    
    func handleAction(state: TestAppState, action: Action) -> TestAppState {
        switch action.type {
        case SetValueAction.type:
            var newState = state
            newState.testValue = SetValueAction(action).value
            return newState
        default:
            abort()
        }
    }
}

class TestStoreSubscriber: StoreSubscriber {
    var receivedStates: [TestAppState] = []

    func newState(state: TestAppState) {
        receivedStates.append(state)
    }
}

class StoreTests: XCTestCase {

    var store: Store!
    var reducer: TestReducer!

    override func setUp() {
        super.setUp()

        reducer = TestReducer()
        store = MainStore(reducer: reducer, appState: TestAppState())
    }

    func testDispatchesInitialValueUponSubscription() {
        let expectation = expectation(description: "Sends initial value")
        store = MainStore(reducer: reducer, appState: TestAppState())
        let subscriber = TestStoreSubscriber()
        
        store.dispatch(action: SetValueAction(3)) { newState in
            if (subscriber.receivedStates.last?.testValue == 3) {
                expectation.fulfill()
            } else {
                print("BK: No!!")
            }
                
        }
        
        store.subscribe(subscriber: subscriber)
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testDoesNotDispatchValuesWhenUnsubscribed() {
        let expectation = expectation(description: "Sends subsequent values")
        store = MainStore(reducer: reducer, appState: TestAppState())
        let subscriber = TestStoreSubscriber()

        store.dispatch(action: SetValueAction(5))
        store.subscribe(subscriber: subscriber)
        store.dispatch(action: SetValueAction(10))

        // Let Run Loop Run so that dispatched actions can be performed
        RunLoop.current.run(mode: .default, before: .distantFuture)

        store.unsubscribe(subscriber: subscriber)
        // Following value is missed due to not being subscribed:
        store.dispatch(action: SetValueAction(15))
        store.dispatch(action: SetValueAction(25))

        // Let Run Loop Run so that dispatched actions can be performed
        RunLoop.current.run(mode: .default, before: .distantFuture)

        store.subscribe(subscriber: subscriber)

        store.dispatch(action: SetValueAction(20)) { newState in
            print("BK states: \(subscriber.receivedStates)")
            if subscriber.receivedStates[subscriber.receivedStates.count - 1].testValue == 20,
               subscriber.receivedStates[subscriber.receivedStates.count - 2].testValue == 25,
               subscriber.receivedStates[subscriber.receivedStates.count - 3].testValue == 10,
               subscriber.receivedStates[subscriber.receivedStates.count - 4].testValue == 5{
                    expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

}
