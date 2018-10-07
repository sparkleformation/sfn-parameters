require "sfn-parameters"

module SfnParameters
  # Parameter resolver
  class Resolver
    @@resolvers = {}

    # :nodoc:
    # Used only for testing
    def self.reset!
      @@resolvers.clear
    end

    # :nodoc:
    def self.inherited(klass)
      if klass.name.nil?
        raise ArgumentError.new("Unnamed classes are not supported")
      end
      klass_key = Bogo::Utility.snake(klass.name).gsub("::", "_")
      @@resolvers[klass_key] = klass
    end

    # @return [Array<Resolver>]
    def self.resolvers
      @@resolvers.values
    end

    # Find resolver that matches given name
    #
    # @param name [String] resolver identifier name
    # @return [Resolver] resolver class
    # @raises [NameError]
    def self.detect_resolver(name)
      name = Bogo::Utility.snake(name).gsub("::", "_")
      @@resolvers.each do |klass_name, klass|
        return klass if klass_name.end_with?(name)
      end
      raise NameError.new("Unknown resolver requested `#{name}` - #{resolvers}")
    end

    # @return [Hash] sfn config
    attr_reader :config

    # Resolver initialization. It is provided
    # the configuration from sfn to allow for
    # any required customizations
    #
    # @param config [Hash] sfn config
    # @return [self]
    def initialize(config)
      @config = config
      setup
    end

    # Run any required setup for the resolver
    def setup; end

    # Resolve the given value. Value will be
    # a Hash type but should be validated
    # locally
    #
    # @param value [Hash]
    # @return [Object]
    def resolve(value)
      raise NotImplementedError
    end
  end
end
