# OmniAuth Latvija.lv

> **Autentifikācijas serviss.** Ar autentifikācijas servisa palīdzību iestādes var ērti savos pakalpojumu portālos vai reģistros autentificēt pakalpojuma lietotāju atbilstoši visiem drošības standartiem. Iestādei vairs nav nepieciešams veidot jaunus autentifikācijas mehānismus un juridiski slēgt vienošanos ar katru no autentifikācijas iespējas nodrošinātājiem. Šobrīd pieejamos autentifikācijas līdzekļus var apskatīties portālā [www.latvija.lv](http://www.latvija.lv/) sadaļā „E-pakalpojumi”.
>
> -- [VRAA E-pakalpojumi](http://www.vraa.gov.lv/lv/epakalpojumi/viss/)

Provides the following authentication types:

* E-paraksts
* Swedbank
* SEB banka
* Online bank
* Citadele
* Norvik banka
* PrivatBank
* eID
* Lattelecom Mobile ID

## Installation

```ruby
gem 'omniauth-latvija', '~> 2.0'
```

## Usage

`OmniAuth::Strategies::Latvija` is simply a Rack middleware. Read the OmniAuth 1.x docs for detailed instructions: https://github.com/intridea/omniauth.

Here's a quick example, adding the middleware to a Rails app in `config/initializers/omniauth.rb`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :latvija, {
    endpoint:    "https://epaktv.vraa.gov.lv/IVIS.LVP.STS/Default.aspx",
    certificate: File.read("/path/to/cert.pem"),
    private_key: File.read("/path/to/private_key.pem"), # mandatory, if the response is encrypted
    realm:       "urn:federation:example.com"
  }
end
```


## Auth Hash

Here's an example hash available in `request.env['omniauth.auth']`

```ruby
{
  provider: 'latvija',
  uid: 'JANIS BERZINS, 12345612345',
  info: {
    name: 'JANIS BERZINS',
    first_name: 'JANIS',
    last_name: 'BERZINS',
    private_personal_identifier: '12345612345'
  },
  extra: {
    raw_info: {
      name: 'JANIS BERZINS',
      first_name: 'JANIS',
      last_name: 'BERZINS',
      private_personal_identifier: '12345612345',
      not_valid_before: '2019-05-09T07:29:41Z',
      not_valid_on_or_after: '2019-05-09T08:29:41Z'
    },
    authentication_method: 'SWEDBANK'
  }
}
```

## References

* http://docs.oasis-open.org/wsfed/federation/v1.2/os/ws-federation-1.2-spec-os.html
* http://msdn.microsoft.com/en-us/library/bb498017.aspx
* http://msdn.microsoft.com/en-us/library/bb608217.aspx
* https://github.com/onelogin/ruby-saml
