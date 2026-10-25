import XCTest

@MainActor
final class DuoFlickSettingsUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    override func tearDown() async throws {
        XCUIDevice.shared.orientation = .portrait
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launch()
        if app.buttons["手順を見る"].waitForExistence(timeout: 5) {
            app.buttons["手順を見る"].tap()
            for _ in 0..<6 where !app.buttons["閉じる"].isHittable { app.swipeUp() }
            app.buttons["閉じる"].tap()
        }
        return app
    }

    private func openDuoSettings(_ app: XCUIApplication) {
        app.descendants(matching: .any)["設定"].firstMatch.tap()
        let duo = app.buttons["duo-flick-settings"]
        XCTAssertTrue(duo.waitForExistence(timeout: 5))
        duo.tap()
        XCTAssertTrue(app.switches["duo-flick-enabled"].waitForExistence(timeout: 5))
    }

    private func rotate(_ orientation: UIDeviceOrientation, app: XCUIApplication) {
        XCUIDevice.shared.orientation = orientation
        let landscape = orientation == .landscapeLeft || orientation == .landscapeRight
        let settled = NSPredicate { _, _ in
            let frame = app.windows.firstMatch.frame
            return (frame.width > frame.height) == landscape
        }
        let expectation = XCTNSPredicateExpectation(predicate: settled, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
    }

    func test_settingsDestinationSurvivesRotation() {
        let app = launchApp()
        openDuoSettings(app)
        for orientation in [UIDeviceOrientation.landscapeLeft, .landscapeRight, .portrait] {
            rotate(orientation, app: app)
            let enabled = app.switches["duo-flick-enabled"]
            XCTAssertTrue(enabled.waitForExistence(timeout: 5))
            XCTAssertTrue(enabled.isHittable)
            XCTAssertGreaterThan(enabled.frame.width, 0)
            XCTAssertTrue(app.frame.contains(enabled.frame))
            let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            screenshot.name = "Duo-settings-\(orientation.rawValue)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
    }

}
