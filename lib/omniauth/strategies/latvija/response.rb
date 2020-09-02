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

      def validate!
        @document.validate!(fingerprint) && validate_conditions!
      end

      def xml
        @document.nokogiri_xml
      end

      def authentication_method
        @authentication_method ||= begin
          xml.xpath('//saml:AuthenticationStatement', saml: ASSERTION).attribute('AuthenticationMethod')
        end
      end

      def name_identifier
        @name_identifier ||= begin
          xml.xpath('//saml:AuthenticationStatement/saml:Subject/saml:NameIdentifier', saml: ASSERTION).text()
        end
      end

      # A hash of all the attributes with the response.
      # Assuming there is only one value for each key
      def attributes
        @attributes ||= begin
          attrs = {
            'not_valid_before' => not_valid_before,
            'not_valid_on_or_after' => not_valid_on_or_after,
            'historical_privatepersonalidentifier' => []
          }

          stmt_elements = xml.xpath('//saml:Attribute', saml: ASSERTION)

          return attrs if stmt_elements.nil?

          identifiers = stmt_elements.xpath("//saml:Attribute[@AttributeName='privatepersonalidentifier']", saml: ASSERTION)

          stmt_elements.each_with_object(attrs) do |element, result|
            name = element.attribute('AttributeName').value
            value = element.text

            case name
            when 'privatepersonalidentifier' # person can change their identifier, service will return all the versions
              if identifiers.length == 1 || element.attribute('OriginalIssuer') # this is the primary identifier, as returned by third party auth service
                result[name] = value
              else
                result['historical_privatepersonalidentifier'] << value
              end
            else
              result[name] = value
            end
          end
        end
      end

      private

      def fingerprint
        cert = OpenSSL::X509::Certificate.new(options[:certificate])
        Digest::SHA256.hexdigest(cert.to_der).upcase.scan(/../).join(':')
      end

      def conditions_tag
        @conditions_tag ||= xml.xpath('//saml:Conditions', saml: ASSERTION)
      end

      def not_valid_before
        @not_valid_before ||= conditions_tag.attribute('NotBefore').value
      end

      def not_valid_on_or_after
        @not_valid_on_or_after ||= conditions_tag.attribute('NotOnOrAfter').value
      end

      def validate_conditions!
        if not_valid_on_or_after.present? && Time.current < Time.parse(not_valid_on_or_after)
          true
        else
          raise ValidationError, 'Current time is on or after NotOnOrAfter condition'
        end
      end
    end
  end
end
