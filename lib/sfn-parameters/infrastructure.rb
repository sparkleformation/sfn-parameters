require 'sfn-parameters'

module Sfn
  class Callback
    # Auto load stack parameters for infrastructure pattern
    class ParametersInfrastructure < Callback

      include Sfn::Utils::JSON
      include SfnParameters::Utils

      # Valid file extensions for configuration file
      VALID_EXTENSIONS = ['.rb', '.xml', '.json', '.yaml', '.yml']

      # @return [TrueClass] silence callback run notification
      def quiet
        config.fetch(:sfn_parameters, :quiet, false)
      end

      # Update configuration after configuration is loaded
      #
      # @return [NilClass]
      def after_config_update(*_)
        config[:parameters] ||= Smash.new
        config[:compile_parameters] ||= Smash.new
        config[:apply_stack] ||= []
        config[:apply_mapping] ||= Smash.new
        stack_name = arguments.first
        content = load_file_for(stack_name)
        process_information_hash(content, [])
        nil
      end
      alias_method :after_config_create, :after_config_update

      protected

      # Load the configuration file
      #
      # @param stack_name [String]
      # @return [Smash]
      def load_file_for(stack_name)
        isolation_name = config.fetch(:sfn_parameters, :destination,
          ENV.fetch('SFN_PARAMETERS_DESTINATION', 'default')
        )
        expand_config_file(unpack_file(parameters_directory, isolation_name))
      end

      # Detect and expand defined definitions
      #
      # @param config [Smash] current configuration
      # @return [Smash] expanded config
      def expand_config_file(config)
        new_config = config.to_smash
        definitions = config.fetch(:definitions, [])
        if(definitions.is_a?(Array))
          definitions.each do |def_name|
            definition = load_definition(def_name)
            new_config.deep_merge!(definition)
          end
        end
        new_config.keys.each do |key, value|
          if(value.is_a?(Hash))
            new_config[key] = expand_config_file(value)
          end
        end
        new_config
      end

      # Define parameters directory for infrastructure based files
      #
      # @return [String]
      def parameters_directory
        config.fetch(:sfn_parameters, :directory, 'infrastructure')
      end

      # Read and unpack file
      #
      # @param directory [String] directory path
      # @param name [String] file name without extension
      # @return [Smash]
      def unpack_file(directory, name)
        paths = Dir.glob(File.join(directory, "#{name}{#{VALID_EXTENSIONS.join(',')}}")).map(&:to_s)
        if(paths.size > 1)
          raise ArgumentError.new "Multiple parameter file matches encountered! (#{paths.join(', ')})"
        elsif(paths.empty?)
          Smash.new
        else
          unlock_content(Bogo::Config.new(paths.first).data)
        end
      end

      # Load defintion file of given name
      #
      # @param name [String] name of definition
      # @return [Smash] definition contents
      def load_definition(name)
        unpack_file(File.join(parameters_directory, 'definitions'), name)
      end

      # Process the given hash and set configuration values
      #
      # @param hash [Hash]
      # @param path [Array<String>] stack name hierarchy
      # @return [TrueClass]
      def process_information_hash(hash, path=[])
        if(path.empty? && hash[:template])
          config[:file] = hash[:template]
        end
        hash.fetch(:parameters, {}).each do |key, value|
          key = [*path, key].compact.map(&:to_s).join('__')
          if(current_value = config[:parameters][key])
            ui.debug "Not setting template parameter `#{key}`. Already set within config. (`#{current_value}`)"
          else
            config[:parameters][key] = value
          end
        end
        hash.fetch(:compile_parameters, {}).each do |key, value|
          key = [*path, key].compact.map(&:to_s).join('__')
          if(current_value = config[:compile_parameters][key])
            ui.debug "Not setting compile time parameter `#{key}`. Already set within config. (`#{current_value}`)"
          else
            config[:compile_parameters][key] = value
          end
        end
        hash.fetch(:stacks, {}).each do |key, value|
          process_information_hash(value, [*path, key].compact)
        end
        hash.fetch(:mappings, {}).each do |key, value|
          value = [*path, Bogo::Utility.camel(value)].compact.map(&:to_s).join('__')
          config[:apply_mapping][key] = value
        end
        hash.fetch(:apply_stacks, []).each do |s_name|
          config[:apply_stack] << s_name
        end
        true
      end
    end
  end
end
