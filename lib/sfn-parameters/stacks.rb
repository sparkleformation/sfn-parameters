require 'sfn-parameters'

module Sfn
  class Callback
    # Auto load stack parameters for single stack pattern
    class ParametersStacks < ParametersInfrastructure

      # Load the configuration file
      #
      # @param stack_name [String]
      # @return [Smash]
      def load_file_for(stack_name)
        unpack_file(parameters_directory, stack_name)
      end

      # Define parameters directory for stacks based files
      #
      # @return [String]
      def parameters_directory
        config.fetch(:sfn_parameters, :directory, 'stacks')
      end

    end
  end
end
