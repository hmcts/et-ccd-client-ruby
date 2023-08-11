require 'spec_helper'
require 'et_ccd_client'
require 'rotp'
RSpec.describe EtCcdClient::IdamClient do
  subject(:client) { described_class.new config: mock_config }

  let(:test_secret) { 'AAAAAAAAAAAAAAAC' }
  let(:mock_config) { instance_double(EtCcdClient::Config, mock_config_values) }
  let(:mock_config_values) do
    {
      auth_base_url: 'http://auth.mock.com',
      idam_base_url: 'http://idam.mock.com',
      data_store_base_url: 'http://data.mock.com',
      jurisdiction_id: 'mockjid',
      microservice: 'mockmicroservice',
      microservice_secret: test_secret,
      logger: mock_logger,
      user_id: 51,
      initiate_claim_event_id: 'mockinitiateevent',
      initiate_case_url: 'http://data.mock.com/caseworkers/{uid}/jurisdictions/{jid}/case-types/{ctid}/event-triggers/{etid}/token',
      create_case_url: 'http://data.mock.com/caseworkers/{uid}/jurisdictions/{jid}/case-types/{ctid}/cases',
      idam_service_token_exchange_url: "http://auth.mock.com/lease",
      idam_user_token_exchange_url: "http://idam.mock.com/loginUser",
      use_sidam: true,
      sidam_username: 'm@m.com',
      sidam_password: 'p',
      verify_ssl: false,
      user_details_url: "http://idam.mock.com/details",
      proxy: false
    }
  end
  let(:mock_logger) do
    instance_spy('ActiveSupport::Logger').tap do |spy|
      allow(spy).to receive(:tagged) do |_arg1, &block|
        block.call
      end
    end
  end
  let(:mock_positive_response) do
    {
      "access_token": "myusertoken",
      "scope": "acr openid profile roles authorities",
      "id_token": "myidtokenshouldntbeused",
      "token_type": "Bearer",
      "expires_in": "28799",
      "api_auth_token": "myauthapitokenshouldntbeused"
    }.to_json
  end

  describe "#login" do
    it "calls the service auth provider service with a otp" do

      # Arrange - Setup the stubs
      user_details = { 'id' => 'mockid', 'roles' => ['mockrole1', 'mockrole2'] }
      stub_request(:post, "http://auth.mock.com/lease").with(body: { 'microservice': 'mockmicroservice', 'oneTimePassword': an_instance_of(String) }).to_return do |_request|
        { body: "myservicetoken" }
      end
      stub_request(:post, "http://idam.mock.com/loginUser").with(body: { 'username': 'm@m.com', password: 'p' }).to_return(body: mock_positive_response)
      stub_request(:get, "http://idam.mock.com/details").with(headers: { 'Accept' => 'application/json', 'Authorization' => 'myusertoken' }).to_return(status: 200, body: user_details.to_json)

      # Act
      client.login(username: 'm@m.com', password: 'p')

      # Assert - Make sure the tokens are available to others
      expect(client).to have_attributes service_token: 'myservicetoken', user_token: 'myusertoken', user_details: user_details
    end

    it "validates the otp" do

      # Arrange - Setup the stubs
      totp = ROTP::TOTP.new(test_secret)
      user_details = { 'id' => 'mockid', 'roles' => ['mockrole1', 'mockrole2'] }
      stub_request(:post, "http://auth.mock.com/lease").with(body: { 'microservice': 'mockmicroservice', 'oneTimePassword': an_instance_of(String) }).to_return do |request|
        payload = JSON.parse(request.body)
        expect(totp.verify(payload['oneTimePassword'], drift_behind: 15)).not_to be_nil
        { body: "myservicetoken" }
      end
      stub_request(:post, "http://idam.mock.com/loginUser").with(body: { 'username': 'm@m.com', password: 'p' }).to_return(body: mock_positive_response)
      stub_request(:get, "http://idam.mock.com/details").with(headers: { 'Accept' => 'application/json', 'Authorization' => 'myusertoken' }).to_return(status: 200, body: user_details.to_json)

      # Act
      client.login(username: 'm@m.com', password: 'p')
    end
  end
end
