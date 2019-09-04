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
  class Client
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
        new.tap do |client|
          client.login
        end
      end
    end

    delegate login: :idam_client

    # Initiate the case ready for creation
    # @param [String] case_type_id
    #
    # @return [Hash] The json response
    def caseworker_start_case_creation(case_type_id:)
      logger.tagged('EtCcdClient::Client') do
        url = initiate_case_url(case_type_id, config.initiate_claim_event_id)
        get_request_with_login(url, log_subject: 'Start case creation', extra_headers: headers_from_idam_client)
      end
    end

    # Initiate a bulk action case ready for creation
    # @param [String] case_type_id
    #
    # @return [Hash] The json response
    def caseworker_start_bulk_creation(case_type_id:)
      logger.tagged('EtCcdClient::Client') do
        url = initiate_case_url(case_type_id, config.initiate_bulk_event_id)
        get_request_with_login(url, log_subject: 'Start bulk creation', extra_headers: headers_from_idam_client)
      end
    end

    # Initiate a document upload
    # @param [String] case_type_id
    #
    # @return [Hash] The json response
    def caseworker_start_upload_document(case_type_id:)
      url = initiate_document_upload_url(case_type_id)
      get_request_with_login(url, log_subject: 'Start upload document', extra_headers: headers_from_idam_client)
    end

    # @param [Hash] data
    # @param [String] case_type_id
    #
    # @return [Hash] The json response
    def caseworker_case_create(data, case_type_id:)
      logger.tagged('EtCcdClient::Client') do
        tpl = Addressable::Template.new(config.create_case_url)
        url = tpl.expand(uid: idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id).to_s
        post_request_with_login(url, data, log_subject: 'Case worker create case', extra_headers: headers_from_idam_client)
      end
    end

    # Search for cases by reference - useful for testing
    # @param [String] reference The reference number to search for
    # @param [String] case_type_id The case type ID to set the search scope to
    # @param [Integer] page - The page number to fetch
    # @param [String] sort_direction (defaults to 'desc') - Change to 'asc' to do oldest first
    #
    # @return [Array<Hash>] The json response from the server
    def caseworker_search_by_reference(reference, case_type_id:, page: 1, sort_direction: 'desc')
      logger.tagged('EtCcdClient::Client') do
        tpl = Addressable::Template.new(config.cases_url)
        url = tpl.expand(uid: idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id, query: { 'case.feeGroupReference' => reference, page: page, 'sortDirection' => sort_direction }).to_s
        get_request_with_login(url, log_subject: 'Caseworker search by reference', extra_headers: headers_from_idam_client)
      end
    end

    # Search for the latest case matching the reference.  Useful for testing
    # @param [String] reference The reference number to search for
    # @param [String] case_type_id The case type ID to set the search scope to
    # @return [Hash] The case object returned from the server
    def caseworker_search_latest_by_reference(reference, case_type_id:)
      results = caseworker_search_by_reference(reference, case_type_id: case_type_id, page: 1, sort_direction: 'desc')
      results.first
    end

    # Search for cases by multiple reference - useful for testing
    # @param [String] reference The multiples reference number to search for
    # @param [String] case_type_id The case type ID to set the search scope to
    # @param [Integer] page - The page number to fetch
    # @param [String] sort_direction (defaults to 'desc') - Change to 'asc' to do oldest first
    #
    # @return [Array<Hash>] The json response from the server
    def caseworker_search_by_multiple_reference(reference, case_type_id:, page: 1, sort_direction: 'desc')
      logger.tagged('EtCcdClient::Client') do
        tpl = Addressable::Template.new(config.cases_url)
        url = tpl.expand(uid: idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id, query: { 'case.multipleReference' => reference, page: page, 'sortDirection' => sort_direction }).to_s
        get_request_with_login(url, log_subject: 'Caseworker search by multiple reference', extra_headers: headers_from_idam_client)
      end
    end

    # Search for the latest case matching the multiples reference.  Useful for testing
    # @param [String] reference The multiples reference number to search for
    # @param [String] case_type_id The case type ID to set the search scope to
    # @return [Hash] The case object returned from the server
    def caseworker_search_latest_by_multiple_reference(reference, case_type_id:)
      results = caseworker_search_by_multiple_reference(reference, case_type_id: case_type_id, page: 1, sort_direction: 'desc')
      results.first
    end

    # Search for cases by ethos case reference - useful for testing
    # @param [String] reference The ethos case reference number to search for
    # @param [String] case_type_id The case type ID to set the search scope to
    # @param [Integer] page - The page number to fetch
    # @param [String] sort_direction (defaults to 'desc') - Change to 'asc' to do oldest first
    #
    # @return [Array<Hash>] The json response from the server
    def caseworker_search_by_ethos_case_reference(reference, case_type_id:, page: 1, sort_direction: 'desc')
      logger.tagged('EtCcdClient::Client') do
        tpl = Addressable::Template.new(config.cases_url)
        url = tpl.expand(uid: idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id, query: { 'case.ethosCaseReference' => reference, page: page, 'sortDirection' => sort_direction }).to_s
        resp = get_request_with_login(url, log_subject: 'Caseworker search by ethos case reference', extra_headers: headers_from_idam_client)
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
    def caseworker_search_latest_by_ethos_case_reference(reference, case_type_id:)
      results = caseworker_search_by_ethos_case_reference(reference, case_type_id: case_type_id, page: 1, sort_direction: 'desc')
      results.first
    end


    def caseworker_cases_pagination_metadata(case_type_id:, query: {})
      logger.tagged('EtCcdClient::Client') do
        tpl = Addressable::Template.new(config.cases_pagination_metadata_url)
        url = tpl.expand(uid: idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id, query: query).to_s
        get_request_with_login(url, log_subject: 'Caseworker cases pagination metadata', extra_headers: headers_from_idam_client)
      end
    end

    # @param [String] filename The full path to the file to upload
    # @return [Hash] The object returned by the server
    def upload_file_from_filename(filename, content_type:)
      login_on_forbidden do
        upload_file_from_source(filename, content_type: content_type, source_name: :filename, source: filename)
      end
    end

    # @param [String] url The url of the file to upload
    # @return [Hash] The object returned by the server
    def upload_file_from_url(url, content_type:, original_filename: File.basename(url))
      resp = download_from_remote_source(url)
      login_on_forbidden do
        upload_file_from_source(resp.file.path, content_type: content_type, source_name: :url, source: url, original_filename: original_filename)
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

    def upload_file_from_source(filename, content_type:, source_name:, source:, original_filename: filename)
      logger.tagged('EtCcdClient::Client') do
        url = config.upload_file_url
        logger.debug("ET > Upload file from #{source_name} (#{url})")
        uploaded_file = UploadedFile.new(filename, content_type: content_type, binary: true, original_filename: original_filename)
        data = {
          multipart: true,
          files: uploaded_file,
          classification: 'PUBLIC'
        }
        request = RestClient::Request.new(method: :post, url: url, payload: data, headers: { 'ServiceAuthorization' => "Bearer #{idam_client.service_token}", :authorization => "Bearer #{idam_client.user_token}" }, verify_ssl: config.verify_ssl)
        resp = request.execute
        resp_body = resp.body
        logger.debug "ET < Upload file from #{source_name} - #{resp_body}"
        unless config.document_store_url_rewrite == false
          resp_body = rewrite_document_store_urls(resp_body)
        end
        JSON.parse(resp_body)
      rescue RestClient::Exception => e
        logger.debug "ET < Upload file from #{source_name} (ERROR) - #{e.response.body}"
        Exceptions::Base.raise_exception(e, url: url, request: request)
      end
    end

    def initiate_case_url(case_type_id, event_id)
      tpl = Addressable::Template.new(config.initiate_case_url)
      tpl.expand(uid: idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id, etid: event_id).to_s
    end

    def initiate_document_upload_url(case_type_id)
      tpl = Addressable::Template.new(config.initiate_case_url)
      tpl.expand(uid: idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id, etid: config.initiate_document_upload_event_id).to_s
    end

    def rewrite_document_store_urls(body)
      source_host, source_port, dest_host, dest_port = config.document_store_url_rewrite
      body.gsub(/(https?):\/\/#{Regexp.quote source_host}:#{Regexp.quote source_port}/, "\\1://#{dest_host}:#{dest_port}")
    end

    def headers_from_idam_client
      {'ServiceAuthorization' => "Bearer #{idam_client.service_token}", :authorization => "Bearer #{idam_client.user_token}", 'user-id' => idam_client.user_details['id'], 'user-roles' => idam_client.user_details['roles'].join(',')}
    end

    def reverse_rewrite_document_store_urls(json)
      source_host, source_port, dest_host, dest_port = config.document_store_url_rewrite
      JSON.parse(JSON.generate(json).gsub(/(https?):\/\/#{Regexp.quote dest_host}:#{Regexp.quote dest_port}/, "\\1://#{source_host}:#{source_port}"))
    end

    attr_accessor :idam_client, :config, :logger
  end
end
