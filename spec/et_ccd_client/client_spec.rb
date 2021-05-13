require 'spec_helper'
require 'et_ccd_client'
require 'rack'


RSpec.describe EtCcdClient::Client do
  subject(:client) { described_class.new(idam_client: mock_idam_client, config: mock_config) }

  let(:mock_idam_client) { instance_spy(EtCcdClient::IdamClient, service_token: 'mockservicetoken', user_token: 'mockusertoken', user_details: { 'id' => 'mockuserid', 'roles' => ['mockrole1', 'mockrole2'] }, login: nil) }
  let(:mock_config) { instance_double(EtCcdClient::Config, mock_config_values) }
  let(:mock_config_values) do
    {
      auth_base_url: 'http://auth.mock.com',
      idam_base_url: 'http://idam.mock.com',
      data_store_base_url: 'http://data.mock.com',
      ecm_base_url: 'http://ecm.mock.com',
      start_multiple_url: 'http://ecm.mock.com/generateCaseRefNumbers',
      document_store_base_url: 'http://documents.mock.com',
      document_store_url_rewrite: false,
      jurisdiction_id: 'mockjid',
      microservice: 'mockmicroservice',
      microservice_secret: 'nottellingyouitsasecret',
      logger: mock_logger,
      user_id: 51,
      initiate_claim_event_id: 'mockinitiateevent',
      initiate_bulk_event_id: 'mockinitiatebulkevent',
      initiate_case_url: 'http://data.mock.com/caseworkers/{uid}/jurisdictions/{jid}/case-types/{ctid}/event-triggers/{etid}/token',
      create_case_url: 'http://data.mock.com/caseworkers/{uid}/jurisdictions/{jid}/case-types/{ctid}/cases',
      upload_file_url: 'http://documents.mock.com/documents',
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

    context 'when using tidam' do
      let(:mock_config_values) do
        {
          auth_base_url: 'http://auth.mock.com',
          idam_base_url: 'http://idam.mock.com',
          data_store_base_url: 'http://data.mock.com',
          jurisdiction_id: 'mockjid',
          microservice: 'mockmicroservice',
          microservice_secret: 'nottellingyouitsasecret',
          logger: mock_logger,
          user_id: 51,
          initiate_claim_event_id: 'mockinitiateevent',
          initiate_case_url: 'http://data.mock.com/caseworkers/{uid}/jurisdictions/{jid}/case-types/{ctid}/event-triggers/{etid}/token',
          create_case_url: 'http://data.mock.com/caseworkers/{uid}/jurisdictions/{jid}/case-types/{ctid}/cases',
          use_sidam: false,
          verify_ssl: false
        }
      end
      let(:mock_idam_client) { instance_spy(EtCcdClient::TidamClient, service_token: 'mockservicetoken', login: nil) }

      it "delegates to the idam client with default values" do
        # Act - Call with no arguments
        client.login

        # Assert - Ensure it calls login in idam client with no arguments
        expect(mock_idam_client).to have_received(:login).with(no_args)
      end

      it "delegates to the idam client with specified user_id" do
        # Act - Call with user_id
        client.login(user_id: 19)

        # Assert - Ensure it calls login in idam client with no arguments
        expect(mock_idam_client).to have_received(:login).with(user_id: 19)
      end

      it "delegates to the idam client with specified role" do
        # Act - Call with user_id
        client.login(role: 'testrole')

        # Assert - Ensure it calls login in idam client with no arguments
        expect(mock_idam_client).to have_received(:login).with(role: 'testrole')
      end

    end

  end

  describe "#caseworker_start_case_creation" do
    it "performs the correct http request" do
      # Arrange - stub the url
      stub = stub_request(:get, "http://data.mock.com/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/event-triggers/mockinitiateevent/token").
             to_return(body: '{}', headers: default_response_headers, status: 200)

      # Act - Call the method
      client.caseworker_start_case_creation(case_type_id: 'mycasetypeid')

      # Assert
      expect(stub).to have_been_requested
    end

    it "returns the correct hash from the json" do
      # Arrange - stub the url
      stub_request(:get, "http://data.mock.com/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/event-triggers/mockinitiateevent/token").
        to_return(body: '{"test":"value"}', headers: default_response_headers, status: 200)

      # Act - Call the method
      result = client.caseworker_start_case_creation(case_type_id: 'mycasetypeid')

      # Assert
      expect(result).to eq("test" => "value")
    end

    it_behaves_like 'common GET logging examples', log_subject: 'Start case creation' do
      let(:url) { "http://data.mock.com/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/event-triggers/mockinitiateevent/token" }
      let(:action) { -> { client.caseworker_start_case_creation(case_type_id: 'mycasetypeid') } }
    end

    it_behaves_like "common GET exception handling examples" do
      let(:url) { "http://data.mock.com/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/event-triggers/mockinitiateevent/token" }
      let(:action) { -> { client.caseworker_start_case_creation(case_type_id: 'mycasetypeid') } }
    end

    it_behaves_like "common GET auto login examples" do
      let(:url) { "http://data.mock.com/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/event-triggers/mockinitiateevent/token" }
      let(:action) { -> { client.caseworker_start_case_creation(case_type_id: 'mycasetypeid') } }
    end
  end
  describe "#caseworker_start_bulk_creation" do
    it "performs the correct http request" do
      # Arrange - stub the url
      stub = stub_request(:get, "http://data.mock.com/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/event-triggers/mockinitiatebulkevent/token").
             to_return(body: '{}', headers: default_response_headers, status: 200)

      # Act - Call the method
      client.caseworker_start_bulk_creation(case_type_id: 'mycasetypeid')

      # Assert
      expect(stub).to have_been_requested
    end

    it "returns the correct hash from the json" do
      # Arrange - stub the url
      stub_request(:get, "http://data.mock.com/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/event-triggers/mockinitiatebulkevent/token").
        to_return(body: '{"test":"value"}', headers: default_response_headers, status: 200)

      # Act - Call the method
      result = client.caseworker_start_bulk_creation(case_type_id: 'mycasetypeid')

      # Assert
      expect(result).to eq("test" => "value")
    end

    it_behaves_like 'common GET logging examples', log_subject: 'Start bulk creation' do
      let(:url) { "http://data.mock.com/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/event-triggers/mockinitiatebulkevent/token" }
      let(:action) { -> { client.caseworker_start_bulk_creation(case_type_id: 'mycasetypeid') } }
    end

    it_behaves_like "common GET exception handling examples" do
      let(:url) { "http://data.mock.com/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/event-triggers/mockinitiatebulkevent/token" }
      let(:action) { -> { client.caseworker_start_bulk_creation(case_type_id: 'mycasetypeid') } }
    end

    it_behaves_like "common GET auto login examples" do
      let(:url) { "http://data.mock.com/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/event-triggers/mockinitiatebulkevent/token" }
      let(:action) { -> { client.caseworker_start_bulk_creation(case_type_id: 'mycasetypeid') } }
    end

  end

  describe "#caseworker_case_create" do
    it "performs the correct http request" do
      # Arrange - stub the url
      stub = stub_request(:post, "http://data.mock.com/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases").
             with(headers: { "Content-Type": "application/x-www-form-urlencoded" }).
             to_return(body: '{}', headers: default_response_headers, status: 200)

      # Act - Call the method
      client.caseworker_case_create({}, case_type_id: 'mycasetypeid')

      # Assert
      expect(stub).to have_been_requested
    end

    it "returns the correct json" do
      # Arrange - stub the url
      stub_request(:post, "http://data.mock.com/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases").
        to_return(body: '{"test":"value"}', headers: default_response_headers, status: 200)

      # Act - Call the method
      result = client.caseworker_case_create({}, case_type_id: 'mycasetypeid')

      # Assert
      expect(result).to eql("test" => "value")
    end

    it_behaves_like 'common POST logging examples', log_subject: 'Case worker create case' do
      let(:url) { "http://data.mock.com/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases" }
      let(:action) { -> (data = {}) { client.caseworker_case_create(data, case_type_id: 'mycasetypeid') } }
    end

    it_behaves_like "common POST exception handling examples" do
      let(:url) { "http://data.mock.com/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases" }
      let(:action) { -> (data = {}) { client.caseworker_case_create(data, case_type_id: 'mycasetypeid') } }
    end

    it_behaves_like "common POST auto login examples" do
      let(:url) { "http://data.mock.com/caseworkers/mockuserid/jurisdictions/mockjid/case-types/mycasetypeid/cases" }
      let(:action) { -> (data = {}) { client.caseworker_case_create(data, case_type_id: 'mycasetypeid') } }
    end
  end

  describe '#start_multiple' do
    let(:response_data) do
      {
        'caseRefNumberCount' => 100,
        'startCaseRefNumber' => '2100001/2019',
        'multipleRefNumber' => '2111111/2019'
      }
    end
    let(:expected_body) do
      {
        'case_details' => a_hash_including(
          'case_data' => a_hash_including(
            'caseRefNumberCount' => '100'
          ),
          'case_type_id' => 'mycasetypeid'
        )
      }
    end
    it "performs the correct http request" do
      # Arrange - stub the url
      stub = stub_request(:post, mock_config_values[:start_multiple_url]).
        with(headers: { "Content-Type": "application/json" }, body: hash_including(expected_body)).
        to_return(body: response_data.to_json, headers: default_response_headers, status: 200)

      # Act - Call the method
      client.start_multiple(case_type_id: 'mycasetypeid', quantity: 100)

      # Assert
      expect(stub).to have_been_requested
    end

    it "returns the correct json" do
      # Arrange - stub the url
      stub_request(:post, mock_config_values[:start_multiple_url]).
        with(headers: { "Content-Type": "application/json" }).
        to_return(body: response_data.to_json, headers: default_response_headers, status: 200)

      # Act - Call the method
      result = client.start_multiple(case_type_id: 'mycasetypeid', quantity: 100)

      # Assert
      expect(result).to eql response_data
    end

    it_behaves_like "common POST auto login examples" do
      let(:url) { mock_config_values[:start_multiple_url] }
      let(:action) { -> (data = {}) { client.start_multiple(case_type_id: 'mycasetypeid', quantity: 100) } }
    end

  end
  describe "#caseworker_search_by_reference" do

  end

  describe "#caseworker_search_latest_by_reference" do

  end

  describe "#caseworker_cases_pagination_metadata" do

  end

  describe '#caseworker_case' do

  end

  describe "#upload_file_from_filename" do
    def parse_multipart(request)
      Rack::Multipart::Parser.parse StringIO.new(request.body), request.headers['Content-Length'].to_i, request.headers['Content-Type'], Rack::Multipart::Parser::TEMPFILE_FACTORY, Rack::Multipart::Parser::BUFSIZE, Rack::Utils.default_query_parser
    end

    let(:example_response) do
      example_response = {
        "_embedded" => {
          "documents" => [
            {
              "_links" => {
                "self" => {
                  "href" => "http://localhost:4506/1234-5678-1234-5678"
                },
                "binary" => {
                  "href" => "http://localhost:4506/1234-5678-1234-5678/binary"
                },
                "thumbnail" => {
                  "href" => "http://localhost:4506/1234-5678-1234-5678/thumbnail"
                }
              },
              "_embedded" => {
                "allDocumentVersions" => {
                  "_embedded" => {
                    "documentVersions" => [
                      {
                        "_links" => {
                          "document" => {
                            "href" => "http://localhost:4506/1234-5678-1234-5678"
                          },
                          "self" => {
                            "href" => "http://localhost:4506/1234-5678-1234-5678/versions/ac711770-6681-4fd8-b662-f7f54ea7a27d"
                          },
                          "binary" => {
                            "href" => "http://localhost:4506/1234-5678-1234-5678/versions/ac711770-6681-4fd8-b662-f7f54ea7a27d/binary"
                          },
                          "thumbnail" => {
                            "href" => "http://localhost:4506/1234-5678-1234-5678/versions/ac711770-6681-4fd8-b662-f7f54ea7a27d/thumbnail"
                          },
                          "migrate" => {
                            "href" => "http://localhost:4506/1234-5678-1234-5678/versions/ac711770-6681-4fd8-b662-f7f54ea7a27d/migrate"
                          }
                        }
                      }
                    ]
                  }
                }
              }
            }
          ]
        }
      }
    end

    it "performs the correct http request" do
      # Arrange - stub the url
      stub = stub_request(:post, "http://documents.mock.com/documents").
        with(headers: { 'Serviceauthorization'=>'Bearer mockservicetoken', 'Authorization' => 'Bearer mockusertoken', 'Content-Type' => /\Amultipart\/form-data/}).
        to_return(body: '{}', headers: default_response_headers, status: 200)

      # Act - Call the method
      client.upload_file_from_filename(File.absolute_path('../fixtures/et1.pdf', __dir__), content_type: 'application/pdf')

      # Assert
      expect(stub).to have_been_requested
    end

    it "has the correct params in the multipart body" do
      # Arrange - stub the url
      last_request = nil
      stub_request(:post, "http://documents.mock.com/documents").
        with(headers: { 'Serviceauthorization'=>'Bearer mockservicetoken', 'Authorization' => 'Bearer mockusertoken', 'Content-Type' => /\Amultipart\/form-data/}) {|request| last_request = request}.
        to_return(body: '{}', headers: default_response_headers, status: 200)

      # Act - Call the method
      client.upload_file_from_filename(File.absolute_path('../fixtures/et1.pdf', __dir__), content_type: 'application/pdf')

      # Assert
      expect(parse_multipart(last_request).params).to include('files' => a_hash_including(filename: 'et1.pdf', name: "files", type: "application/pdf", tempfile: instance_of(Tempfile)), 'classification' => 'PUBLIC')
    end

    it "has the correct file in the multipart body" do
      # Arrange - stub the url
      last_request = nil
      stub_request(:post, "http://documents.mock.com/documents").
        with(headers: { 'Serviceauthorization'=>'Bearer mockservicetoken', 'Authorization' => 'Bearer mockusertoken', 'Content-Type' => /\Amultipart\/form-data/}) {|request| last_request = request}.
        to_return(body: '{}', headers: default_response_headers, status: 200)

      # Act - Call the method
      input_file = File.absolute_path('../fixtures/et1.pdf', __dir__)
      client.upload_file_from_filename(input_file, content_type: 'application/pdf')

      # Assert
      file = parse_multipart(last_request).params.dig('files', :tempfile)
      expect(file.size).to eql File.size(input_file)
    end

    it "returns the correct hash from the json without any urls modified" do
      # Arrange - stub the url
      stub_request(:post, "http://documents.mock.com/documents").
        with(headers: { 'Serviceauthorization'=>'Bearer mockservicetoken', 'Authorization' => 'Bearer mockusertoken', 'Content-Type' => /\Amultipart\/form-data/}).
        to_return(body: JSON.generate(example_response), headers: default_response_headers, status: 200)

      # Act - Call the method
      result = client.upload_file_from_filename(File.absolute_path('../fixtures/et1.pdf', __dir__), content_type: 'application/pdf')

      # Assert
      expect(result).to eql(example_response)
    end

    it "returns the correct hash from the json with the first set of urls re written when configured to do so" do

      # Arrange - change the config and stub the url
      mock_config_values['document_store_url_rewrite'] = 'localhost:4506:dm-store:8080'.split(':')
      stub_request(:post, "http://documents.mock.com/documents").
        with(headers: { 'Serviceauthorization'=>'Bearer mockservicetoken', 'Authorization' => 'Bearer mockusertoken', 'Content-Type' => /\Amultipart\/form-data/}).
        to_return(body: JSON.generate(example_response), headers: default_response_headers, status: 200)

      # Act - Call the method
      result = client.upload_file_from_filename(File.absolute_path('../fixtures/et1.pdf', __dir__), content_type: 'application/pdf')

      # Assert
      json_paths = ['self', 'binary', 'thumbnail']
      aggregate_failures "Validating all hrefs" do
        json_paths.each do |json_path|
          full_path = "_links.#{json_path}.href"
          expect(result.dig('_embedded', 'documents').first.dig(*full_path.split('.'))).to start_with('http://dm-store:8080')
        end
      end
    end

    it "returns the correct hash from the json with the second set of urls re written when configured to do so" do

      # Arrange - change the config and stub the url
      mock_config_values['document_store_url_rewrite'] = 'localhost:4506:dm-store:8080'.split(':')
      stub_request(:post, "http://documents.mock.com/documents").
        with(headers: { 'Serviceauthorization'=>'Bearer mockservicetoken', 'Authorization' => 'Bearer mockusertoken', 'Content-Type' => /\Amultipart\/form-data/}).
        to_return(body: JSON.generate(example_response), headers: default_response_headers, status: 200)

      # Act - Call the method
      result = client.upload_file_from_filename(File.absolute_path('../fixtures/et1.pdf', __dir__), content_type: 'application/pdf')

      # Assert
      json_paths = ['document', 'self', 'binary', 'thumbnail', 'migrate']
      aggregate_failures "Validating all hrefs" do
        json_paths.each do |json_path|
          full_path = "_links.#{json_path}.href"
          expect(result.dig('_embedded', 'documents').first.dig('_embedded', 'allDocumentVersions', '_embedded', 'documentVersions').first.dig(*full_path.split('.'))).to start_with('http://dm-store:8080')
        end
      end
    end


    it "uses a tagged logger" do
      # Arrange - stub the url
      stub_request(:post, "http://documents.mock.com/documents").
        to_return(body: '{"test":"value"}', headers: default_response_headers, status: 200)

      # Act - Call the method
      client.upload_file_from_filename(File.absolute_path('../fixtures/et1.pdf', __dir__), content_type: 'application/pdf')

      # Assert
      expect(mock_logger).to have_received(:tagged)
    end

    it "logs the request" do
      # Arrange - stub the url
      stub_request(:post, "http://documents.mock.com/documents").
        to_return(body: '{"test":"value"}', headers: default_response_headers, status: 200)

      # Act - Call the method
      filename = File.absolute_path('../fixtures/et1.pdf', __dir__)
      client.upload_file_from_filename(filename, content_type: 'application/pdf')

      # Assert
      expect(mock_logger).to have_received(:debug).with("ET > Upload file from filename (http://documents.mock.com/documents)")
    end

    it "logs the response" do
      # Arrange - stub the url
      resp_body = '{"test":"value"}'
      stub_request(:post, "http://documents.mock.com/documents").
        to_return(body: resp_body, headers: default_response_headers, status: 200)

      # Act - Call the method
      client.upload_file_from_filename(File.absolute_path('../fixtures/et1.pdf', __dir__), content_type: 'application/pdf')

      # Assert
      expect(mock_logger).to have_received(:debug).with("ET < Upload file from filename - #{resp_body}")
    end

    it "logs the response under error conditions" do
      # Arrange - stub the url
      resp_body = '{"message": "Not found"}'
      stub_request(:post, "http://documents.mock.com/documents").
        to_return(body: resp_body, headers: default_response_headers, status: 404)

      # Act - Call the method
      action = -> { client.upload_file_from_filename(File.absolute_path('../fixtures/et1.pdf', __dir__), content_type: 'application/pdf') }

      # Assert
      aggregate_failures "Both exception should be raised and log should be recorded" do
        expect(action).to raise_exception(EtCcdClient::Exceptions::Base)
        expect(mock_logger).to have_received(:debug).with("ET < Upload file from filename (ERROR) - #{resp_body}")
      end
    end

    it "raises an error with the url present if the server responds with an error" do
      # Arrange - stub the url
      resp_body = '{"message": "Not found"}'
      stub_request(:post, "http://documents.mock.com/documents").
        to_return(body: resp_body, headers: default_response_headers, status: 404)

      # Act - Call the method
      action = -> { client.upload_file_from_filename(File.absolute_path('../fixtures/et1.pdf', __dir__), content_type: 'application/pdf') }

      # Assert
      expect(action).to raise_exception(EtCcdClient::Exceptions::Base, "404 Not Found - Not found ('http://documents.mock.com/documents')")
    end

    it_behaves_like "common POST auto login examples" do
      let(:url) { "http://documents.mock.com/documents" }
      let(:action) { -> { client.upload_file_from_filename(File.absolute_path('../fixtures/et1.pdf', __dir__), content_type: 'application/pdf') } }
    end



  end

  describe "#upload_file_from_url" do
    let(:example_response) do
      example_response = {
        "_embedded" => {
          "documents" => [
            {
              "_links" => {
                "self" => {
                  "href" => "http://localhost:4506/1234-5678-1234-5678"
                },
                "binary" => {
                  "href" => "http://localhost:4506/1234-5678-1234-5678/binary"
                },
                "thumbnail" => {
                  "href" => "http://localhost:4506/1234-5678-1234-5678/thumbnail"
                }
              },
              "_embedded" => {
                "allDocumentVersions" => {
                  "_embedded" => {
                    "documentVersions" => [
                      {
                        "_links" => {
                          "document" => {
                            "href" => "http://localhost:4506/1234-5678-1234-5678"
                          },
                          "self" => {
                            "href" => "http://localhost:4506/1234-5678-1234-5678/versions/ac711770-6681-4fd8-b662-f7f54ea7a27d"
                          },
                          "binary" => {
                            "href" => "http://localhost:4506/1234-5678-1234-5678/versions/ac711770-6681-4fd8-b662-f7f54ea7a27d/binary"
                          },
                          "thumbnail" => {
                            "href" => "http://localhost:4506/1234-5678-1234-5678/versions/ac711770-6681-4fd8-b662-f7f54ea7a27d/thumbnail"
                          },
                          "migrate" => {
                            "href" => "http://localhost:4506/1234-5678-1234-5678/versions/ac711770-6681-4fd8-b662-f7f54ea7a27d/migrate"
                          }
                        }
                      }
                    ]
                  }
                }
              }
            }
          ]
        }
      }
    end

    def parse_multipart(request)
      Rack::Multipart::Parser.parse StringIO.new(request.body), request.headers['Content-Length'].to_i, request.headers['Content-Type'], Rack::Multipart::Parser::TEMPFILE_FACTORY, Rack::Multipart::Parser::BUFSIZE, Rack::Utils.default_query_parser
    end

    before do
      stub_request(:get, "http://external.server/et1.pdf").
        to_return(status: 200, body: File.new(File.absolute_path('../fixtures/et1.pdf', __dir__)), headers: {'Content-Type' => 'application/pdf'})
    end

    it "performs the correct http request" do
      # Arrange - stub the url
      stub = stub_request(:post, "http://documents.mock.com/documents").
        with(headers: { 'Serviceauthorization'=>'Bearer mockservicetoken', 'Authorization' => 'Bearer mockusertoken', 'Content-Type' => /\Amultipart\/form-data/}).
        to_return(body: '{}', headers: default_response_headers, status: 200)

      # Act - Call the method
      client.upload_file_from_url('http://external.server/et1.pdf', content_type: 'application/pdf')

      # Assert
      expect(stub).to have_been_requested
    end

    it "has the correct params in the multipart body" do
      # Arrange - stub the url
      last_request = nil
      stub_request(:post, "http://documents.mock.com/documents").
        with(headers: { 'Serviceauthorization'=>'Bearer mockservicetoken', 'Authorization' => 'Bearer mockusertoken', 'Content-Type' => /\Amultipart\/form-data/}) {|request| last_request = request}.
        to_return(body: '{}', headers: default_response_headers, status: 200)

      # Act - Call the method
      client.upload_file_from_url('http://external.server/et1.pdf', content_type: 'application/pdf')

      # Assert
      expect(parse_multipart(last_request).params).to include('files' => a_hash_including(filename: 'et1.pdf', name: "files", type: "application/pdf", tempfile: instance_of(Tempfile)), 'classification' => 'PUBLIC')
    end

    it "has the correct file in the multipart body" do
      # Arrange - stub the url
      last_request = nil
      stub_request(:post, "http://documents.mock.com/documents").
        with(headers: { 'Serviceauthorization'=>'Bearer mockservicetoken', 'Authorization' => 'Bearer mockusertoken', 'Content-Type' => /\Amultipart\/form-data/}) {|request| last_request = request}.
        to_return(body: '{}', headers: default_response_headers, status: 200)

      # Act - Call the method
      input_file = File.absolute_path('../fixtures/et1.pdf', __dir__)
      client.upload_file_from_url('http://external.server/et1.pdf', content_type: 'application/pdf')

      # Assert
      file = parse_multipart(last_request).params.dig('files', :tempfile)
      expect(file.size).to eql File.size(input_file)
    end

    it "returns the correct hash from the json without any urls modified" do
      # Arrange - stub the url
      stub_request(:post, "http://documents.mock.com/documents").
        with(headers: { 'Serviceauthorization'=>'Bearer mockservicetoken', 'Authorization' => 'Bearer mockusertoken', 'Content-Type' => /\Amultipart\/form-data/}).
        to_return(body: JSON.generate(example_response), headers: default_response_headers, status: 200)

      # Act - Call the method
      result = client.upload_file_from_url('http://external.server/et1.pdf', content_type: 'application/pdf')

      # Assert
      expect(result).to eql(example_response)
    end

    it "returns the correct hash from the json with the first set of urls re written when configured to do so" do

      # Arrange - change the config and stub the url
      mock_config_values['document_store_url_rewrite'] = 'localhost:4506:dm-store:8080'.split(':')
      stub_request(:post, "http://documents.mock.com/documents").
        with(headers: { 'Serviceauthorization'=>'Bearer mockservicetoken', 'Authorization' => 'Bearer mockusertoken', 'Content-Type' => /\Amultipart\/form-data/}).
        to_return(body: JSON.generate(example_response), headers: default_response_headers, status: 200)

      # Act - Call the method
      result = client.upload_file_from_url('http://external.server/et1.pdf', content_type: 'application/pdf')

      # Assert
      json_paths = ['self', 'binary', 'thumbnail']
      aggregate_failures "Validating all hrefs" do
        json_paths.each do |json_path|
          full_path = "_links.#{json_path}.href"
          expect(result.dig('_embedded', 'documents').first.dig(*full_path.split('.'))).to start_with('http://dm-store:8080')
        end
      end
    end

    it "returns the correct hash from the json with the second set of urls re written when configured to do so" do

      # Arrange - change the config and stub the url
      mock_config_values['document_store_url_rewrite'] = 'localhost:4506:dm-store:8080'.split(':')
      stub_request(:post, "http://documents.mock.com/documents").
        with(headers: { 'Serviceauthorization'=>'Bearer mockservicetoken', 'Authorization' => 'Bearer mockusertoken', 'Content-Type' => /\Amultipart\/form-data/}).
        to_return(body: JSON.generate(example_response), headers: default_response_headers, status: 200)

      # Act - Call the method
      result = client.upload_file_from_url('http://external.server/et1.pdf', content_type: 'application/pdf')

      # Assert
      json_paths = ['document', 'self', 'binary', 'thumbnail', 'migrate']
      aggregate_failures "Validating all hrefs" do
        json_paths.each do |json_path|
          full_path = "_links.#{json_path}.href"
          expect(result.dig('_embedded', 'documents').first.dig('_embedded', 'allDocumentVersions', '_embedded', 'documentVersions').first.dig(*full_path.split('.'))).to start_with('http://dm-store:8080')
        end
      end
    end

    it "uses a tagged logger" do
      # Arrange - stub the url
      stub_request(:post, "http://documents.mock.com/documents").
        to_return(body: '{"test":"value"}', headers: default_response_headers, status: 200)

      # Act - Call the method
      client.upload_file_from_url('http://external.server/et1.pdf', content_type: 'application/pdf')

      # Assert
      expect(mock_logger).to have_received(:tagged).at_least(:once)
    end

    it "logs the request" do
      # Arrange - stub the url
      stub_request(:post, "http://documents.mock.com/documents").
        to_return(body: '{"test":"value"}', headers: default_response_headers, status: 200)

      # Act - Call the method
      input_url = 'http://external.server/et1.pdf'
      client.upload_file_from_url(input_url, content_type: 'application/pdf')

      # Assert
      expect(mock_logger).to have_received(:debug).with("ET > Upload file from url (http://documents.mock.com/documents)")
    end

    it "logs the response" do
      # Arrange - stub the url
      resp_body = '{"test":"value"}'
      stub_request(:post, "http://documents.mock.com/documents").
        to_return(body: resp_body, headers: default_response_headers, status: 200)

      # Act - Call the method
      client.upload_file_from_url('http://external.server/et1.pdf', content_type: 'application/pdf')

      # Assert
      expect(mock_logger).to have_received(:debug).with("ET < Upload file from url - #{resp_body}")
    end

    it "logs the response under error conditions" do
      # Arrange - stub the url
      resp_body = '{"message": "Not found"}'
      stub_request(:post, "http://documents.mock.com/documents").
        to_return(body: resp_body, headers: default_response_headers, status: 404)

      # Act - Call the method
      action = -> { client.upload_file_from_url('http://external.server/et1.pdf', content_type: 'application/pdf') }

      # Assert
      aggregate_failures "Both exception should be raised and log should be recorded" do
        expect(action).to raise_exception(EtCcdClient::Exceptions::Base)
        expect(mock_logger).to have_received(:debug).with("ET < Upload file from url (ERROR) - #{resp_body}")
      end
    end

    it "raises an error with the url present if the server responds with an error" do
      # Arrange - stub the url
      resp_body = '{"message": "Not found"}'
      stub_request(:post, "http://documents.mock.com/documents").
        to_return(body: resp_body, headers: default_response_headers, status: 404)

      # Act - Call the method
      action = -> { client.upload_file_from_url('http://external.server/et1.pdf', content_type: 'application/pdf') }

      # Assert
      expect(action).to raise_exception(EtCcdClient::Exceptions::Base, "404 Not Found - Not found ('http://documents.mock.com/documents')")
    end


  end

  describe ".use" do
    before do
      stub_request(:post, "http://localhost:4502/lease").to_return(body: 'servicetoken', status: 200)
      stub_request(:post, "http://localhost:4501/loginUser").to_return(body: '{"access_token":"usertoken"}', status: 200)
      stub_request(:get, "http://localhost:4501/details").to_return(body: '{"id":"userid","roles":["role1","role2"]}', status: 200)
    end
    it 'fetches a connection from the pool' do
      # Act
      described_class.use do |client|
        # Assert
        expect(client).to be_an_instance_of(described_class)
      end
    end

    it 'ensures it is logged in ready for use' do
      # Setup - call use
      stub_request(:get, "http://localhost:4452/caseworkers/userid/jurisdictions/EMPLOYMENT/case-types/anything/event-triggers/initiateCase/token").
        with(
          headers: {
            'Authorization'=>'Bearer usertoken',
            'Serviceauthorization'=>'Bearer servicetoken',
            'User-Id'=>'userid',
            'User-Roles'=>'role1,role2'
          }).
        to_return(status: 200, body: "{}", headers: {})

      described_class.use do |client|
        # Act - Try and use an endpoint
        client.caseworker_start_case_creation(case_type_id: 'anything')


      end
    end

    it 'checks out from the pool' do
      # Arrange
      was_available = described_class.connection_pool.available
      # Act
      described_class.use do |_client|
        # Assert
        expect(described_class.connection_pool.available).to eql(was_available - 1)
      end
    end

    it 'checks back into the pool' do
      # Arrange
      was_available = described_class.connection_pool.available

      # Act
      described_class.use { |_client| }

      # Assert
      expect(described_class.connection_pool.available).to eql(was_available)
    end

    it 'checks 2 clients out from the same pool if 2 threads are used' do
      # Arrange
      was_available = described_class.connection_pool.available

      # Act
      thread1 = Thread.new do
        described_class.use do |client1|
          Thread.stop
        end
      end

      thread2 = Thread.new do
        described_class.use do |client2|
          Thread.stop
        end
      end

      sleep 0.1 until thread1.status == 'sleep' && thread2.status == 'sleep'

      expect(described_class.connection_pool.available).to eql(was_available - 2)
      thread1.run
      thread2.run
      thread1.join
      thread2.join
    end
  end

end
