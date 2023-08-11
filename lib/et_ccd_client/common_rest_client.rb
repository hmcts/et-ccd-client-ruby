module EtCcdClient
  module CommonRestClient
    def get_request(url, log_subject:, extra_headers: {}, decode: true, cookies: {})
      logger.debug("ET > #{log_subject} (#{url})")
      req = RestClient::Request.new(method: :get, url: url, headers: { content_type: 'application/json' }.merge(extra_headers), cookies: cookies, verify_ssl: config.verify_ssl,
                                    proxy: common_rest_client_proxy)
      resp = req.execute
      logger.debug "ET < #{log_subject} - #{resp.body}"
      common_rest_client_decode_response(resp, decode: decode)
    rescue RestClient::Exception => e
      common_rest_client_log_exception(e, log_subject: log_subject)
      Exceptions::Base.raise_exception(e, url: url, request: req)
    end

    def post_request(url, data, log_subject:, extra_headers: {}, decode: true, cookies: {}) # rubocop:disable Metrics/ParameterLists
      logger.debug("ET > #{log_subject} (#{url}) - #{data.to_json}")
      req = RestClient::Request.new(method: :post, url: url, payload: data, headers: { content_type: 'application/json' }.merge(extra_headers), cookies: cookies,
                                    verify_ssl: config.verify_ssl, proxy: common_rest_client_proxy)
      resp = req.execute
      logger.debug "ET < #{log_subject} - #{resp.body}"
      common_rest_client_decode_response(resp, decode: decode)
    rescue RestClient::Exception => e
      common_rest_client_log_exception(e, log_subject: log_subject)
      Exceptions::Base.raise_exception(e, url: url, request: req)
    end

    private

    def common_rest_client_proxy
      config.proxy == false || config.proxy.blank? ? nil : "http://#{config.proxy}"
    end

    def common_rest_client_decode_response(resp, decode: true)
      decode ? JSON.parse(resp.body) : resp.body
    end

    def common_rest_client_log_exception(exception, log_subject:)
      logger.debug "ET < #{log_subject} (ERROR) - #{exception.response&.body}"
    end
  end
end
