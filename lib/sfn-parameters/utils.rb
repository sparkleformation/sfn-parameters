require 'sfn-parameters'

module SfnParameters
  # Common helper methods
  module Utils

    # Lock the given content
    #
    # @param content [Hash] content to lock
    # @return [Hash] locked content
    def lock_content(content)
      content = content.to_smash
      content.merge!(:sfn_lock_enabled => true)
      safe = SfnParameters::Safe.build(
        config.fetch(:sfn_parameters, :safe, Smash.new)
      )
      safe.lock(dump_json(content))
    end

    # Unlock given content
    #
    # @param content [Hash] content to unlock
    # @return [Hash] unlocked content
    def unlock_content(content)
      content = content.to_smash
      if(content[:sfn_parameters_lock])
        safe = SfnParameters::Safe.build(
          config.fetch(:sfn_parameters, :safe, Smash.new)
        )
        load_json(safe.unlock(content)).to_smash.merge(:sfn_lock_enabled => true)
      else
        content
      end
    end

  end
end
