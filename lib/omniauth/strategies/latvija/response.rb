module OmniAuth::Strategies
  class Latvija
    class Response
      ASSERTION = 'urn:oasis:names:tc:SAML:1.0:assertion'

      attr_accessor :options, :response, :document

      def initialize(response, **options)
        raise ArgumentError.new('Response cannot be nil') if response.nil?
        @options  = options
        @response = response
        @document = OmniAuth::Strategies::Latvija::SignedDocument.new(response, private_key: options[:private_key])
      end

      def validate!
        document.validate!(fingerprint)
      end

      def authentication_method
        @authentication_method ||= begin
          REXML::XPath.first(document, "//saml:AuthenticationStatement").attributes['AuthenticationMethod']
        end
      end

      # A hash of alle the attributes with the response. Assuming there is only one value for each key
      def attributes
        @attributes ||= begin
          result = {}

          stmt_element = REXML::XPath.first(document, "//a:Assertion/a:AttributeStatement", { "a" => ASSERTION })
          return {} if stmt_element.nil?

          stmt_element.elements.each do |attr_element|
            name  = attr_element.attributes["AttributeName"]
            value = attr_element.elements.first.text

            result[name] = value
          end

          result
        end
      end

      private

      def fingerprint
        cert = OpenSSL::X509::Certificate.new(options[:certificate])
        Digest::SHA1.hexdigest(cert.to_der).upcase.scan(/../).join(":")
      end
    end
  end
end
