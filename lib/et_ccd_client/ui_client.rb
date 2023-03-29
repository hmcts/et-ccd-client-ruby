require "addressable/template"
require 'rest_client'
require 'et_ccd_client/ui_idam_client'
require 'et_ccd_client/config'
require 'et_ccd_client/exceptions'
require 'et_ccd_client/common_rest_client'
require 'json'
require 'forwardable'
module EtCcdClient
  # A client to interact with the CCD UI API (front end)
  class UiClient
    extend Forwardable
    include CommonRestClient

    def initialize(ui_idam_client: UiIdamClient.new, config: ::EtCcdClient.config)
      self.ui_idam_client = ui_idam_client
      self.config = config
      self.logger = config.logger
    end

    delegate login: :ui_idam_client

    # Search for cases by reference - useful for testing
    # @param [String] reference The reference number to search for
    # @param [String] case_type_id The case type ID to set the search scope to
    # @param [Integer] page - The page number to fetch
    # @param [String] sort_direction (defaults to 'desc') - Change to 'asc' to do oldest first
    #
    # @return [Array<Hash>] The json response from the server
    def caseworker_search_by_reference(reference, case_type_id:, page: 1, sort_direction: 'desc')
      logger.tagged('EtCcdClient::UiClient') do
        tpl = Addressable::Template.new(config.cases_path)
        path = tpl.expand(uid: ui_idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id, query: { 'case.feeGroupReference' => reference, page: page, 'sortDirection' => sort_direction }).to_s
        url = "#{config.gateway_api_url}/aggregated#{path}"
        resp = get_request(url, log_subject: 'Caseworker search by reference', extra_headers: { content_type: 'application/json', accept: 'application/json' }, cookies: { accessToken: ui_idam_client.user_token })
        unless config.document_store_url_rewrite == false
          resp = reverse_rewrite_document_store_urls(resp)
        end
        resp["results"]
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

    # Search for cases by ethos case reference - useful for testing
    # @param [String] reference The ethos case reference number to search for
    # @param [String] case_type_id The case type ID to set the search scope to
    # @param [Integer] page - The page number to fetch
    # @param [String] sort_direction (defaults to 'desc') - Change to 'asc' to do oldest first
    #
    # @return [Array<Hash>] The json response from the server
    def caseworker_search_by_ethos_case_reference(reference, case_type_id:, page: 1, sort_direction: 'desc')
      logger.tagged('EtCcdClient::UiClient') do
        tpl = Addressable::Template.new(config.cases_path)
        path = tpl.expand(uid: ui_idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id, query: { 'case.ethosCaseReference' => reference, page: page, 'sortDirection' => sort_direction }).to_s
        url = "#{config.gateway_api_url}/aggregated#{path}"
        resp = get_request(url, log_subject: 'Caseworker search by ethos case reference', extra_headers: { content_type: 'application/json', accept: 'application/json' }, cookies: { accessToken: ui_idam_client.user_token })
        unless config.document_store_url_rewrite == false
          resp = reverse_rewrite_document_store_urls(resp)
        end
        resp["results"]
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

    # Search for cases by multiples reference - useful for testing
    # @param [String] reference The multiples reference number to search for
    # @param [String] case_type_id The case type ID to set the search scope to
    # @param [Integer] page - The page number to fetch
    # @param [String] sort_direction (defaults to 'desc') - Change to 'asc' to do oldest first
    #
    # @return [Array<Hash>] The json response from the server
    def caseworker_search_by_multiple_reference(reference, case_type_id:, page: 1, sort_direction: 'desc')
      logger.tagged('EtCcdClient::UiClient') do
        tpl = Addressable::Template.new(config.cases_path)
        path = tpl.expand(uid: ui_idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id, query: { 'case.multipleReference' => reference, page: page, 'sortDirection' => sort_direction }).to_s
        url = "#{config.gateway_api_url}/aggregated#{path}"
        resp = get_request(url, log_subject: 'Case worker search by multiple reference', extra_headers: { content_type: 'application/json', accept: 'application/json' }, cookies: { accessToken: ui_idam_client.user_token })
        resp["results"]
      end
    end

    # Search for the latest case matching the multiple reference.  Useful for testing
    # @param [String] reference The multiples reference number to search for
    # @param [String] case_type_id The case type ID to set the search scope to
    # @return [Hash] The case object returned from the server
    def caseworker_search_latest_by_multiple_reference(reference, case_type_id:)
      results = caseworker_search_by_multiple_reference(reference, case_type_id: case_type_id, page: 1, sort_direction: 'desc')
      results.first
    end

    # Search for cases by bulk case title - useful for testing
    # @param [String] case_title The bulk case title to search for
    # @param [String] case_type_id The case type ID to set the search scope to
    # @param [Integer] page - The page number to fetch
    # @param [String] sort_direction (defaults to 'desc') - Change to 'asc' to do oldest first
    #
    # @return [Array<Hash>] The json response from the server
    def caseworker_search_by_bulk_case_title(case_title, case_type_id:, page: 1, sort_direction: 'desc')
      logger.tagged('EtCcdClient::UiClient') do
        tpl = Addressable::Template.new(config.cases_path)
        path = tpl.expand(uid: ui_idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id, query: { 'case.multipleName' => case_title, page: page, 'sortDirection' => sort_direction }).to_s
        url = "#{config.gateway_api_url}/aggregated#{path}"
        resp = get_request(url, log_subject: 'Case worker search by bulk case title', extra_headers: { content_type: 'application/json', accept: 'application/json' }, cookies: { accessToken: ui_idam_client.user_token })
        resp["results"]
      end
    end

    # Search for the latest case matching the bulk case title.  Useful for testing
    # @param [String] case-title The bulk case title to search for
    # @param [String] case_type_id The case type ID to set the search scope to
    # @return [Hash] The case object returned from the server
    def caseworker_search_latest_by_bulk_case_title(case_title, case_type_id:)
      results = caseworker_search_by_bulk_case_title(case_title, case_type_id: case_type_id, page: 1, sort_direction: 'desc')
      results.first
    end

    # List all cases (paginated)
    # @param [String] case_type_id The case type ID to set the search scope to
    # @param [Integer] page - The page number to fetch
    # @param [String] sort_direction (defaults to 'desc') - Change to 'asc' to do oldest first
    #
    # @return [Array<Hash>] The json response from the server
    def caseworker_list_cases(case_type_id:, page: 1, sort_direction: 'desc')
      logger.tagged('EtCcdClient::UiClient') do
        tpl = Addressable::Template.new(config.cases_path)
        path = tpl.expand(uid: ui_idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id, query: { page: page, 'sortDirection' => sort_direction }).to_s
        url = "#{config.gateway_api_url}/aggregated#{path}"
        resp = get_request(url, log_subject: 'List all cases', extra_headers: { content_type: 'application/json', accept: 'application/json' }, cookies: { accessToken: ui_idam_client.user_token })
        resp["results"]
      end
    end

    # Initiate the case ready for creation
    # @param [String] case_type_id
    #
    # @return [Hash] The json response
    def caseworker_start_case_creation(case_type_id:, extra_headers: {})
      logger.tagged('EtCcdClient::Client') do
        path = initiate_case_path(case_type_id, config.initiate_claim_event_id)
        url = "#{config.gateway_api_url}/aggregated#{path}"

        get_request(url, log_subject: 'Start case creation', extra_headers: { content_type: 'application/json', accept: 'application/json' }, cookies: { accessToken: ui_idam_client.user_token })
      end
    end

    # @param [Hash] data
    # @param [String] case_type_id
    #
    # @return [Hash] The json response
    def caseworker_case_create(data, case_type_id:, extra_headers: {})
      logger.tagged('EtCcdClient::Client') do
        tpl = Addressable::Template.new(config.create_case_path)
        path = tpl.expand(uid: ui_idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id).to_s
        url = "#{config.gateway_api_url}/aggregated#{path}"
        post_request(url, data, log_subject: 'Case worker create case', extra_headers: { content_type: 'application/json', accept: 'application/json' }, cookies: { accessToken: ui_idam_client.user_token })
      end
    end




    private

    attr_accessor :ui_idam_client, :config, :logger

    def reverse_rewrite_document_store_urls(json)
      source_host, source_port, dest_host, dest_port = config.document_store_url_rewrite
      JSON.parse(JSON.generate(json).gsub(/(https?):\/\/#{Regexp.quote dest_host}:#{Regexp.quote dest_port}/, "\\1://#{source_host}:#{source_port}"))
    end

    def initiate_case_path(case_type_id, event_id)
      tpl = Addressable::Template.new(config.initiate_case_path)
      tpl.expand(uid: ui_idam_client.user_details['id'], jid: config.jurisdiction_id, ctid: case_type_id, etid: event_id).to_s
    end
  end
end
