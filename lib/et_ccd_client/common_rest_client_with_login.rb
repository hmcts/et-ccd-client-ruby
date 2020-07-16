module EtCcdClient
  module CommonRestClientWithLogin

    private

    def get_request_with_login(*args)
      login_on_denial do
        get_request(*args)
      end
    end

    def post_request_with_login(*args)
      login_on_denial do
        post_request(*args)
      end
    end

    def login_on_denial
      retried = false
      begin
        yield
      rescue EtCcdClient::Exceptions::Forbidden, EtCcdClient::Exceptions::Unauthorized => e
        raise if retried

        retried = true
        logger.tagged('Re logging in') do
          login
        end
        retry
      end
    end
  end
end
