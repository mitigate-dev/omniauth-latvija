# The contents of this file are subject to the terms
# of the Common Development and Distribution License
# (the License). You may not use this file except in
# compliance with the License.
#
# You can obtain a copy of the License at
# https://opensso.dev.java.net/public/CDDLv1.0.html or
# opensso/legal/CDDLv1.0.txt
# See the License for the specific language governing
# permission and limitations under the License.
#
# When distributing Covered Code, include this CDDL
# Header Notice in each file and include the License file
# at opensso/legal/CDDLv1.0.txt.
# If applicable, add the following below the CDDL Header,
# with the fields enclosed by brackets [] replaced by
# your own identifying information:
# 'Portions Copyrighted [year] [name of copyright owner]'
#
# $Id: xml_sec.rb,v 1.6 2007/10/24 00:28:41 todddd Exp $
#
# Copyright 2007 Sun Microsystems Inc. All Rights Reserved
# Portions Copyrighted 2007 Todd W Saxton.

module OmniAuth::Strategies
  class Latvija
    class SignedDocument
      DSIG = 'http://www.w3.org/2000/09/xmldsig#'.freeze
      XENC = 'http://www.w3.org/2001/04/xmlenc#'.freeze
      CANON_MODE = Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0

      def initialize(response, **opts)
        @response = Nokogiri::XML.parse(response, &:noblanks)
        return unless encrypted?
        decryptor = OmniAuth::Strategies::Latvija::Decryptor.new(response, opts[:private_key])
        decrypted_response = decryptor.decrypt
        @response = Nokogiri::XML.parse(decrypted_response, &:noblanks)
      end

      def validate!(idp_cert_fingerprint)
        validate_fingerprint!(idp_cert_fingerprint)
        sig_element = @response.xpath('//xmlns:Signature', xmlns: DSIG)

        validate_digest!(sig_element)
        validate_signature!(sig_element)
        true
      end

      def nokogiri_xml
        @response
      end

      private

      def encrypted?
        @response.xpath('//xenc:EncryptedData', 'xmlns:xenc' => XENC).any?
      end

      def certificate
        @certificate ||= begin
          base64_cert = @response.xpath('//xmlns:X509Certificate', xmlns: DSIG).text
          cert_text   = Base64.decode64(base64_cert)
          OpenSSL::X509::Certificate.new(cert_text)
        end
      end

      def validate_fingerprint!(idp_cert_fingerprint)
        fingerprint = Digest::SHA256.hexdigest(certificate.to_der)
        if fingerprint != idp_cert_fingerprint.gsub(/[^a-zA-Z0-9]/, '').downcase
          raise ValidationError, 'Fingerprint mismatch'
        end
      end

      def validate_digest!(sig_element)
        response_without_signature = @response.dup
        response_without_signature.xpath('//xmlns:Signature', xmlns: DSIG).remove

        sig_element.xpath('.//xmlns:Reference', xmlns: DSIG).each do |ref|
          uri            = ref.attribute('URI').value
          hashed_element = response_without_signature.
            at_xpath("//*[@AssertionID='#{uri[1, uri.size]}']").
            canonicalize(CANON_MODE)
          hash           = Base64.encode64(Digest::SHA256.digest(hashed_element)).chomp
          digest_value   = ref.xpath('.//xmlns:DigestValue', xmlns: DSIG).text

          raise ValidationError, 'Digest mismatch' if hash != digest_value
        end
      end

      def validate_signature!(sig_element)
        signed_info_element = sig_element.
          at_xpath('.//xmlns:SignedInfo', xmlns: DSIG).
          canonicalize(CANON_MODE)
        base64_signature    = sig_element.xpath('.//xmlns:SignatureValue', xmlns: DSIG).text
        signature           = Base64.decode64(base64_signature)

        unless certificate.public_key.verify(OpenSSL::Digest::SHA256.new, signature, signed_info_element)
          raise ValidationError, 'Key validation error'
        end
      end
    end
  end
end
