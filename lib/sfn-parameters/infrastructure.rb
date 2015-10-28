require 'sfn-parameters'

class Sfn
  class Callback
    # Auto load stack parameters for infrastructure pattern
    class ParametersInfrastructure < Callback

      # Valid file extensions for configuration file
      VALID_EXTENSIONS = ['.rb', '.xml', '.json', '.yaml', '.yml']

      # Update configuration after configuration is loaded
      #
      # @return [NilClass]
      def after_config_update(*_)
        config[:parameters] ||= Smash.new
        config[:compile_parameters] ||= Smash.new
        config[:apply_stack] ||= []
        stack_name = arguments.first
        content = load_file_for(stack_name)
        unless(content.keys.map(&:to_s).include?(stack_name))
          raise ArgumentError.new "Expected stack configuration not found! (Expected key - #{stack_name})"
        end
        process_information_hash(content[stack_name], [stack_name])
        nil
      end
      alias_method :after_config_create, :after_config_update

      protected

      # Load the configuration file
      #
      # @param stack_name [String]
      # @return [Smash]
      def load_file_for(stack_name)
        root_path = config.fetch(:sfn_parameters, :directory, 'infrastructure')
        isolation_name = config.fetch(:sfn_parameters, :destination,
          ENV.fetch('SFN_PARAMETERS_DESTINATION', 'default')
        )
        directory = File.join(*[root_path, isolation_name].compact)
        paths = Dir.glob(File.join(directory, "#{isolation_name}{#{VALID_EXTENSIONS.join(',')}}")).map(&:to_s)
        if(paths.size > 1)
          raise ArgumentError.new "Multiple parameter file matches encountered! (#{paths.join(', ')})"
        elsif(paths.empty?)
          raise ArgumentError.new 'No parameter file matches found!'
        end
        Bogo::Config.new(:path => paths.first).data
      end

      # Process the given hash and set configuration values
      #
      # @param hash [Hash]
      # @param path [Array<String>] stack name hierarchy
      # @return [TrueClass]
      def process_information_hash(hash, path=[])
        hash.fetch(:parameters, {}).each do |key, value|
          key = [*path, Bogo::Utility.camel(key)].compact.map(&:to_s).join('_')
          config[:parameters][key] = value
        end
        hash.fetch(:compile_parameters, {}).each do |key, value|
          key = [*path, Bogo::Utility.camel(key)].compact.map(&:to_s).join('_')
          config[:compile_parameters][key] = value
        end
        hash.fetch(:stacks, {}).each do |key, value|
          process_information_hash(value, [*path, value].compact)
        end
        hash.fetch(:apply_stacks, []).each do |s_name|
          config[:apply_stack] << s_name
        end
        true
      end

    end
  end
end
