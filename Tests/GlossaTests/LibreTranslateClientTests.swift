import XCTest
@testable import Glossa

final class LibreTranslateClientTests: XCTestCase {
    func testResolvedEndpointAppendsTranslatePathForBaseURL() throws {
        let endpoint = try XCTUnwrap(URL(string: "http://127.0.0.1:5000"))

        XCTAssertEqual(
            LibreTranslateClient.resolvedEndpoint(from: endpoint).absoluteString,
            "http://127.0.0.1:5000/translate"
        )
    }

    func testResolvedEndpointPreservesExplicitPath() throws {
        let endpoint = try XCTUnwrap(URL(string: "http://127.0.0.1:5000/api/translate"))

        XCTAssertEqual(
            LibreTranslateClient.resolvedEndpoint(from: endpoint).absoluteString,
            "http://127.0.0.1:5000/api/translate"
        )
    }
}
