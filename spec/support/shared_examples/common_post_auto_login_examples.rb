RSpec.shared_examples "common POST auto login examples" do
  it "calls login if a 403 is returned from the server and tries again returning success the second time" do
    # Arrange - stub the url
    stub_request(:post, url).
      to_return({ body: '{"error":"Forbidden"}', status: 403 }, { body: '{"test":"value"}', status: 200 })

    # Act - Call the method
    action.call

    # Assert
    expect(mock_idam_client).to have_received(:login).with(no_args).once
  end

  it "returns a successful response if a 403 is returned from the server and tries again returning success the second time" do
    # Arrange - stub the url
    stub_request(:post, url).
      to_return({ body: '{"error":"Forbidden"}', status: 403 }, { body: '{"test":"value"}', status: 200 })

    # Act - Call the method
    result = action.call

    # Assert
    expect(result).to eql("test" => "value")
  end

  it "raises a forbidden error if a 403 is returned twice from the server" do
    # Arrange - stub the url
    stub_request(:post, url).
      to_return({ body: '{"error":"Forbidden"}', status: 403 }, { body: '{"error":"Forbidden"}', status: 403 }, { body: '{"test":"value"}', status: 200 })

    # Act and Assert
    expect(action).to raise_error(EtCcdClient::Exceptions::Forbidden)
  end

end
