require File.expand_path('../../../spec_helper', __FILE__)

describe OmniAuth::Strategies::Latvija, :type => :strategy do
  include OmniAuth::Test::StrategyTestCase

  def strategy
    [ OmniAuth::Strategies::Latvija,
      { certificate: certificate,
        endpoint: "https://epaktv.vraa.gov.lv/IVIS.LVP.STS/Default.aspx",
        realm: "urn:federation:example.com",
        private_key: private_key
      }
    ]
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
      last_request.env['omniauth.auth']['info']['first_name'].should be_present
      last_request.env['omniauth.auth']['info']['last_name'].should be_present
      last_request.env['omniauth.auth']['info']['private_personal_identifier'].should be_present
    end

    it 'should fail after unsuccessful authentication with fingerprint mismatch' do
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
  end

  private

  def invalid_certificate
    <<-EOS
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
  end

  def certificate
    File.read('spec/fixtures/cert.pem')
  end

  def private_key
    File.read('spec/fixtures/key.pem')
  end

  def wresult_encrypted
    File.read('spec/fixtures/wresult_encrypted.xml')
  end

  def wresult_decrypted
    File.read('spec/fixtures/wresult_decrypted.xml')
  end
end
