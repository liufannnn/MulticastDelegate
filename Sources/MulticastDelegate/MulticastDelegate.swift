//
//  MulticastDelegate.swift
//  MulticastDelegate
//
//  Created by Joao Nunes on 28/12/15.
//  Copyright © 2015 Joao Nunes. All rights reserved.
//

import Foundation

open class MulticastDelegate<T> {

    /// The delegates hash table.
    public let delegates: NSHashTable<AnyObject>

    /// Initialize a new `MulticastDelegate` specifying whether delegate references should be weak or strong.
    /// - Parameter strongReferences: Whether delegates should be strongly referenced, false by default.
    public init(strongReferences: Bool = false) {
        delegates = strongReferences ? NSHashTable<AnyObject>() : NSHashTable<AnyObject>.weakObjects()
    }

    /// Use this method to initialize a new `MulticastDelegate` specifying the storage options yourself.
    /// - Parameter options: The underlying storage options to use
    public init(options: NSPointerFunctions.Options) {
        delegates = NSHashTable<AnyObject>(options: options, capacity: 0)
    }

    /// Use this method to add a delelgate.
    /// - Parameter delegate: The delegate to be added.
    public func addDelegate(_ delegate: T) { delegates.add(delegate as AnyObject) }

    /// Use this method to remove a previously-added delegate.
    /// - Parameter delegate: The delegate to be removed.
    public func removeDelegate(_ delegate: T) { delegates.remove(delegate as AnyObject) }

    /// Use this method to invoke a closure on each delegate.
    /// - Parameter invocation: The closure to be invoked on each delegate.
    public func invokeDelegates(_ invocation: (T) -> Void) {
        for delegate in delegates.allObjects {
            if let delegate = delegate as? T { invocation(delegate) }
        }
    }

    /// Use this method to determine if the multicast delegate contains a given delegate.
    /// - Parameter delegate: The given delegate to check if it's contained
    /// - Returns: `true` if the delegate is found or `false` otherwise
    public func containsDelegate(_ delegate: T) -> Bool { delegates.contains(delegate as AnyObject) }
}
