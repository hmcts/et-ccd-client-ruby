require "addressable/template"
require 'rest_client'
require 'et_ccd_client/config'
require 'et_ccd_client/common_rest_client'
require 'rotp'
module EtCcdClient
  class IdamClient
    include CommonRestClient
    attr_reader :service_token, :user_token, :user_details

    def initialize(config: ::EtCcdClient.config)
      self.config = config
      self.logger = config.logger
      self.service_token = nil
      self.user_token = nil
      self.user_details = nil
    end

    def login(username: config.sidam_username, password: config.sidam_password)
      logger.tagged('EtCcdClient::IdamClient') do
        self.service_token = exchange_service_token
        self.user_token = exchange_sidam_user_token(username, password)
        self.user_details = fetch_user_details
      end
    end

    private

    attr_writer :service_token, :user_token, :user_details
    attr_accessor :config, :logger

    def exchange_service_token
      url = config.idam_service_token_exchange_url
      data = { microservice: config.microservice, oneTimePassword: otp }.to_json
      post_request(url, data, log_subject: 'Idam service token exchange', decode: false)
    end

    def exchange_sidam_user_token(username, password)
      url = config.idam_user_token_exchange_url
      resp = post_request(url, { username: username, password: password }, log_subject: 'Idam user token exchange')
      resp['access_token']
    end

    def fetch_user_details
      url = config.user_details_url
      get_request(url, extra_headers: { 'Accept' => 'application/json', 'Authorization' => user_token }, log_subject: 'Idam get user details')
    end

    def otp
      totp.now
    end

    def totp
      @totp ||= ROTP::TOTP.new(config.microservice_secret)
    end
  end
end
