require 'aws-sdk-ssm'

module SfnParameters
  module Resolvers
    class ParameterStore

      def initialize; end

      def resolve(value)
        begin
          resp = ssm.get_parameter(
            name: value,
            with_decryption: true
          )
        rescue Aws::SSM::Errors::ParameterNotFound
          raise "Unable to find '#{value}' in Parameter Store"
        end
        resp.parameter.value
      end

      private

      def ssm
        @ssm ||= Aws::SSM::Client.new
      end

    end
  end
end
