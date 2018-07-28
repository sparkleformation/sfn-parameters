require "sfn-parameters"

module Sfn
  class Callback
    # Auto load stack parameters for single stack pattern
    class ParametersStacks < ParametersInfrastructure

      # Load the configuration file
      #
      # @param stack_name [String]
      # @return [Smash]
      def load_file_for(stack_name)
        root_path = config.fetch(:sfn_parameters, :directory, "stacks")
        paths = Dir.glob(File.join(root_path, "#{stack_name}{#{VALID_EXTENSIONS.join(",")}}")).map(&:to_s)
        if paths.size > 1
          raise ArgumentError.new "Multiple parameter file matches encountered! (#{paths.join(", ")})"
        elsif paths.empty?
          Smash.new
        else
          unlock_content(Bogo::Config.new(paths.first).data)
        end
      end
    end
  end
end
