module OmniAuth::Strategies
  class Latvija
    class Response
      ASSERTION = 'urn:oasis:names:tc:SAML:1.0:assertion'.freeze

      attr_accessor :options, :response

      def initialize(response, **options)
        raise ArgumentError, 'Response cannot be nil' if response.nil?
        @options  = options
        @response = response
        @document = OmniAuth::Strategies::Latvija::SignedDocument.new(response, private_key: options[:private_key])
      end

      def nokogiri_xml
        @response
      end

      def validate!
        @document.validate!(fingerprint)
      end

      def xml
        @document.nokogiri_xml
      end

      def authentication_method
        @authentication_method ||= begin
          xml.xpath('//saml:AuthenticationStatement', saml: ASSERTION).attribute('AuthenticationMethod')
        end
      end

      # A hash of all the attributes with the response.
      # Assuming there is only one value for each key
      def attributes
        @attributes ||= begin

          stmt_elements = xml.xpath('//a:Attribute', a: ASSERTION)
          return {} if stmt_elements.nil?

          stmt_elements.each_with_object({}) do |element, result|
            name  = element.attribute('AttributeName').value
            value = element.text

            result[name] = value
          end
        end
      end

      private

      def fingerprint
        cert = OpenSSL::X509::Certificate.new(options[:certificate])
        Digest::SHA1.hexdigest(cert.to_der).upcase.scan(/../).join(':')
      end
    end
  end
end
