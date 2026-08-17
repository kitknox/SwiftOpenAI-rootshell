import Foundation
import XCTest

@testable import SwiftOpenAI

final class ForkCompatibilityTests: XCTestCase {
  private struct TestEndpoint: Endpoint {
    func path(in openAIEnvironment: OpenAIEnvironment) -> String {
      "/v1/test"
    }
  }

  func testNoneAuthorizationOmitsHeader() throws {
    let environment = OpenAIEnvironment(
      baseURL: "https://example.com",
      proxyPath: nil,
      version: nil)

    let request = try TestEndpoint().request(
      apiKey: .none,
      openAIEnvironment: environment,
      organizationID: nil,
      method: .get)

    XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
  }

  func testCodexResponseExtensionsEncodeExpectedKeys() throws {
    let parameters = ModelResponseParameter(
      input: .array([
        .reasoning(
          ReasoningInputItem(
            summary: [.init(text: "summary")],
            encryptedContent: "encrypted"))
      ]),
      model: .gpt5Codex,
      reasoning: Reasoning(
        effort: "high",
        summary: .concise,
        context: "all_turns"),
      streamOptions: StreamOptions(
        includeObfuscation: false,
        reasoningSummaryDelivery: "sequential_cutoff"),
      text: TextConfiguration(verbosity: "low"))

    let data = try JSONEncoder().encode(parameters)
    let json = try XCTUnwrap(
      JSONSerialization.jsonObject(with: data) as? [String: Any])
    let input = try XCTUnwrap(json["input"] as? [[String: Any]])
    let reasoning = try XCTUnwrap(json["reasoning"] as? [String: Any])
    let streamOptions = try XCTUnwrap(json["stream_options"] as? [String: Any])
    let text = try XCTUnwrap(json["text"] as? [String: Any])

    XCTAssertEqual(input.first?["type"] as? String, "reasoning")
    XCTAssertEqual(input.first?["encrypted_content"] as? String, "encrypted")
    XCTAssertEqual(reasoning["context"] as? String, "all_turns")
    XCTAssertEqual(streamOptions["reasoning_summary_delivery"] as? String, "sequential_cutoff")
    XCTAssertEqual(text["verbosity"] as? String, "low")
    XCTAssertNil(text["format"])
  }
}
