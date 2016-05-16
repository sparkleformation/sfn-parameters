require 'sfn-parameters'

module SfnParameters
  # Safe storage
  class Safe

    # OpenSSL based Safe implementation
    class Ssl < Safe

      # Default salt for key generation
      CRYPT_SALT='sfn~parameters~crypt~salt'
      # Default cipher
      DEFAULT_CIPHER='AES-256-CBC'
      # Maximum computation iteration length
      CRYPT_ITER=10000
      # Default length of generated key
      CRYPT_KEY_LENGTH=32

      # Create OpenSSL backed safe
      #
      # @param args [Hash]
      # @option :args [String] :cipher name of cipher
      # @option :args [String] :key shared key value
      # @option :args [Integer] :iterations generation interation
      # @option :args [String] :salt value for salting
      # @option :args [Integer] :key_length length of generated key
      # @return [self]
      def initialize(*_)
        super
        unless(arguments[:key])
          raise ArgumentError.new 'Required `:key` argument unset for `Safe::Ssl`!'
        end
      end

      # Lock a given value for storage
      #
      # @param value [String] value to lock
      # @return [Hash] locked content in form {:iv, :content}
      def lock(value)
        cipher = build
        new_iv = cipher.random_iv
        cipher.iv = new_iv
        result = cipher.update(value) + cipher.final
        Smash.new(
          :iv => Base64.urlsafe_encode64(new_iv),
          :cipher => arguments.fetch(:cipher, DEFAULT_CIPHER),
          :content => Base64.urlsafe_encode64(result),
          :sfn_parameters_lock => Bogo::Utility.snake(self.class.name.split('::').last)
        )
      end

      # Unlock a given value for access
      #
      # @param value [Hash] content to unlock
      # @option :value [String] :iv initialization vector value
      # @option :value [String] :content stored content
      # @return [String]
      def unlock(value)
        value = value.to_smash
        o_cipher = arguments[:cipher]
        arguments[:cipher] = value[:cipher] if value[:cipher]
        cipher = build(Base64.urlsafe_decode64(value[:iv]))
        arguments[:cipher] = o_cipher
        string = Base64.urlsafe_decode64(value[:content])
        cipher.update(string) + cipher.final
      end

      protected

      # Build a new cipher
      #
      # @param iv [String] initialization vector
      # @return [OpenSSL::Cipher]
      def build(iv=nil)
        cipher = OpenSSL::Cipher.new(arguments.fetch(:cipher, DEFAULT_CIPHER))
        iv ? cipher.decrypt : cipher.encrypt
        key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(
          arguments[:key],
          arguments.fetch(:salt, CRYPT_SALT),
          arguments.fetch(:iterations, CRYPT_ITER),
          arguments.fetch(:key_length, CRYPT_KEY_LENGTH)
        )
        cipher.iv = iv if iv
        cipher.key = key
        cipher
      end

    end
  end
end
