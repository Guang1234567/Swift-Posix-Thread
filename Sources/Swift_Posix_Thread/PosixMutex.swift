
import Foundation

public class PosixMutex {
    private let pMutex: UnsafeMutablePointer<pthread_mutex_t>

    deinit {
        if pthread_mutex_destroy(pMutex) == 0 {
            // success
        }
        pMutex.deallocate()
    }

    public init? () {
        pMutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)

        guard pthread_mutex_init(pMutex, nil) == 0 else {
            pMutex.deallocate()
            return nil
        }
    }

    public func with<R>(fallbackValue: R? = nil, _ block: () -> R) -> R? {
        var result: R? = fallbackValue
        if pthread_mutex_lock(pMutex) == 0 {
            defer {
                if pthread_mutex_unlock(pMutex) == 0 {
                    // unlock fail
                }
            }
            result = block()
        }
        return result
    }
}
