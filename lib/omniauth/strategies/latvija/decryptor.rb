require 'byebug'
require 'xmlenc'

module OmniAuth::Strategies
  class Latvija
    class Decryptor
      def initialize(response, key)
        @response = response
        @key = key
      end

      def decrypt
        private_key = OpenSSL::PKey::RSA.new(@key)
        encrypted_document = Xmlenc::EncryptedDocument.new(@response)
        encrypted_document.decrypt(private_key)
      end
    end
  end
end
