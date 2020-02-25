# Swift-Posix-Thread

## Usage

```swift

import Foundation

class ThreadParameter {
    var threadIdentifier: String
    init(_ threadIdentifier: String) {
        self.threadIdentifier = threadIdentifier
    }
}

class ThreadResult {
    var result: String
    init(_ result: String) {
        self.result = result
    }
}

print("main Thread \(Thread.current)")

if let pthread: PosixThread<ThreadResult> = PosixThread(ThreadParameter("Posix_Thread_007"), { (input: ThreadParameter) in

    print("start a new thread")

    print("current Thread \(Thread.current)")

    print("input = \(input.threadIdentifier)")

    return ThreadResult("I am a result")
}) {
    let threadResult: ThreadResult? = pthread.join()
    if let threadResult = threadResult {
        print("result = \(threadResult.result)")
    } else {
        print("result = nil")
    }
} else {
    print("create Posix thread fail!")
}

print("\n--------------------------------------\n")

if let pthread2: PosixThread<Void> = PosixThread({ () in

    print("2start a new thread return void")

    print("2current Thread \(Thread.current)")

    print("2 no input param")

    return ()
}) {
    let threadResult: Void? = pthread2.join()
    if let threadResult = threadResult {
        print("result2 = \(threadResult)")
    } else {
        print("result2 = nil")
    }
} else {
    print("create Posix thread2 fail!")
}


```
