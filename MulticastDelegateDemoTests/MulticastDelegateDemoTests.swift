//
//  MulticastDelegateDemoTests.swift
//  MulticastDelegateDemoTests
//
//  Created by Joao Nunes on 28/12/15.
//  Copyright © 2015 Joao Nunes. All rights reserved.
//

import XCTest
@testable import MulticastDelegateDemo

protocol TestDelegate {
	
	func doThis()
	func doThis(value: Int)
	
}

class DelegateTestClass: TestDelegate {
	
	func doThis() {
		// do nothing
	}
	func doThis(value: Int) {
		print(value)
	}
}


class ServiceTestClass {
	
	var delegate = MulticastDelegate<TestDelegate>()
	
	func imReady() -> Bool {
		
        delegate.invokeDelegates { delegate in
            delegate.doThis()
        }

		return true
	}
	
	func imReadyAgain() {
		
		delegate.invokeDelegates { delegate in
			
			delegate.doThis(value: 1)
			
		}
	}
}

class CopyTestDelegate: NSObject, NSCopying {

    var value: Int
    
    init(value: Int) {
        self.value = value
    }
    
    @objc func copy(with: NSZone?) -> Any {
        return CopyTestDelegate(value: value)
    }
}

func ==(lhs: CopyTestDelegate, rhs: CopyTestDelegate) -> Bool {
    return lhs.value == rhs.value
}

struct TestStruct: TestDelegate {
    
    func doThis() {
        // do nothing
    }
    
    func doThis(value: Int) {
        print(value)
    }
}


class MulticastDelegateDemoTests: XCTestCase {
		
    // MARK: - Object Lifecycle - Tests
    
    func testInitUsesWeakReferencesByDefault() {
        
        let multicastDelegate = MulticastDelegate<TestDelegate>()
        
        autoreleasepool {
            let demoDelegateClass = DelegateTestClass()
            multicastDelegate.addDelegate(demoDelegateClass)
        }
        
        var delegatesCalled = 0
        multicastDelegate.invokeDelegates { _ in
            delegatesCalled += 1
        }
        
        XCTAssertEqual(delegatesCalled, 0)
    }
    
    func testInitWithStrongReferencesUsesStrongDelegateStorage() {
        
        let multicastDelegate = MulticastDelegate<TestDelegate>(strongReferences: true)
        
        autoreleasepool {
            let demoDelegateClass = DelegateTestClass()
            multicastDelegate.addDelegate(demoDelegateClass)
        }
        
        var delegatesCalled = 0
        multicastDelegate.invokeDelegates { _ in
            delegatesCalled += 1
        }
        
        XCTAssertEqual(delegatesCalled, 1)
    }
    
    func testInitWithOptionsUsesOptionsToSpecifyStorage() {
        
        let multicastDelegate = MulticastDelegate<CopyTestDelegate>(options: [.strongMemory, .objectPersonality])
        weak var weakDelegate: CopyTestDelegate?

        autoreleasepool {
            
            let delegate = CopyTestDelegate(value: 42)
            multicastDelegate.addDelegate(delegate)
            weakDelegate = delegate
        }
		
		XCTAssertNotNil(weakDelegate)
        XCTAssertTrue(multicastDelegate.containsDelegate(weakDelegate!))
    }
    
    // MARK: - Invoking Delegates - Tests
    
    func testMulticast() {
		
		let multicastDelegate = MulticastDelegate<TestDelegate>()
		let demoDelegateClass = DelegateTestClass()
		
        multicastDelegate.addDelegate(demoDelegateClass)
		
		var delegatesCalled = 0
        multicastDelegate.invokeDelegates { delegate in
            delegate.doThis()
            delegatesCalled += 1
        }
		
		XCTAssertEqual(delegatesCalled,1)

    }
	
	func testMultipleMulticast() {
		
		let multicastDelegate = MulticastDelegate<TestDelegate>()
		let demoDelegateClass = DelegateTestClass()
		let demoDelegateClass2 = DelegateTestClass()
        
        multicastDelegate.addDelegate(demoDelegateClass)
        multicastDelegate.addDelegate(demoDelegateClass2)
		
		var delegatesCalled = 0
        multicastDelegate.invokeDelegates { delegate in
            delegatesCalled += 1
            delegate.doThis(value: delegatesCalled)
        }
		
		XCTAssert(delegatesCalled == 2,"Must be 2")
		
        multicastDelegate.removeDelegate(demoDelegateClass2)
        multicastDelegate.removeDelegate(demoDelegateClass)
		delegatesCalled = 0
        multicastDelegate.invokeDelegates { delegate in
            delegatesCalled += 1
            delegate.doThis(value: delegatesCalled)
        }
		XCTAssertEqual(delegatesCalled,0)
		
	}
	
	func testTypicalCase() {
		
		let service = ServiceTestClass()
		let demoDelegateClass = DelegateTestClass()
		
        service.delegate.addDelegate(demoDelegateClass)
		
		XCTAssertTrue(service.imReady(),"Ready failed")
		
	}
	
	func testStructNotAccepted() {
		
		let multicastDelegate = MulticastDelegate<TestDelegate>()
		let myStruct = TestStruct()
		
        multicastDelegate.addDelegate(myStruct)
        
		var delegatesCalled = 0
        multicastDelegate.invokeDelegates { delegate in
            delegatesCalled += 1
            delegate.doThis(value: delegatesCalled)
        }
		XCTAssertEqual(delegatesCalled,0)
		
	}
	
	func testMulticastDealloc() {
		
		let multicastDelegate = MulticastDelegate<TestDelegate>()
		var delegatesCalled = 0
		
		autoreleasepool {
			var demoDelegateClass: DelegateTestClass? = DelegateTestClass()
			
            multicastDelegate.addDelegate(demoDelegateClass!)
			
            multicastDelegate.invokeDelegates { delegate in
                delegate.doThis()
                delegatesCalled += 1
            }
			XCTAssertEqual(delegatesCalled,1)
			
			
			demoDelegateClass = nil
		}
		
		delegatesCalled = 0
        multicastDelegate.invokeDelegates { delegate in
            delegate.doThis()
            delegatesCalled += 1
        }
		
		XCTAssertEqual(delegatesCalled,0)
		
	}
	
    func testContainsDelegateStructReturnsFalse() {
        let multicastDelegate = MulticastDelegate<TestDelegate>()
        let myStruct = TestStruct()
        multicastDelegate.addDelegate(myStruct) // isn't actually allowed
    
        XCTAssertFalse(multicastDelegate.containsDelegate(myStruct))
    }
    
    func testContainsDelegatePreviouslyAddedDelegateReturnsTrue() {
        
        let multicastDelegate = MulticastDelegate<TestDelegate>()
        let delegate = DelegateTestClass()
        multicastDelegate.addDelegate(delegate)
        
        XCTAssertTrue(multicastDelegate.containsDelegate(delegate))
    }
    
    func testContainsDelegateNeverAddedDelegateReturnsFalse() {
        
        let multicastDelegate = MulticastDelegate<TestDelegate>()
        let delegate = DelegateTestClass()
        
        XCTAssertFalse(multicastDelegate.containsDelegate(delegate))
    }
    
    func testEmptyAfterCreation() {
        
        let multicastDelegate = MulticastDelegate<TestDelegate>()
        
        XCTAssertTrue(multicastDelegate.delegates.allObjects.isEmpty)
    }
    
    func testNotEmptyAfterAdd() {
        
        let multicastDelegate = MulticastDelegate<TestDelegate>()
        multicastDelegate.addDelegate(DelegateTestClass())
        
        XCTAssertFalse(multicastDelegate.delegates.allObjects.isEmpty)
    }
    
    func testNotEmptyAfterDoubleAdd() {
        
        let multicastDelegate = MulticastDelegate<TestDelegate>()

        multicastDelegate.addDelegate(DelegateTestClass())
        multicastDelegate.addDelegate(DelegateTestClass())
        XCTAssertFalse(multicastDelegate.delegates.allObjects.isEmpty)
    }
    
    func testEmptyAfterAddAndDelete() {
        
        let multicastDelegate = MulticastDelegate<TestDelegate>()
        let delegate = DelegateTestClass()

        multicastDelegate.addDelegate(delegate)
        multicastDelegate.removeDelegate(delegate)
        
        XCTAssertTrue(multicastDelegate.delegates.allObjects.isEmpty)
    }
    
}
