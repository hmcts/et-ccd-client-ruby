require "addressable/template"
require "addressable/uri"
require 'et_ccd_client/config'
module EtCcdClient
  class UiIdamClient
    include CommonRestClient
    attr_reader :service_token, :user_token, :user_details

    def initialize(config: ::EtCcdClient.config)
      self.config = config
      self.logger = config.logger
      self.user_details = nil
    end

    def login(username: config.sidam_username, password: config.sidam_password)
      logger.tagged('EtCcdClient::UiIdamClient') do
        self.user_token = exchange_sidam_user_token(username, password)
        self.user_details = user_details_from_idam
      end
    end

    private

    attr_writer :user_token, :user_details
    attr_accessor :config, :logger

    def exchange_sidam_user_token(username, password)
      url = "#{config.idam_base_url}/loginUser"
      resp = post_request(url, { username: username, password: password }, extra_headers: { content_type: 'application/x-www-form-urlencoded', accept: 'application/json' },
                                                                           log_subject: "IdamUI user token exchange")
      resp['access_token']
    end

    def user_details_from_idam
      url = "#{config.idam_base_url}/details"
      get_request(url, extra_headers: { 'Accept' => 'application/json', 'Authorization' => user_token }, log_subject: "UiIdam get user details")
    end
  end
end
