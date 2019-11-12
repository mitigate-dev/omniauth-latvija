## Unreleased

- **BREAKING CHANGE**: use the identifier returned by latvija.lv as auth UID, to prevent surname changes resetting user identity. Without changes in caller code, existing users will not be able to log in. Previously used versions of UID can be found under `extra.legacy_uids` key in auth response.
- Return correct personal identifier in cases when person has had it changed. Historical identifiers, if any, can be found under `extra.raw_info.historical_privatepersonalidentifier` key in auth response.

## 4.0.0

- Check authentication expirity #6

## 3.0.0

- Normalize omniauth attribute names #5

## 2.0.0

- Support for encrypted responses #4
- Switch XML parsing and canonicalization to Nokogiri #4
- Switch to ruby 2.1 Syntax (removed support for Ruby <2.0) #4

## 1.1.1

- Added 'wfresh' parameter support in request phase #2

## 1.1.0

- Pass back authentication_method #1

## 1.0.0

- Initial version
