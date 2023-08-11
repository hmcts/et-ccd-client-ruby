require 'spec_helper'
require 'et_ccd_client'
require 'rotp'
RSpec.describe EtCcdClient::TidamClient do
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
      idam_user_token_exchange_url: "http://idam.mock.com/testing-support/lease",
      use_sidam: false,
      verify_ssl: false
    }
  end
  let(:mock_logger) do
    instance_spy('ActiveSupport::Logger').tap do |spy|
      allow(spy).to receive(:tagged) do |_arg1, &block|
        block.call
      end
    end
  end

  describe "#login" do
    it "calls the service auth provider service with a otp" do

      # Arrange - Setup the stubs
      stub_request(:post, "http://auth.mock.com/lease").with(body: { 'microservice': 'mockmicroservice', 'oneTimePassword': an_instance_of(String) }).to_return do
        { body: "myservicetoken" }
      end
      stub_request(:post, "http://idam.mock.com/testing-support/lease").with(body: { 'id': 22, role: 'rolestuff' }).to_return(body: "myusertoken")

      # Act
      client.login(user_id: 22, role: 'rolestuff')

      # Assert - Make sure the tokens are available to others
      expect(client).to have_attributes service_token: 'myservicetoken', user_token: 'myusertoken'
    end

    it "has a valid otp" do

      # Arrange - Setup the stubs
      totp = ROTP::TOTP.new(test_secret)
      stub_request(:post, "http://auth.mock.com/lease").with(body: { 'microservice': 'mockmicroservice', 'oneTimePassword': an_instance_of(String) }).to_return do |request|
        payload = JSON.parse(request.body)
        expect(totp.verify(payload['oneTimePassword'], drift_behind: 15)).not_to be_nil
        { body: "myservicetoken" }
      end
      stub_request(:post, "http://idam.mock.com/testing-support/lease").with(body: { 'id': 22, role: 'rolestuff' }).to_return(body: "myusertoken")

      # Act
      client.login(user_id: 22, role: 'rolestuff')
    end

  end

end
