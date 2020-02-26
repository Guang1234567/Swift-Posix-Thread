
import Foundation

public class PosixRwLock {
    private let pLock: UnsafeMutablePointer<pthread_rwlock_t>

    deinit {
        if pthread_rwlock_destroy(pLock) == 0 {
            // success
        }
        pLock.deallocate()
    }

    public init? () {
        pLock = UnsafeMutablePointer<pthread_rwlock_t>.allocate(capacity: 1)

        guard pthread_rwlock_init(pLock, nil) == 0 else {
            pLock.deallocate()
            return nil
        }
    }

    public func withRead<R>(fallbackValue: R? = nil, _ block: () -> R) -> R? {
        var result: R? = fallbackValue
        if pthread_rwlock_rdlock(pLock) == 0 {
            defer {
                if pthread_rwlock_unlock(pLock) == 0 {
                    // unlock fail
                }
            }
            result = block()
        }
        return result
    }

    public func withWrite<R>(fallbackValue: R? = nil, _ block: () -> R) -> R? {
        var result: R? = fallbackValue
        if pthread_rwlock_wrlock(pLock) == 0 {
            defer {
                if pthread_rwlock_unlock(pLock) == 0 {
                    // unlock fail
                }
            }
            result = block()
        }
        return result
    }
}
