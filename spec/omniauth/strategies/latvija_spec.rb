require File.expand_path('../../../spec_helper', __FILE__)

describe OmniAuth::Strategies::Latvija, :type => :strategy do
  include OmniAuth::Test::StrategyTestCase

  let(:fixtures_valid_from_inclusive) { Time.parse '2017-10-17T14:56:04.831Z' }
  let(:fixtures_valid_to_not_inclusive) { Time.parse '2017-10-17T18:56:04.831Z' }
  let(:freeze_time_at) { fixtures_valid_from_inclusive }

  let(:certificate) { File.read('spec/fixtures/private/cert.pem') }
  let(:private_key) { File.read('spec/fixtures/private/key.pem') }
  let(:wresult_encrypted) { File.read('spec/fixtures/private/wresult_encrypted.xml') }
  let(:wresult_decrypted) { File.read('spec/fixtures/private/wresult_decrypted.xml') }

  def strategy
    [ OmniAuth::Strategies::Latvija,
      { certificate: certificate,
        endpoint: "https://epaktv.vraa.gov.lv/IVIS.LVP.STS/Default.aspx",
        realm: "urn:federation:example.com",
        private_key: private_key
      }
    ]
  end

  around do |example|
    Timecop.freeze(freeze_time_at) do
      example.run
    end
  end

  describe '/auth/latvija' do
    it 'should redirect to latvija.lv authentication screen' do
      get '/auth/latvija'
      last_response.should be_redirect
      # puts last_response.headers['Location'].inspect
      last_response.headers['Location'].should match %r{https://epaktv.vraa.gov.lv/IVIS.LVP.STS/Default.aspx\?wa=wsignin1.0&wct=([^&]+)&wtrealm=urn%3Afederation%3Aexample.com&wreply=http%3A%2F%2Fexample.org%2Fauth%2Flatvija%2Fcallback&wctx=http%3A%2F%2Fexample.org%2Fauth%2Flatvija%2Fcallback&wreq=%3Ctrust}
    end

    it 'should gather user data after successful authentication using Swedbank' do
      post '/auth/latvija/callback', {
        :wa => "wsignin1.0",
        :wctx => "http://example.org/auth/latvija/callback",
        :wresult => wresult_encrypted
      }

      # puts "omniauth.auth: #{last_request.env['omniauth.auth'].inspect}"
      # puts "omniauth.error: #{last_request.env['omniauth.error'].inspect}"
      # puts "omniauth.error.type: #{last_request.env['omniauth.error.type'].inspect}"
      # puts "omniauth.strategy: #{last_request.env['omniauth.strategy'].inspect}"

      last_request.env['omniauth.error'].should be_nil
      last_request.env['omniauth.auth']['uid'].should be_present
      last_request.env['omniauth.auth']['extra']['raw_info']['givenname'].should be_present
      last_request.env['omniauth.auth']['extra']['raw_info']['surname'].should be_present
      last_request.env['omniauth.auth']['info']['first_name'].should be_present
      last_request.env['omniauth.auth']['info']['last_name'].should be_present
      last_request.env['omniauth.auth']['info']['private_personal_identifier'].should be_present
    end

    it 'should fail after unsuccessful authentication with fingerprint mismatch' do
      invalid_certificate = <<-EOS
        -----BEGIN CERTIFICATE-----
        MIICNDCCAaECEAKtZn5ORf5eV288mBle3cAwDQYJKoZIhvcNAQECBQAwXzELMAkG
        A1UEBhMCVVMxIDAeBgNVBAoTF1JTQSBEYXRhIFNlY3VyaXR5LCBJbmMuMS4wLAYD
        VQQLEyVTZWN1cmUgU2VydmVyIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MB4XDTk0
        MTEwOTAwMDAwMFoXDTEwMDEwNzIzNTk1OVowXzELMAkGA1UEBhMCVVMxIDAeBgNV
        BAoTF1JTQSBEYXRhIFNlY3VyaXR5LCBJbmMuMS4wLAYDVQQLEyVTZWN1cmUgU2Vy
        dmVyIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MIGbMA0GCSqGSIb3DQEBAQUAA4GJ
        ADCBhQJ+AJLOesGugz5aqomDV6wlAXYMra6OLDfO6zV4ZFQD5YRAUcm/jwjiioII
        0haGN1XpsSECrXZogZoFokvJSyVmIlZsiAeP94FZbYQHZXATcXY+m3dM41CJVphI
        uR2nKRoTLkoRWZweFdVJVCxzOmmCsZc5nG1wZ0jl3S3WyB57AgMBAAEwDQYJKoZI
        hvcNAQECBQADfgBl3X7hsuyw4jrg7HFGmhkRuNPHoLQDQCYCPgmc4RKz0Vr2N6W3
        YQO2WxZpO8ZECAyIUwxrl0nHPjXcbLm7qt9cuzovk2C2qUtN8iD3zV9/ZHuO3ABc
        1/p3yjkWWW8O6tO1g39NTUJWdrTJXwT4OPjr0l91X817/OWOgHz8UA==
        -----END CERTIFICATE-----
      EOS

      post '/auth/latvija/callback', {
        :wa => "wsignin1.0",
        :wctx => "http://example.org/auth/latvija/callback",
        :wresult => wresult_decrypted.sub(
          certificate.sub("-----BEGIN CERTIFICATE-----", "").sub("-----END CERTIFICATE-----", "").gsub("\n", ""),
          invalid_certificate.sub("-----BEGIN CERTIFICATE-----", "").sub("-----END CERTIFICATE-----", "").gsub("\n", "")
        )
      }

      last_request.env['omniauth.error'].message.should == "Fingerprint mismatch"
    end

    it 'should fail after unsuccessful authentication when signature digest is invalid' do
      post '/auth/latvija/callback', {
        :wa => "wsignin1.0",
        :wctx => "http://example.org/auth/latvija/callback",
        :wresult => wresult_decrypted.sub(
          /<DigestValue>[^<]+<\/DigestValue>/,
          '<DigestValue>0FA</DigestValue>'
        )
      }

      last_request.env['omniauth.error'].message.should == "Digest mismatch"
      last_request.env['omniauth.auth'].should be_nil
    end

    it 'should fail after unsuccessful authentication when signature key is invalid' do
      post '/auth/latvija/callback', {
        :wa => "wsignin1.0",
        :wctx => "http://example.org/auth/latvija/callback",
        :wresult => wresult_decrypted.sub(
          /<SignatureValue>[^<]+<\/SignatureValue>/,
          '<SignatureValue>0FA</SignatureValue>'
        )
      }

      last_request.env['omniauth.error'].message.should == "Key validation error"
      last_request.env['omniauth.auth'].should be_nil
    end

    it 'should fail after unsuccessful authentication when wresult is empty' do
      post '/auth/latvija/callback', {
        :wa => "wsignin1.0",
        :wctx => "http://example.org/auth/latvija/callback"
      }

      last_request.env['omniauth.error.type'].should == :invalid_response
      last_request.env['omniauth.auth'].should be_nil
    end

    context 'timestamp validation' do
      context 'when response is still valid' do
        let(:freeze_time_at) { fixtures_valid_to_not_inclusive - 1.second }

        it 'should not fail' do
          post '/auth/latvija/callback', {
            :wa => "wsignin1.0",
            :wctx => "http://example.org/auth/latvija/callback",
            :wresult => wresult_decrypted
          }

          last_request.env['omniauth.error'].should be_nil
          last_request.env['omniauth.auth'].should be_present
          last_request.env['omniauth.auth']['extra']['raw_info']['not_valid_before'].should be_present
          last_request.env['omniauth.auth']['extra']['raw_info']['not_valid_on_or_after'].should be_present
        end
      end

      context 'when response is no longer valid' do
        let(:freeze_time_at) { fixtures_valid_to_not_inclusive }

        it 'should fail' do
          post '/auth/latvija/callback', {
            :wa => "wsignin1.0",
            :wctx => "http://example.org/auth/latvija/callback",
            :wresult => wresult_decrypted
          }

          last_request.env['omniauth.error'].message.should == 'Current time is on or after NotOnOrAfter condition'
          last_request.env['omniauth.auth'].should be_nil
        end
      end
    end

    context 'specific properties' do
      let(:wresult_decrypted) { File.read('spec/fixtures/wresult_multi_personal_codes_decrypted.xml') }

      before(:each) do
        allow_any_instance_of(OmniAuth::Strategies::Latvija::SignedDocument).to receive(:validate!).and_return(true)
      end

      let(:response) do
        post '/auth/latvija/callback', {
          :wa => "wsignin1.0",
          :wctx => "http://example.org/auth/latvija/callback",
          :wresult => wresult_decrypted
        }

        last_request.env['omniauth.auth'].tap { |x| pp x }
      end

      it 'should return first name' do
        expect(response.dig('info', 'first_name')).to eq('ODS')
      end

      it 'should return last name' do
        expect(response.dig('info', 'last_name')).to eq('KNISLIS')
      end

      it 'should return combined name' do
        expect(response.dig('info', 'name')).to eq('ODS KNISLIS')
      end

      it 'should return primary personal code, as specified by OriginalIssuer param' do
        expect(response.dig('info', 'private_personal_identifier')).to eq('32345678901')
      end

      it 'should return any historical personal codes in extra info' do
        expect(response.dig('extra', 'raw_info', 'historical_privatepersonalidentifier')).to match_array(['12345678901'])
      end
    end
  end
end
