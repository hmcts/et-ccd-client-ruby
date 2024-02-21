RSpec.shared_examples "common POST exception handling examples" do
  it "re raises the response with the response body available under error conditions with detailed message" do
    # Arrange - stub the url
    resp_body = {
      "status": 422,
      "path": "/caseworkers/22/jurisdictions/EMPLOYMENT/case-types/EmpTrib_MVP_1.0_Manc/cases",
      "details": {
        "field_errors": [
          {
            "id": "claimantType.claimant_addressUK.PostCode",
            "message": "1065^&%$£@():?><*& exceed maximum length 14"
          }
        ]
      }
    }.to_json
    stub_request(:post, url).
      to_return(body: resp_body, status: 422)

    # Act and Assert
    aggregate_failures "Exception should be raised" do
      expect(action).to raise_error(EtCcdClient::Exceptions::UnprocessableEntity) do |error|
        expect(error.message).to include("claimantType.claimant_addressUK.PostCode => 1065^&%$£@():?><*& exceed maximum length 14")
      end
    end
  end

  it 're raises the exception with a conflict when a 409 is received' do
    # Arrange - stub the url
    resp_body = '{"message": "Conflict"}'
    stub_request(:post, url).
      to_return(body: resp_body, status: 409)

    # Act and Assert
    aggregate_failures "Exception should be raised" do
      expect(action).to raise_error(EtCcdClient::Exceptions::Conflict) do |error|
        expect(error.message).to include("Conflict")
      end
    end
  end

  it "re raises the response with the response body available under error conditions with standard message" do
    # Arrange - stub the url
    resp_body = '{"message": "Unauthorized"}'
    stub_request(:post, url).
      to_return(body: resp_body, status: 401)

    # Act and Assert
    aggregate_failures "Both exception should be raised and log should be recorded" do
      expect(action).to raise_error(EtCcdClient::Exceptions::Base) do |error|
        expect(error.message).to include("Unauthorized")
      end
    end
  end

  it "raises an error with the url present if the server responds with an error" do
    # Arrange - stub the url
    resp_body = '{"message": "Not Found"}'
    stub_request(:post, url).
      to_return(body: resp_body, status: 404)

    # Assert
    expect(action).to raise_error(EtCcdClient::Exceptions::Base, "404 Not Found - Not Found ('#{url}')")
  end

end
