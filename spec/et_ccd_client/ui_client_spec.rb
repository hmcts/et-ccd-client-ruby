require 'spec_helper'
require 'et_ccd_client'
RSpec.describe EtCcdClient::UiClient do
  subject(:client) { described_class.new(ui_idam_client: mock_idam_client, config: mock_config) }

  let(:mock_idam_client) { instance_spy(EtCcdClient::UiIdamClient, service_token: 'mockservicetoken', user_token: 'mockusertoken', user_details: { 'id' => 'mockuserid', 'roles' => ['mockrole1', 'mockrole2'] }, login: nil) }
  let(:mock_config) { instance_double(EtCcdClient::Config, mock_config_values) }
  let(:mock_config_values) do
    {
      auth_base_url: 'http://auth.mock.com',
      idam_base_url: 'http://idam.mock.com',
      data_store_base_url: 'http://data.mock.com',
      gateway_api_url: 'http://gateway.mock.com',
      document_store_url_rewrite: false,
      jurisdiction_id: 'mockjid',
      microservice: 'mockmicroservice',
      microservice_secret: 'nottellingyouitsasecret',
      logger: mock_logger,
      user_id: 51,
      initiate_claim_event_id: 'mockinitiateevent',
      initiate_case_url: 'http://data.mock.com/caseworkers/{uid}/jurisdictions/{jid}/case-types/{ctid}/event-triggers/{etid}/token',
      create_case_url: 'http://data.mock.com/caseworkers/{uid}/jurisdictions/{jid}/case-types/{ctid}/cases',
      cases_path: '/caseworkers/{uid}/jurisdictions/{jid}/case-types/{ctid}/cases{?query*}',
      use_sidam: true,
      sidam_username: 'm@m.com',
      sidam_password: 'p',
      verify_ssl: false,
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
  let(:default_response_headers) { { 'Content-Type' => 'application/json' } }

  describe "#initialize" do
    it 'has correct default values for injected services' do
      class_double('::EtCcdClient::UiIdamClient', new: mock_idam_client).as_stubbed_const
      allow(::EtCcdClient).to receive(:config).and_return(mock_config)

      described_class.new
      expect(::EtCcdClient).to have_received(:config)
    end
  end

  describe "#login" do
    context 'when using sidam' do
      it "delegates to the idam client with default values" do
        # Act - Call with no arguments
        client.login

        # Assert - Ensure it calls login in idam client with no arguments
        expect(mock_idam_client).to have_received(:login).with(no_args)
      end

      it "delegates to the idam client with specified user_id" do
        # Act - Call with user_id
        client.login(username: 'username')

        # Assert - Ensure it calls login in idam client with no arguments
        expect(mock_idam_client).to have_received(:login).with(username: 'username')
      end

      it "delegates to the idam client with specified role" do
        # Act - Call with user_id
        client.login(password: 'password')

        # Assert - Ensure it calls login in idam client with no arguments
        expect(mock_idam_client).to have_received(:login).with(password: 'password')
      end

    end
  end

  describe "#caseworker_search_by_reference" do
    let(:reference) { "123456789012" }
    let(:response_for_empty_collection) do
      {
        'results' => []
      }
    end
    let(:response_for_one_entry) do
      {
        'results' => [
          { 'anything' => 'goes' }
        ]
      }
    end
    let(:response_for_error) do
      {
        "exception": "uk.gov.hmcts.ccd.endpoint.exceptions.SomeException",
        "timestamp": "2019-06-23T17:13:07.282",
        "status": 500,
        "error": "Internal Server Error",
        "message": "Something went wrong",
        "path": "/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases"
      }
    end

    it "performs the correct http request" do
      # Arrange - stub the url
      stub = stub_request(:get, "http://gateway.mock.com/aggregated/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases").
             with(query: { 'case.feeGroupReference' => reference, page: 1, 'sortDirection' => 'desc' }).
             to_return(body: response_for_empty_collection.to_json, headers: default_response_headers, status: 200)

      # Act - Call the method
      client.caseworker_search_by_reference(reference, case_type_id: 'mycasetypeid')

      # Assert
      expect(stub).to have_been_requested
    end

    it "returns the correct json" do
      # Arrange - stub the url
      stub_request(:get, "http://gateway.mock.com/aggregated/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases").
        with(query: { 'case.feeGroupReference' => reference, page: 1, 'sortDirection' => 'desc' }).
        to_return(body: response_for_one_entry.to_json, headers: default_response_headers, status: 200)

      # Act - Call the method
      result = client.caseworker_search_by_reference(reference, case_type_id: 'mycasetypeid')

      # Assert
      expect(result).to eql(response_for_one_entry['results'])
    end

    it "uses a tagged logger" do
      # Arrange - stub the url
      stub_request(:get, "http://gateway.mock.com/aggregated/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases").
        with(query: { 'case.feeGroupReference' => reference, page: 1, 'sortDirection' => 'desc' }).
        to_return(body: response_for_empty_collection.to_json, headers: default_response_headers, status: 200)

      # Act - Call the method
      client.caseworker_search_by_reference(reference, case_type_id: 'mycasetypeid')

      # Assert
      expect(mock_logger).to have_received(:tagged)
    end

    it "logs the request" do
      # Arrange - stub the url
      url = "http://gateway.mock.com/aggregated/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases"
      stub_request(:get, url).
        with(query: { 'case.feeGroupReference' => reference, page: 1, 'sortDirection' => 'desc' }).
        to_return(body: response_for_empty_collection.to_json, headers: default_response_headers, status: 200)

      # Act - Call the method
      client.caseworker_search_by_reference(reference, case_type_id: 'mycasetypeid')

      # Assert
      expect(mock_logger).to have_received(:debug).with(start_with("ET > Caseworker search by reference (#{url}"))
    end

    it "re raises the response with the response body available under error conditions with detailed message" do
      # Arrange - stub the url
      resp_body = response_for_error.to_json
      stub_request(:get, "http://gateway.mock.com/aggregated/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases").
        with(query: { 'case.feeGroupReference' => reference, page: 1, 'sortDirection' => 'desc' }).
        to_return(body: resp_body, headers: default_response_headers, status: 500)

      # Act - Call the method
      action = -> { client.caseworker_search_by_reference(reference, case_type_id: 'mycasetypeid') }

      # Assert
      aggregate_failures "Both exception should be raised and log should be recorded" do
        expect(action).to raise_error(EtCcdClient::Exceptions::InternalServerError) do |error|
          expect(error.message).to include("Internal Server Error")
        end
      end
    end

    it "re raises the response with the response body available under error conditions with standard message" do
      # Arrange - stub the url
      resp_body = '{"message": "Unauthorized"}'
      stub_request(:get, "http://gateway.mock.com/aggregated/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases").
        with(query: { 'case.feeGroupReference' => reference, page: 1, 'sortDirection' => 'desc' }).
        to_return(body: resp_body, headers: default_response_headers, status: 401)

      # Act - Call the method
      action = -> { client.caseworker_search_by_reference(reference, case_type_id: 'mycasetypeid') }

      # Assert
      aggregate_failures "Both exception should be raised and log should be recorded" do
        expect(action).to raise_error(EtCcdClient::Exceptions::Base) do |error|
          expect(error.message).to include("Unauthorized")
        end
      end
    end
  end

  describe "#caseworker_search_by_ethos_case_reference" do
    let(:reference) { "123456789012" }
    let(:response_for_empty_collection) do
      {
        'results' => []
      }
    end
    let(:response_for_one_entry) do
      {
        'results' => [
          { 'anything' => 'goes' }
        ]
      }
    end
    let(:response_for_error) do
      {
        "exception": "uk.gov.hmcts.ccd.endpoint.exceptions.SomeException",
        "timestamp": "2019-06-23T17:13:07.282",
        "status": 500,
        "error": "Internal Server Error",
        "message": "Something went wrong",
        "path": "/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases"
      }
    end

    it "performs the correct http request" do
      # Arrange - stub the url
      stub = stub_request(:get, "http://gateway.mock.com/aggregated/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases").
             with(query: { 'case.ethosCaseReference' => reference, page: 1, 'sortDirection' => 'desc' }).
             to_return(body: response_for_empty_collection.to_json, headers: default_response_headers, status: 200)

      # Act - Call the method
      client.caseworker_search_by_ethos_case_reference(reference, case_type_id: 'mycasetypeid')

      # Assert
      expect(stub).to have_been_requested
    end

    it "returns the correct json" do
      # Arrange - stub the url
      stub_request(:get, "http://gateway.mock.com/aggregated/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases").
        with(query: { 'case.ethosCaseReference' => reference, page: 1, 'sortDirection' => 'desc' }).
        to_return(body: response_for_one_entry.to_json, headers: default_response_headers, status: 200)

      # Act - Call the method
      result = client.caseworker_search_by_ethos_case_reference(reference, case_type_id: 'mycasetypeid')

      # Assert
      expect(result).to eql(response_for_one_entry['results'])
    end

    it "uses a tagged logger" do
      # Arrange - stub the url
      stub_request(:get, "http://gateway.mock.com/aggregated/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases").
        with(query: { 'case.ethosCaseReference' => reference, page: 1, 'sortDirection' => 'desc' }).
        to_return(body: response_for_empty_collection.to_json, headers: default_response_headers, status: 200)

      # Act - Call the method
      client.caseworker_search_by_ethos_case_reference(reference, case_type_id: 'mycasetypeid')

      # Assert
      expect(mock_logger).to have_received(:tagged)
    end

    it "logs the request" do
      # Arrange - stub the url
      url = "http://gateway.mock.com/aggregated/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases"
      stub_request(:get, url).
        with(query: { 'case.ethosCaseReference' => reference, page: 1, 'sortDirection' => 'desc' }).
        to_return(body: response_for_empty_collection.to_json, headers: default_response_headers, status: 200)

      # Act - Call the method
      client.caseworker_search_by_ethos_case_reference(reference, case_type_id: 'mycasetypeid')

      # Assert
      expect(mock_logger).to have_received(:debug).with(start_with("ET > Caseworker search by ethos case reference (#{url}"))
    end

    it "re raises the response with the response body available under error conditions with detailed message" do
      # Arrange - stub the url
      resp_body = response_for_error.to_json
      stub_request(:get, "http://gateway.mock.com/aggregated/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases").
        with(query: { 'case.ethosCaseReference' => reference, page: 1, 'sortDirection' => 'desc' }).
        to_return(body: resp_body, headers: default_response_headers, status: 500)

      # Act - Call the method
      action = -> { client.caseworker_search_by_ethos_case_reference(reference, case_type_id: 'mycasetypeid') }

      # Assert
      aggregate_failures "Both exception should be raised and log should be recorded" do
        expect(action).to raise_error(EtCcdClient::Exceptions::InternalServerError) do |error|
          expect(error.message).to include("Internal Server Error")
        end
      end
    end

    it "re raises the response with the response body available under error conditions with standard message" do
      # Arrange - stub the url
      resp_body = '{"message": "Unauthorized"}'
      stub_request(:get, "http://gateway.mock.com/aggregated/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases").
        with(query: { 'case.ethosCaseReference' => reference, page: 1, 'sortDirection' => 'desc' }).
        to_return(body: resp_body, headers: default_response_headers, status: 401)

      # Act - Call the method
      action = -> { client.caseworker_search_by_ethos_case_reference(reference, case_type_id: 'mycasetypeid') }

      # Assert
      aggregate_failures "Both exception should be raised and log should be recorded" do
        expect(action).to raise_error(EtCcdClient::Exceptions::Base) do |error|
          expect(error.message).to include("Unauthorized")
        end
      end
    end
  end

  describe "#caseworker_search_by_multiple_reference" do
    let(:reference) { "123456789012" }
    let(:response_for_empty_collection) do
      {
        'results' => []
      }
    end
    let(:response_for_one_entry) do
      {
        'results' => [
          { 'anything' => 'goes' }
        ]
      }
    end
    let(:response_for_error) do
      {
        "exception": "uk.gov.hmcts.ccd.endpoint.exceptions.SomeException",
        "timestamp": "2019-06-23T17:13:07.282",
        "status": 500,
        "error": "Internal Server Error",
        "message": "Something went wrong",
        "path": "/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases"
      }
    end

    it "performs the correct http request" do
      # Arrange - stub the url
      stub = stub_request(:get, "http://gateway.mock.com/aggregated/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases").
             with(query: { 'case.multipleReference' => reference, page: 1, 'sortDirection' => 'desc' }).
             to_return(body: response_for_empty_collection.to_json, headers: default_response_headers, status: 200)

      # Act - Call the method
      client.caseworker_search_by_multiple_reference(reference, case_type_id: 'mycasetypeid')

      # Assert
      expect(stub).to have_been_requested
    end

    it "returns the correct json" do
      # Arrange - stub the url
      stub_request(:get, "http://gateway.mock.com/aggregated/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases").
        with(query: { 'case.multipleReference' => reference, page: 1, 'sortDirection' => 'desc' }).
        to_return(body: response_for_one_entry.to_json, headers: default_response_headers, status: 200)

      # Act - Call the method
      result = client.caseworker_search_by_multiple_reference(reference, case_type_id: 'mycasetypeid')

      # Assert
      expect(result).to eql(response_for_one_entry['results'])
    end

    it "uses a tagged logger" do
      # Arrange - stub the url
      stub_request(:get, "http://gateway.mock.com/aggregated/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases").
        with(query: { 'case.multipleReference' => reference, page: 1, 'sortDirection' => 'desc' }).
        to_return(body: response_for_empty_collection.to_json, headers: default_response_headers, status: 200)

      # Act - Call the method
      client.caseworker_search_by_multiple_reference(reference, case_type_id: 'mycasetypeid')

      # Assert
      expect(mock_logger).to have_received(:tagged)
    end

    it "logs the response" do
      # Arrange - stub the url
      resp_body = response_for_empty_collection.to_json
      stub_request(:get, "http://gateway.mock.com/aggregated/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases").
        with(query: { 'case.multipleReference' => reference, page: 1, 'sortDirection' => 'desc' }).
        to_return(body: resp_body, headers: default_response_headers, status: 200)

      # Act - Call the method
      client.caseworker_search_by_multiple_reference(reference, case_type_id: 'mycasetypeid')

      # Assert
      expect(mock_logger).to have_received(:debug).with("ET < Case worker search by multiple reference - #{resp_body}")
    end

    it "logs the response under error conditions" do
      # Arrange - stub the url
      resp_body = response_for_error.to_json
      stub_request(:get, "http://gateway.mock.com/aggregated/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases").
        with(query: { 'case.multipleReference' => reference, page: 1, 'sortDirection' => 'desc' }).
        to_return(body: resp_body, headers: default_response_headers, status: 500)

      # Act - Call the method
      action = -> { client.caseworker_search_by_multiple_reference(reference, case_type_id: 'mycasetypeid') }

      # Assert
      aggregate_failures "Both exception should be raised and log should be recorded" do
        expect(action).to raise_exception(EtCcdClient::Exceptions::InternalServerError)
        expect(mock_logger).to have_received(:debug).with("ET < Case worker search by multiple reference (ERROR) - #{resp_body}")
      end
    end

    it "re raises the response with the response body available under error conditions with detailed message" do
      # Arrange - stub the url
      resp_body = response_for_error.to_json
      stub_request(:get, "http://gateway.mock.com/aggregated/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases").
        with(query: { 'case.multipleReference' => reference, page: 1, 'sortDirection' => 'desc' }).
        to_return(body: resp_body, headers: default_response_headers, status: 500)

      # Act - Call the method
      action = -> { client.caseworker_search_by_multiple_reference(reference, case_type_id: 'mycasetypeid') }

      # Assert
      aggregate_failures "Both exception should be raised and log should be recorded" do
        expect(action).to raise_error(EtCcdClient::Exceptions::InternalServerError) do |error|
          expect(error.message).to include("Internal Server Error")
        end
        expect(mock_logger).to have_received(:debug).with("ET < Case worker search by multiple reference (ERROR) - #{resp_body}")
      end
    end

    it "re raises the response with the response body available under error conditions with standard message" do
      # Arrange - stub the url
      resp_body = '{"message": "Unauthorized"}'
      stub_request(:get, "http://gateway.mock.com/aggregated/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases").
        with(query: { 'case.multipleReference' => reference, page: 1, 'sortDirection' => 'desc' }).
        to_return(body: resp_body, headers: default_response_headers, status: 401)

      # Act - Call the method
      action = -> { client.caseworker_search_by_multiple_reference(reference, case_type_id: 'mycasetypeid') }

      # Assert
      aggregate_failures "Both exception should be raised and log should be recorded" do
        expect(action).to raise_error(EtCcdClient::Exceptions::Base) do |error|
          expect(error.message).to include("Unauthorized")
        end
        expect(mock_logger).to have_received(:debug).with("ET < Case worker search by multiple reference (ERROR) - #{resp_body}")
      end
    end
  end

end
