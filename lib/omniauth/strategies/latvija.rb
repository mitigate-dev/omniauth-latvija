require 'time'
require 'openssl'
require 'digest/sha1'
require 'xmlenc'
require 'nokogiri'
require 'omniauth/strategies/latvija/response'
require 'omniauth/strategies/latvija/decryptor'
require 'omniauth/strategies/latvija/signed_document'

module OmniAuth::Strategies
  #
  # Authenticate with Latvija.lv.
  #
  # @example Basic Rails Usage
  #
  #  Add this to config/initializers/omniauth.rb
  #
  #    Rails.application.config.middleware.use OmniAuth::Builder do
  #      provider :latvija, {
  #        endpoint:    "https://epaktv.vraa.gov.lv/IVIS.LVP.STS/Default.aspx",
  #        certificate: File.read("/path/to/cert"),
  #        private:     File.read("/path/to/private_key"),
  #        realm:       "urn:federation:example.com"
  #      }
  #    end
  #
  class Latvija
    include OmniAuth::Strategy
    class ValidationError < StandardError; end

    option :realm, nil
    option :wfresh, false
    option :endpoint, nil
    option :certificate, nil
    option :private_key, nil

    def request_phase
      params = {
        wa: 'wsignin1.0',
        wct: Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ'),
        wtrealm: options[:realm],
        wreply: callback_url,
        wctx: callback_url,
        wreq: '<trust:RequestSecurityToken xmlns:trust="http://docs.oasis-open.org/ws-sx/ws-trust/200512"><trust:Claims xmlns:i="http://schemas.xmlsoap.org/ws/2005/05/identity" Dialect="http://schemas.xmlsoap.org/ws/2005/05/identity"><i:ClaimType Uri="http://docs.oasis-open.org/wsfed/authorization/200706/claims/action" Optional="false" /></trust:Claims><trust:RequestType>http://docs.oasis-open.org/ws-sx/ws-trust/200512/Issue</trust:RequestType></trust:RequestSecurityToken>'
      }
      params[:wfresh] = options[:wfresh] if options[:wfresh]
      query_string = params.collect { |key, value| "#{key}=#{Rack::Utils.escape(value)}" }.join('&')
      redirect "#{options[:endpoint]}?#{query_string}"
    end

    def callback_phase
      if request.params['wresult']
        @response = OmniAuth::Strategies::Latvija::Response.new(
          request.params['wresult'],
          certificate: options[:certificate],
          private_key: options[:private_key]
        )
        @response.validate!
        super
      else
        fail!(:invalid_response)
      end
    rescue Exception => e
      fail!(:invalid_response, e)
    end

    def auth_hash
      OmniAuth::Utils.deep_merge(super,
        uid: "#{@response.attributes['givenname']} #{@response.attributes['surname']}, #{@response.attributes["privatepersonalidentifier"]}",
        info: {
          name: "#{@response.attributes['givenname']} #{@response.attributes['surname']}",
          first_name: @response.attributes['givenname'],
          last_name: @response.attributes['surname'],
          private_personal_identifier: @response.attributes['privatepersonalidentifier']
        },
        authentication_method: @response.authentication_method,
        extra: {
          raw_info: @response.attributes
        }
      )
    end
  end
end
