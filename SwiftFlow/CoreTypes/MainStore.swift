//
//  MainStore.swift
//  SwiftFlow
//
//  Created by Benjamin Encz on 11/11/15.
//  Copyright © 2015 DigiTales. All rights reserved.
//

import Foundation

open class MainStore: Store {

    // TODO: Setter should not be public; need way for store enhancers to modify appState anyway
    /*private (set)*/ public var appState: StateType {
        didSet {
            print("BK: new state: \(appState)")
            subscribers.forEach { $0._newState(state: appState) }
        }
    }

    private var reducer: AnyReducer
    private var subscribers: [AnyStoreSubscriber] = []

    public init(reducer: AnyReducer, appState: StateType) {
        self.reducer = reducer
        self.appState = appState
    }

    public func subscribe(subscriber: AnyStoreSubscriber) {
        subscribers.append(subscriber)
        subscriber._newState(state: appState)
    }

    public func unsubscribe(subscriber: AnyStoreSubscriber) {
        guard let index = subscribers.firstIndex(where: { $0 === subscriber }) else {
            return
        }
        
        print("BK: subscriber removed: \(index)")
        subscribers.remove(at: index)
     }

    public func dispatch(action: ActionConvertible) {
        dispatch(action: action.toAction())
    }

    public func dispatch(action: ActionType) {
        dispatch(action: action.toAction(), callback: nil)
    }

    public func dispatch(actionCreatorProvider: ActionCreator) {
        dispatch(actionCreatorProvider: actionCreatorProvider, callback: nil)
    }

    public func dispatch(asyncActionCreatorProvider: AsyncActionCreator) {
        dispatch(asyncActionCreatorProvider: asyncActionCreatorProvider, callback: nil)
    }

    public func dispatch(action: ActionType, callback: DispatchCallback?) {
        // Dispatch Asynchronously so that each subscriber receives the latest state
        // Without Async a receiver could immediately be called and emit a new state
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            self.appState = self.reducer._handleAction(state: self.appState, action: action.toAction())
            callback?(self.appState)
        }
    }

    public func dispatch(actionCreatorProvider: ActionCreator, callback: DispatchCallback?) {
        let action = actionCreatorProvider(self.appState, self)
        if let action = action {
            dispatch(action: action, callback: callback)
        }
    }

    public func dispatch(
        asyncActionCreatorProvider actionCreatorProvider: AsyncActionCreator,
        callback: DispatchCallback?
    ) {
        actionCreatorProvider(self.appState, self) { actionProvider in
            let action = actionProvider(self.appState, self)
            if let action {
                self.dispatch(action: action, callback: callback)
            }
        }
    }

}
