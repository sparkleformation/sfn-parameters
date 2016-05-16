require 'sfn-parameters'

module SfnParameters
  # Safe storage
  class Safe

    autoload :Ssl, 'sfn-parameters/safe/ssl'

    # @return [Hash] safe configuration
    attr_reader :arguments

    # Create a new safe
    #
    # @param args [Hash]
    # @return [self]
    def initialize(args={})
      @arguments = args.to_smash
    end

    # Lock a given value for storage
    #
    # @param value [String] value to lock
    # @return [Hash]
    def lock(value)
      raise NotImplementedError
    end

    # Unlock a given value for access
    #
    # @param value [Hash] content to unlock
    # @return [String]
    def unlock(value)
      raise NotImplementedError
    end

    class << self

      # Build a new safe instance
      #
      # @param args [Hash] arguments for safe instance
      # @option args [String] :type type of safe
      # @return [Safe]
      def build(args={})
        args = args.to_smash
        type = Bogo::Utility.camel(args.fetch(:type, 'ssl'))
        if(const_defined?(type))
          const_get(type).new(args)
        else
          raise ArgumentError.new "Unknown safe type provided `#{type}`."
        end
      end

    end

  end
end
