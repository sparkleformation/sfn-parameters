require 'sfn-parameters'

module Sfn
  class Command
    # Parameters command
    class Parameters < Command

      include SfnParameters::Utils
      include Sfn::CommandModule::Base

      # Execute parameters action request
      def execute!
        action, item = arguments[0,2]
        ui.info "Running parameters action #{ui.color(action.to_s, :bold)}"
        case action.to_sym
        when :lock
          item = validate_item(item)
          ui.print " Locking #{ui.color(item, :bold)}... "
          content = load_json(File.read(item)).to_smash
          if(content[:sfn_parameters_lock])
            ui.puts ui.color('no-op', :yellow)
            ui.warn "Item is already locked! (#{item})"
          else
            thing = lock_content(content)
            val = format_json(thing)
            File.write(item, val)
            ui.puts ui.color('locked', :blue)
          end
        when :unlock
          item = validate_item(item)
          ui.print " Unlocking #{ui.color(item, :bold)}... "
          content = load_json(File.read(item)).to_smash
          if(content[:sfn_parameters_lock])
            content = unlock_content(content)
            content.delete(:sfn_lock_enabled)
            File.write(item, format_json(content))
            ui.puts ui.color('unlocked', :green)
          else
            ui.puts ui.color('no-op', :yellow)
            ui.warn "Item is already unlocked! (#{item})"
          end
        when :show
          item = validate_item(item)
          content = load_json(File.read(item)).to_smash
          if(content[:sfn_parameters_lock])
            ui.print ui.color(' *', :bold)
            ui.print " Unlocking #{ui.color(item, :bold)} for display... "
            content = unlock_content(content)
            content.delete(:sfn_lock_enabled)
            ui.puts ui.color('unlocked', :green)
          end
          ui.puts format_json(content)
        when :create, :edit
          unless(ENV['EDITOR'])
            raise ArgumentError.new '$EDITOR must be set for create/edit commands!'
          end
          begin
            item = validate_item(item)
          rescue ArgumentError
            new_item = true
            item = new_item(item)
          end
          FileUtils.mkdir_p(File.dirname(item))
          tmp = Bogo::EphemeralFile.new('sfn-parameters')
          content = new_item ? Smash.new : load_json(File.read(item)).to_smash
          if(content[:sfn_parameters_lock])
            ui.print ui.color(' *', :bold)
            ui.print " Unlocking #{ui.color(item, :bold)} for edit... "
            content = unlock_content(content)
            ui.puts ui.color('unlocked', :green)
          end
          lock_enabled = content.delete(:sfn_lock_enabled) || new_item
          tmp.write(format_json(content))
          tmp.flush
          system("#{ENV['EDITOR']} #{tmp.path}")
          tmp.rewind
          content = load_json(tmp.read).to_smash
          ui.print ui.color(' *', :bold)
          if(lock_enabled)
            ui.print " Locking #{ui.color(item, :bold)} for storage... "
            content = lock_content(content)
            ui.puts ui.color('locked', :blue)
          else
            ui.puts " Storing #{ui.color(item, :bold)} for storage... #{ui.color('unlocked', :yellow)}"
          end
          File.write(item, format_json(content))
          tmp.close
        else
          ArgumentError.new "Unsupported action received `#{action}`. " \
            "Allowed: lock, unlock, show, create, edit"
        end
      end

      # Expand path for new item if required
      #
      # @param item [String]
      # @return [String]
      def new_item(item)
        unless(item.include?(File::SEPARATOR))
          prefixes = [
            config.get(:sfn_parameters, :directory),
            'infrastructure',
            'stacks'
          ].compact
          prefix = prefixes.find_all do |dir|
            File.directory?(dir)
          end
          if(prefix.size > 1)
            raise ArgumentError.new "Unable to auto-determine directory for item! Multiple directories found. " \
              "(detected: #{prefix.join(', ')})"
          elsif(prefix.empty?)
            raise ArgumentError.new "No existing parameter directories found. Please create required directory. " \
              "(checked: #{prefixes.join(', ')})"
          end
          File.join(prefix.first, "#{item}.json")
        end
      end

      # Validate existence of requested item. Expand path
      # if only name given
      #
      # @param item [String]
      # @return [String]
      def validate_item(item)
        items = [
          item,
          File.join(
            config.fetch(
              :sfn_parameters, :directory, 'stacks'
            ),
            item
          ),
          File.join(
            config.fetch(
              :sfn_parameters, :directory, 'stacks'
            ),
            "#{item}.json"
          ),
          File.join(
            config.fetch(
              :sfn_parameters, :directory, 'infrastructure'
            ),
            item
          ),
          File.join(
            config.fetch(
              :sfn_parameters, :directory, 'infrastructure'
            ),
            "#{item}.json"
          )
        ]
        valid = items.find_all do |file|
          File.exist?(file)
        end
        if(valid.empty?)
          raise ArgumentError.new "Failed to locate item `#{item}`!"
        elsif(valid.size > 1)
          raise ArgumentError.new "Multiple matches detected for item `#{item}`. " \
            "(Matches: #{valid.join(', ')})"
        else
          valid.first
        end
      end

    end
  end
end
