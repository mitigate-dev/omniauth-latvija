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

      attr_accessor :signed_element_id

      def initialize(response, **opts)
        @response = Nokogiri::XML(response)
        if encrypted?
          decryptor = OmniAuth::Strategies::Latvija::Decryptor.new(response, opts[:private_key])
          decrypted_response = decryptor.decrypt
          @response = Nokogiri::XML(decrypted_response)
        end

        extract_signed_element_id
      end

      def validate!(idp_cert_fingerprint)
        # get cert from response
        base64_cert = @response.xpath('//xmlns:X509Certificate', xmlns: DSIG).text
        cert_text   = Base64.decode64(base64_cert)
        cert        = OpenSSL::X509::Certificate.new(cert_text)

        # check cert matches registered idp cert
        fingerprint = Digest::SHA1.hexdigest(cert.to_der)
        raise ValidationError, 'Fingerprint mismatch' if fingerprint != idp_cert_fingerprint.gsub(/[^a-zA-Z0-9]/, '').downcase

        # remove signature node
        sig_element = @response.xpath('//xmlns:Signature', xmlns: DSIG)
        sig_element.remove

        # check digests
        sig_element.xpath('.//xmlns:Reference', xmlns: DSIG).each do |ref|
          uri            = ref.attribute('URI').value
          hashed_element = @response.xpath("//*[@AssertionID='#{uri[1, uri.size]}']").canonicalize
          hash           = Base64.encode64(Digest::SHA1.digest(hashed_element)).chomp
          digest_value   = ref.xpath('.//xmlns:DigestValue', xmlns: DSIG).text

          raise ValidationError, 'Digest mismatch' if hash != digest_value
        end

        # verify signature
        signed_info_element = Nokogiri::XML(sig_element.xpath('.//xmlns:SignedInfo', xmlns: DSIG).to_s).canonicalize
        base64_signature    = sig_element.xpath('.//xmlns:SignatureValue', xmlns: DSIG).text
        signature           = Base64.decode64(base64_signature)

        unless cert.public_key.verify(OpenSSL::Digest::SHA1.new, signature, signed_info_element)
          raise ValidationError, 'Key validation error'
        end

        true
      end

      def extract_signed_element_id
        reference_element       = @response.xpath('//ds:Signature/ds:SignedInfo/ds:Reference', 'ds' => DSIG)
        self.signed_element_id  = reference_element.attribute('URI').value unless reference_element.nil?
      end

      def encrypted?
        @response.xpath('//xenc:EncryptedData', 'xmlns:xenc' => XENC).any?
      end
    end
  end
end
