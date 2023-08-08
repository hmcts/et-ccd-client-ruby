module EtCcdClient
  module Exceptions
    class UnprocessableEntity < Base
      def to_s
        json = begin
          JSON.parse(response.body)
        rescue StandardError
          JSON::JSONError
        end
        return super if json.nil? || json == JSON::JSONError

        field_errors = json.dig('details', 'field_errors')&.map do |field_error|
          "#{field_error['id']} => #{field_error['message']}"
        end
        return super if field_errors.nil?

        "#{super} - #{field_errors.join(', ')}"
      end

    end
  end
end
