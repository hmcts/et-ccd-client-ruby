require "singleton"
require "json"
require "rest-client"
module EtCcdClient
  class UiRemoteConfig
    include Singleton
    attr_accessor :login_url, :logout_url, :api_url, :case_data_url, :document_management_url, :remote_document_management_url
    attr_accessor :pagination_page_size, :postcode_lookup_url, :oauth2_token_endpoint_url, :oauth2_client_id

    private :login_url=, :logout_url=, :api_url=, :case_data_url=, :document_management_url=, :remote_document_management_url=
    private :pagination_page_size=, :postcode_lookup_url=, :oauth2_token_endpoint_url=, :oauth2_client_id=

    private

    def initialize
      dynamic_config = JSON.parse(RestClient::Request.execute(method: :get, url: Config.instance.case_management_ui_config_url, verify_ssl: Config.instance.verify_ssl,
                                                              proxy: Config.instance.proxy).body)
      dynamic_config.each_pair do |key, value|
        setter = :"#{key}="
        send(setter, value) if respond_to?(setter, true)
      end
    end
  end
end
