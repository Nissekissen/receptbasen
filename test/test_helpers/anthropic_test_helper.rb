module AnthropicTestHelper
  # Stubs the Anthropic Messages API endpoint. Pass one JSON string per expected
  # call, in order (e.g. one for LlmParser, one for TagExtractor) — WebMock
  # returns them in sequence, and repeats the last one for any further calls.
  def stub_anthropic_messages(*texts)
    responses = texts.map do |text|
      { status: 200, body: anthropic_message_envelope(text), headers: { "Content-Type" => "application/json" } }
    end

    stub_request(:post, "https://api.anthropic.com/v1/messages").to_return(*responses)
  end

  private

  # Wraps a JSON-schema response body the way the real Anthropic Messages API
  # would, since the anthropic gem deserializes the response into typed models
  # (Anthropic::Models::Message/TextBlock/Usage) that expect this full shape.
  def anthropic_message_envelope(text)
    {
      id: "msg_test",
      type: "message",
      role: "assistant",
      model: "claude-haiku-4-5",
      content: [ { type: "text", text: text, citations: nil } ],
      stop_reason: "end_turn",
      stop_sequence: nil,
      stop_details: nil,
      container: nil,
      usage: {
        input_tokens: 100,
        output_tokens: 50,
        cache_creation: nil,
        cache_creation_input_tokens: nil,
        cache_read_input_tokens: nil,
        inference_geo: nil,
        output_tokens_details: nil,
        server_tool_use: nil,
        service_tier: nil
      }
    }.to_json
  end
end
