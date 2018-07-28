require "sfn-parameters"

module Sfn
  class Callback
    # Auto load stack parameters for infrastructure pattern
    class ParametersInfrastructure < Callback
      include Sfn::Utils::JSON
      include SfnParameters::Utils

      # Valid file extensions for configuration file
      VALID_EXTENSIONS = [".rb", ".xml", ".json", ".yaml", ".yml"]

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

      alias_method :after_config, :after_config_update

      protected

      # Load the configuration file
      #
      # @param stack_name [String]
      # @return [Smash]
      def load_file_for(stack_name)
        root_path = config.fetch(:sfn_parameters, :directory, "infrastructure")
        isolation_name = config.fetch(
          :sfn_parameters, :destination,
          ENV.fetch("SFN_PARAMETERS_DESTINATION", "default")
        )
        paths = Dir.glob(File.join(root_path, "#{isolation_name}{#{VALID_EXTENSIONS.join(",")}}")).map(&:to_s)
        if paths.size > 1
          raise ArgumentError.new "Multiple parameter file matches encountered! (#{paths.join(", ")})"
        elsif paths.empty?
          Smash.new
        else
          unlock_content(Bogo::Config.new(paths.first).data)
        end
      end

      # Process the given hash and set configuration values
      #
      # @param hash [Hash]
      # @param path [Array<String>] stack name hierarchy
      # @return [TrueClass]
      def process_information_hash(hash, path = [])
        if path.empty? && hash[:template]
          config[:file] = hash[:template]
        end
        hash.fetch(:parameters, {}).each do |key, value|
          key = [*path, key].compact.map(&:to_s).join("__")
          if current_value = config[:parameters][key]
            ui.debug "Not setting template parameter `#{key}`. Already set within config. (`#{current_value}`)"
          else
            config[:parameters][key] = value
          end
        end
        hash.fetch(:compile_parameters, {}).each do |key, value|
          key = [*path, key].compact.map(&:to_s).join("__")
          if current_value = config[:compile_parameters][key]
            ui.debug "Not setting compile time parameter `#{key}`. Already set within config. (`#{current_value}`)"
          else
            config[:compile_parameters][key] = value
          end
        end
        hash.fetch(:stacks, {}).each do |key, value|
          process_information_hash(value, [*path, key].compact)
        end
        hash.fetch(:mappings, {}).each do |key, value|
          value = [*path, Bogo::Utility.camel(value)].compact.map(&:to_s).join("__")
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
