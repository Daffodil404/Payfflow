import XCTest
@testable import PayflowiOS

final class WorkSessionTests: XCTestCase {
    func testEarningsAccumulateFromElapsedWholeSeconds() {
        let start = Date(timeIntervalSince1970: 1_000)
        let session = WorkSession(startedAt: start, grossPerSecond: Decimal(string: "0.125")!)

        XCTAssertEqual(session.elapsedSeconds(at: start), 0)
        XCTAssertEqual(session.grossEarnings(at: start.addingTimeInterval(0.9)), 0)
        XCTAssertEqual(session.grossEarnings(at: start.addingTimeInterval(1)), Decimal(string: "0.125"))
        XCTAssertEqual(session.grossEarnings(at: start.addingTimeInterval(2)), Decimal(string: "0.25"))
        XCTAssertEqual(session.elapsedSeconds(at: start.addingTimeInterval(65)), 65)
    }

    func testStopFreezesElapsedTimeAndEarnings() {
        let start = Date(timeIntervalSince1970: 1_000)
        var session = WorkSession(startedAt: start, grossPerSecond: Decimal(1))
        session.stop(at: start.addingTimeInterval(10))

        XCTAssertFalse(session.isRunning)
        XCTAssertEqual(session.elapsedSeconds(at: start.addingTimeInterval(100)), 10)
        XCTAssertEqual(session.grossEarnings(at: start.addingTimeInterval(100)), Decimal(10))
    }

    func testClockBeforeStartDoesNotCreateNegativeEarnings() {
        let start = Date(timeIntervalSince1970: 1_000)
        let session = WorkSession(startedAt: start, grossPerSecond: Decimal(1))

        XCTAssertEqual(session.elapsedSeconds(at: start.addingTimeInterval(-5)), 0)
        XCTAssertEqual(session.grossEarnings(at: start.addingTimeInterval(-5)), 0)
    }

    func testStoredSessionRestoresAfterRelaunch() throws {
        let suite = "WorkSessionTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let start = Date(timeIntervalSince1970: 1_000)
        let session = WorkSession(startedAt: start, grossPerSecond: Decimal(string: "0.125")!)
        WorkSessionStore.save(session, defaults: defaults)

        let restored = try XCTUnwrap(WorkSessionStore.load(defaults: defaults))
        XCTAssertTrue(restored.isRunning)
        XCTAssertEqual(restored.grossEarnings(at: start.addingTimeInterval(10)), Decimal(string: "1.25"))

        var stopped = restored
        stopped.stop(at: start.addingTimeInterval(10))
        WorkSessionStore.save(stopped, defaults: defaults)
        let restoredStopped = try XCTUnwrap(WorkSessionStore.load(defaults: defaults))
        XCTAssertFalse(restoredStopped.isRunning)
        XCTAssertEqual(restoredStopped.grossEarnings(at: start.addingTimeInterval(100)), Decimal(string: "1.25"))
    }
}
