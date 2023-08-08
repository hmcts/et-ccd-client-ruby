module EtCcdClient
  module Exceptions
    class NotFound < Base
      def to_s
        json = begin
          JSON.parse(response.body)
        rescue StandardError
          JSON::JSONError
        end
        return "Not Found" if json.nil?

        super
      end

    end
  end
end
