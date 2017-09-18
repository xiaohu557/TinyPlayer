//
//  Observable.swift
//  TinyPlayerDemo
//
//  Created by Kevin Chen on 08.09.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

public class Observable<T> {
    public typealias Observer = (T) -> Void
    private var observers = [UUID: Observer]()

    private(set) var value: T {
        didSet {
            observers.forEach {
                $0.value(value)
            }
        }
    }

    public init(_ value: T) {
        self.value = value
    }

    public func next(_ value: T) {
        self.value = value
    }

    public func observe(_ observer: @escaping Observer) {
        let id = UUID()
        observers[id] = observer
        observer(value)
    }
}
