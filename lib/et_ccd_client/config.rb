require 'singleton'
require 'et_ccd_client/null_logger'
require 'addressable/template'
module EtCcdClient
  class Config
    include Singleton

    attr_accessor :auth_base_url, :idam_base_url, :data_store_base_url, :ecm_base_url, :case_management_ui_base_url, :document_store_base_url, :gateway_api_url,
                  :document_store_url_rewrite, :user_role, :user_id, :jurisdiction_id, :microservice, :microservice_secret, :logger, :verify_ssl, :use_sidam, :sidam_username,
                  :sidam_password, :case_management_ui_redirect_url, :pool_size, :pool_timeout, :proxy

    def idam_service_token_exchange_url
      "#{auth_base_url}/lease"
    end

    def idam_user_token_exchange_url
      use_sidam ? "#{idam_base_url}/loginUser" : "#{idam_base_url}/testing-support/lease"
    end

    def create_case_url
      "#{data_store_base_url}#{create_case_path}"
    end

    def create_case_path
      "/caseworkers/{uid}/jurisdictions/{jid}/case-types/{ctid}/cases"
    end

    def cases_url
      "#{data_store_base_url}#{cases_path}"
    end

    def case_url
      "#{cases_url}/{case_id}"
    end

    def cases_pagination_metadata_url
      "#{data_store_base_url}/caseworkers/{uid}/jurisdictions/{jid}/case-types/{ctid}/cases/pagination_metadata{?query*}"
    end

    def initiate_case_url
      "#{data_store_base_url}#{initiate_case_path}"
    end

    def initiate_case_path
      "/caseworkers/{uid}/jurisdictions/{jid}/case-types/{ctid}/event-triggers/{etid}/token"
    end

    def initiate_document_upload_url
      "#{data_store_base_url}/caseworkers/{uid}/jurisdictions/{jid}/case-types/{ctid}/cases/{cid}/event-triggers/uploadDocument/token"
    end

    def case_events_url
      "#{data_store_base_url}/caseworkers/{uid}/jurisdictions/{jid}/case-types/{ctid}/cases/{cid}/events"
    end

    def upload_file_url
      "#{document_store_base_url}/documents"
    end

    def start_multiple_url
      "#{ecm_base_url}/generateCaseRefNumbers"
    end

    def initiate_claim_event_id
      'initiateCase'
    end

    def initiate_bulk_event_id
      'createMultiple'
    end

    def initiate_document_upload_event_id
      'uploadDocument'
    end

    def case_management_ui_config_url
      "#{case_management_ui_base_url}/config"
    end

    def cases_path
      "/caseworkers/{uid}/jurisdictions/{jid}/case-types/{ctid}/cases{?query*}"
    end

    def user_details_url
      "#{idam_base_url}/details"
    end

    private

    def initialize # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      self.auth_base_url = 'http://localhost:4502'
      self.idam_base_url = 'http://localhost:4501'
      self.data_store_base_url = 'http://localhost:4452'
      self.document_store_base_url = 'http://localhost:4506'
      self.ecm_base_url = 'http://unknown:4506'
      self.document_store_url_rewrite = 'localhost:4506:dm-store:8080'
      self.case_management_ui_redirect_url = 'http://localhost:3451/oauth2redirect'
      self.case_management_ui_base_url = 'http://localhost:3451'
      self.gateway_api_url = 'http://localhost:3453'
      self.user_id = 22
      self.user_role = 'caseworker,caseworker-test,caseworker-employment-tribunal-manchester,caseworker-employment,caseworker-employment-tribunal-manchester-caseofficer,caseworker-publiclaw-localAuthority' # rubocop:disable Metrics/LineLength
      self.jurisdiction_id = 'EMPLOYMENT'
      self.microservice = 'ccd_gw'
      self.microservice_secret = 'AAAAAAAAAAAAAAAC'
      self.logger = NullLogger.new
      self.verify_ssl = true
      self.use_sidam = true
      self.sidam_username = 'm@m.com'
      self.sidam_password = 'Pa55word11'
      self.pool_size = 5
      self.pool_timeout = 30
      self.proxy = false
    end
  end
end
