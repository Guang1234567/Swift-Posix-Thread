import Foundation

private class PThreadParam {
    let mBlock: () throws -> Any?
    
    var mResult: Any?
    
    init(_ block: @escaping () throws -> Any?) {
        mBlock = block
    }
}

/// c function
#if os(Android)
private func cStartRoutine(pPThreadParam: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? {
    let pStatus = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
    defer {
        pStatus.deallocate()
    }
    pStatus.pointee = EXIT_SUCCESS
    
    if let pPThreadParam = pPThreadParam {
        defer {
            pPThreadParam.deallocate()
        }
        
        let pthreadParam = pPThreadParam.load(as: PThreadParam.self)
        
        do {
            pthreadParam.mResult = try pthreadParam.mBlock()
        } catch {
            pStatus.pointee = EXIT_FAILURE
        }
    }
    
    pthread_exit(pStatus)
}

#else
private func cStartRoutine(pPThreadParam: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
    let pStatus = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
    defer {
        pStatus.deallocate()
    }
    pStatus.pointee = EXIT_SUCCESS
    
    defer {
        pPThreadParam.deallocate()
    }
    
    let pthreadParam = pPThreadParam.load(as: PThreadParam.self)
    
    do {
        pthreadParam.mResult = try pthreadParam.mBlock()
    } catch {
        pStatus.pointee = EXIT_FAILURE
    }
    
    pthread_exit(pStatus)
}
#endif

public class PosixThread<Result> {
    private var mPThread: pthread_t?
    
    private let mPThreadParam: PThreadParam
    
    private init?(_ pthreadParam: PThreadParam) {
        //
        #if os(Android)
        let pPThread = UnsafeMutablePointer<pthread_t>.allocate(capacity: 1)
        #else
        let pPThread = UnsafeMutablePointer<pthread_t?>.allocate(capacity: 1)
        #endif
        defer {
            pPThread.deallocate()
        }
        
        //
        mPThreadParam = pthreadParam
        let pPThreadParameter = UnsafeMutablePointer<PThreadParam>.allocate(capacity: 1)
        pPThreadParameter.pointee = mPThreadParam
        
        //
        let pAttibutes = UnsafeMutablePointer<pthread_attr_t>.allocate(capacity: 1)
        defer {
            pthread_attr_destroy(pAttibutes)
        }
        guard pthread_attr_init(pAttibutes) == 0 else {
            return nil
        }
        guard pthread_attr_setdetachstate(pAttibutes, PTHREAD_CREATE_JOINABLE) == 0 else {
            return nil
        }
        
        //
        let status: Int32 = pthread_create(pPThread, pAttibutes, cStartRoutine, pPThreadParameter)
        mPThread = pPThread.pointee
        
        guard status == 0, let _ = mPThread else {
            return nil
        }
    }
    
    public convenience init?(_ block: @escaping () throws -> Result?) {
        self.init(PThreadParam {
            try block()
        })
    }
    
    public convenience init?<Param>(_ threadParameter: Param, _ block: @escaping (_ threadParameter: Param) throws -> Result?) {
        self.init(PThreadParam {
            try block(threadParameter)
        })
    }
    
    public func join() -> Result? {
        if let pthread = mPThread {
            let ppStatus = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 1)
            defer {
                ppStatus.deallocate()
            }
            
            guard pthread_join(pthread, ppStatus) == 0 else {
                return nil
            }
            
            mPThread = nil
            
            if let pStatus: UnsafeMutableRawPointer = ppStatus.pointee {
                defer {
                    pStatus.deallocate()
                }
                if EXIT_SUCCESS == pStatus.load(as: Int32.self) {
                    if let result = mPThreadParam.mResult {
                        return result as? Result
                    } else {
                        return nil
                    }
                } else {
                    return nil
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    /// pthread_detach(3C) 是 pthread_join(3C) 的替代函数，可回收创建时 detachstate 属性设置为 PTHREAD_CREATE_JOINABLE 的线程的存储空间。
    /// https://docs.oracle.com/cd/E19253-01/819-7051/6n919hpa9/index.html#tlib-12602
    public func detach() -> Bool {
        if let pthread = mPThread {
            if pthread_detach(pthread) == 0 {
                mPThread = nil
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    public func cancel() -> Bool {
        if let pthread = mPThread {
            #if os(Android)
            // ndk 20
            // bits/posix_limits.h:86:#define _POSIX_THREADS _POSIX_VERSION /* Strictly, pthread_cancel/pthread_testcancel are missing. */
            return false
            #else
            if pthread_cancel(pthread) == 0 {
                mPThread = nil
                return true
            } else {
                return false
            }
            #endif
        } else {
            return false
        }
    }
    
    deinit {
        // Anyway, force detach a joinable thread to avoid memory leak.
        _ = detach()
    }
}
