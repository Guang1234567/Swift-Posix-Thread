
import Foundation

public class PosixSemaphore {
    private let pSemaphore: UnsafeMutablePointer<sem_t>

    deinit {
        if sem_destroy(pSemaphore) == 0 {
            // success
        }
        pSemaphore.deallocate()
    }

    public init? (initValue: UInt32) {
        pSemaphore = UnsafeMutablePointer<sem_t>.allocate(capacity: 1)

        guard sem_init(pSemaphore, 0, initValue) == 0 else {
            pSemaphore.deallocate()
            return nil
        }
    }

    public func wait() {
        if sem_wait(pSemaphore) == 0 {}
    }

    public func post() {
        if sem_post(pSemaphore) == 0 {}
    }
}
