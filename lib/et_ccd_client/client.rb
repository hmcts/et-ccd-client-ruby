require "addressable/template"
require 'rest_client'
require 'et_ccd_client/idam_client'
require 'et_ccd_client/config'
require 'et_ccd_client/exceptions'
require 'et_ccd_client/common_rest_client'
require 'et_ccd_client/common_rest_client_with_login'
require 'json'
require 'forwardable'
require 'connection_pool'
module EtCcdClient
  # A client to interact with the CCD API (backend)
  class Client # rubocop:disable Metrics/ClassLength
    extend Forwardable
    include CommonRestClient
    include CommonRestClientWithLogin

    def initialize(idam_client: nil, config: ::EtCcdClient.config)
      self.idam_client = idam_client || (config.use_sidam ? IdamClient.new : TidamClient.new)
      self.config = config
      self.logger = config.logger
    end

    def self.use(&block)
      connection_pool.with(&block)
    end

    def self.connection_pool(config: ::EtCcdClient.config)
      @connection_pool ||= ConnectionPool.new(size: config.pool_size, timeout: config.pool_timeout) do
        new.tap(&:login)
      end
    end

    delegate login: :idam_client

    # Initiate the case ready for creation
    # @param [String] case_type_id
    #
    # @return [Hash] The json response
    def caseworker_start_case_creation(case_type_id:, extra_headers: {})
      logger.tagged('EtCcdClient::Client') do
        url = initiate_case_url(case_type_id, config.initiate_claim_event_id)
        get_request_with_login(url, log_subject: 'Start case creation', extra_headers: extra_headers.merge(headers_from_idam_client))
      end
    end

    # Initiate a bulk action case ready for creation
    # @param [String] case_type_id
    #
    # @return [Hash] The json response
    def caseworker_start_bulk_creation(case_type_id:, extra_headers: {})
      logger.tagged('EtCcdClient::Client') do
        url = initiate_case_url(case_type_id, config.initiate_bulk_event_id)
        get_request_with_login(url, log_subject: 'Start bulk creation', extra_headers: extra_headers.merge(headers_from_idam_client))
      end
    end

    # Initiate a document upload
    # @param [String] ctid
    # @param [String] cid
    #
    # @return [Hash] The json response
    def caseworker_start_upload_document(ctid:, cid:, extra_headers: {})
      url = initiate_document_upload_url(ctid, cid)
      get_request_with_login(url, log_subject: 'Start upload document', extra_headers: extra_headers.merge(headers_from_idam_client))
    end

    # @param [Hash] data
    # @param [String] case_type_id
    #
    # @return [Hash] The json response
    def caseworker_case_create(data, case_type_id:, extra_headers: {})
      logger.tagged('EtCcdClient::Client') do
        tpl = Addressable::Template.new(config.create_case_url)
        url = tpl.expand(uid: idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id).to_s
        post_request_with_login(url, data, log_subject: 'Case worker create case', extra_headers: extra_headers.merge(headers_from_idam_client))
      end
    end

    # Search for cases by reference - useful for testing
    # @param [String] reference The reference number to search for
    # @param [String] case_type_id The case type ID to set the search scope to
    # @param [Integer] page - The page number to fetch
    # @param [String] sort_direction (defaults to 'desc') - Change to 'asc' to do oldest first
    #
    # @return [Array<Hash>] The json response from the server
    def caseworker_search_by_reference(reference, case_type_id:, page: 1, sort_direction: 'desc', extra_headers: {})
      logger.tagged('EtCcdClient::Client') do
        get_request_with_login(cases_url(case_type_id, query: { 'case.feeGroupReference' => reference, page: page, 'sortDirection' => sort_direction }),
                               log_subject: 'Caseworker search by reference', extra_headers: extra_headers.merge(headers_from_idam_client))
      end
    end

    # Find a case by its id
    # @param [String] case_id The id to find
    # @param [String] case_type_id The case type ID to set the search scope to
    #
    # @return [Array<Hash>] The json response from the server
    def caseworker_case(case_id, case_type_id:, extra_headers: {})
      logger.tagged('EtCcdClient::Client') do
        tpl = Addressable::Template.new(config.case_url)
        url = tpl.expand(uid: idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id, case_id: case_id).to_s
        get_request_with_login(url, log_subject: 'Caseworker get by id', extra_headers: extra_headers.merge(headers_from_idam_client))
      end
    end

    # Search for the latest case matching the reference.  Useful for testing
    # @param [String] reference The reference number to search for
    # @param [String] case_type_id The case type ID to set the search scope to
    # @return [Hash] The case object returned from the server
    def caseworker_search_latest_by_reference(reference, case_type_id:, extra_headers: {})
      results = caseworker_search_by_reference(reference, case_type_id: case_type_id, page: 1, sort_direction: 'desc', extra_headers: extra_headers)
      results.first
    end

    # Search for cases by multiple reference - useful for testing
    # @param [String] reference The multiples reference number to search for
    # @param [String] case_type_id The case type ID to set the search scope to
    # @param [Integer] page - The page number to fetch
    # @param [String] sort_direction (defaults to 'desc') - Change to 'asc' to do oldest first
    #
    # @return [Array<Hash>] The json response from the server
    def caseworker_search_by_multiple_reference(reference, case_type_id:, page: 1, sort_direction: 'desc', extra_headers: {})
      logger.tagged('EtCcdClient::Client') do
        tpl = Addressable::Template.new(config.cases_url)
        url = tpl.expand(uid: idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id,
                         query: { 'case.multipleReference' => reference, page: page, 'sortDirection' => sort_direction }).to_s
        get_request_with_login(url, log_subject: 'Caseworker search by multiple reference', extra_headers: extra_headers.merge(headers_from_idam_client))
      end
    end

    # Search for the latest case matching the multiples reference.  Useful for testing
    # @param [String] reference The multiples reference number to search for
    # @param [String] case_type_id The case type ID to set the search scope to
    # @return [Hash] The case object returned from the server
    def caseworker_search_latest_by_multiple_reference(reference, case_type_id:, extra_headers: {})
      results = caseworker_search_by_multiple_reference(reference, case_type_id: case_type_id, page: 1, sort_direction: 'desc', extra_headers: extra_headers)
      results.first
    end

    # @param [String] case_type_id
    # @param [Integer] quantity
    # @return [Hash] The json response from the server
    def start_multiple(case_type_id:, quantity:, extra_headers: {})
      logger.tagged('EtCcdClient::Client') do
        url = config.start_multiple_url
        payload = {
          case_details: {
            case_data: {
              caseRefNumberCount: quantity.to_s
            },
            case_type_id: case_type_id
          }
        }
        post_request_with_login(url, payload.to_json, log_subject: 'Start multiple', extra_headers: extra_headers.merge(headers_from_idam_client))
      end
    end

    # Search for cases by ethos case reference - useful for testing
    # @param [String] reference The ethos case reference number to search for
    # @param [String] case_type_id The case type ID to set the search scope to
    # @param [Integer] page - The page number to fetch
    # @param [String] sort_direction (defaults to 'desc') - Change to 'asc' to do oldest first
    #
    # @return [Array<Hash>] The json response from the server
    def caseworker_search_by_ethos_case_reference(reference, case_type_id:, page: 1, sort_direction: 'desc', extra_headers: {})
      logger.tagged('EtCcdClient::Client') do
        resp = get_request_with_login(cases_url(case_type_id, query: { 'case.ethosCaseReference' => reference, page: page, 'sortDirection' => sort_direction }),
                                      log_subject: 'Caseworker search by ethos case reference', extra_headers: extra_headers.merge(headers_from_idam_client))
        unless config.document_store_url_rewrite == false
          resp = reverse_rewrite_document_store_urls(resp)
        end
        resp
      end
    end

    # Search for the latest case matching the ethos case reference.  Useful for testing
    # @param [String] reference The ethos case reference number to search for
    # @param [String] case_type_id The case type ID to set the search scope to
    # @return [Hash] The case object returned from the server
    def caseworker_search_latest_by_ethos_case_reference(reference, case_type_id:, extra_headers: {})
      results = caseworker_search_by_ethos_case_reference(reference, case_type_id: case_type_id, page: 1, sort_direction: 'desc', extra_headers: extra_headers)
      results.first
    end

    def caseworker_cases_pagination_metadata(case_type_id:, query: {}, extra_headers: {})
      logger.tagged('EtCcdClient::Client') do
        tpl = Addressable::Template.new(config.cases_pagination_metadata_url)
        url = tpl.expand(uid: idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id, query: query).to_s
        get_request_with_login(url, log_subject: 'Caseworker cases pagination metadata', extra_headers: extra_headers.merge(headers_from_idam_client))
      end
    end

    def caseworker_update_case_documents(event_token:, files:, case_id:, case_type_id:, extra_headers: {})
      tpl = Addressable::Template.new(config.case_events_url)
      url = tpl.expand(uid: idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id, cid: case_id).to_s
      logger.tagged('EtCcdClient::Client') do
        payload = {
          data: { documentCollection: files },
          event: { id: 'uploadDocument', summary: '', description: '' },
          event_token: event_token,
          ignore_warning: false
        }.to_json
        post_request_with_login(url, payload, log_subject: 'Caseworker update documents', extra_headers: extra_headers.merge(headers_from_idam_client))
      end
    end

    # @param [String] filename The full path to the file to upload
    # @return [Hash] The object returned by the server
    def upload_file_from_filename(filename, content_type:)
      login_on_denial do
        upload_file_from_source(filename, content_type: content_type, source_name: :filename)
      end
    end

    # @param [String] url The url of the file to upload
    # @return [Hash] The object returned by the server
    def upload_file_from_url(url, content_type:, original_filename: File.basename(url))
      resp = download_from_remote_source(url)
      login_on_denial do
        upload_file_from_source(resp.file.path, content_type: content_type, source_name: :url, original_filename: original_filename)
      end
    end

    private

    def download_from_remote_source(url)
      logger.tagged('EtCcdClient::Client') do
        logger.debug("ET > Download from remote source (#{url})")
        request = RestClient::Request.new(method: :get, url: url, raw_response: true, verify_ssl: config.verify_ssl)
        resp = request.execute
        logger.debug("ET < Download from remote source (#{url}) complete.  Data not shown as very likely to be binary")
        resp
      rescue RestClient::Exception => e
        logger.debug "ET < Download from remote source (ERROR) - #{e.response}"
        Exceptions::Base.raise_exception(e, url: url, request: request)
      end
    end

    def upload_file_from_source(filename, content_type:, source_name:, original_filename: filename)
      logger.tagged('EtCcdClient::Client') do
        url = config.upload_file_url
        logger.debug("ET > Upload file from #{source_name} (#{url})")
        request = upload_file_request(filename, content_type, original_filename, url)
        execute_with_document_rewrite(request, source_name: source_name)
      rescue RestClient::Exception => e
        logger.debug "ET < Upload file from #{source_name} (ERROR) - #{e.response.body}"
        Exceptions::Base.raise_exception(e, url: url, request: request)
      end
    end

    def initiate_case_url(case_type_id, event_id)
      tpl = Addressable::Template.new(config.initiate_case_url)
      tpl.expand(uid: idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id, etid: event_id).to_s
    end

    def initiate_document_upload_url(case_type_id, cid)
      tpl = Addressable::Template.new(config.initiate_document_upload_url)
      tpl.expand(uid: idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id, cid: cid).to_s
    end

    def rewrite_document_store_urls(body)
      source_host, source_port, dest_host, dest_port = config.document_store_url_rewrite
      body.gsub(%r{(https?)://#{Regexp.quote source_host}:#{Regexp.quote source_port}}, "\\1://#{dest_host}:#{dest_port}")
    end

    def cases_url(case_type_id, query:)
      tpl = Addressable::Template.new(config.cases_url)
      tpl.expand(uid: idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id,
                 query: query).to_s
    end

    def headers_from_idam_client
      { 'ServiceAuthorization' => "Bearer #{idam_client.service_token}", :authorization => "Bearer #{idam_client.user_token}", 'user-id' => idam_client.user_details['id'],
        'user-roles' => idam_client.user_details['roles'].join(',') }
    end

    def reverse_rewrite_document_store_urls(json)
      source_host, source_port, dest_host, dest_port = config.document_store_url_rewrite
      JSON.parse(JSON.generate(json).gsub(%r{(https?)://#{Regexp.quote dest_host}:#{Regexp.quote dest_port}}, "\\1://#{source_host}:#{source_port}"))
    end

    def execute_with_document_rewrite(request, source_name:)
      resp = request.execute
      resp_body = resp.body
      logger.debug "ET < Upload file from #{source_name} - #{resp_body}"

      resp_body = rewrite_document_store_urls(resp_body) unless config.document_store_url_rewrite == false
      JSON.parse(resp_body)
    end

    def upload_file_request(filename, content_type, original_filename, url)
      data = { multipart: true, files: UploadedFile.new(filename, content_type: content_type, binary: true, original_filename: original_filename), classification: 'PUBLIC' }
      RestClient::Request.new(method: :post, url: url, payload: data, verify_ssl: config.verify_ssl,
                              headers: { 'ServiceAuthorization' => "Bearer #{idam_client.service_token}", :authorization => "Bearer #{idam_client.user_token}" })
    end

    attr_accessor :idam_client, :logger

    # @return [EtCcdClient::Config] The configuration
    attr_accessor :config
  end
end
