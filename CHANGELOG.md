# Changelog

## 0.10.1

* Add `HTTP::Proxy::Client#write_timeout` ([#29](https://github.com/mamantoha/http_proxy/pull/29))
* Add specs for proxy client with auth ([#28](https://github.com/mamantoha/http_proxy/pull/28))

## 0.10.0

* Refactor `HTTP::Proxy::Client`
* Deprecate `HTTP::Client#set_proxy`. Use `HTTP::Client#proxy=` instead.
* Require Crystal >= 1.0.0

## 0.9.0

* Fix an issue with `HTTP::Request` ([#25](https://github.com/mamantoha/http_proxy/pull/25))

## 0.8.1

* Small refactoring
## 0.8.0

* Require Crystal >= 0.36.0

## 0.7.3

* Fixed compatibility with Crystal nightly

## 0.7.2

* Allow to set HTTP headers for proxy client ([#23](https://github.com/mamantoha/http_proxy/pull/23))

## 0.7.1

* Fixed compatibility with Crystal nightly

## 0.7.0

* **(breaking-change)** Sending full URL instead of path when using HTTP proxy is not required

## 0.6.0

* **(breaking-change)** Change `HTTP::Proxy::Server` implementation.
  `HTTP::Proxy::Server.new` not require `host` and `port` parameters

## 0.5.0

* Compatibility with Crystal 0.35.0

## 0.4.0

* Compatibility with Crystal 0.30

## 0.3.6

* Updates to Crystal 0.27
* Refactor Proxy Client

## 0.3.5

* Updates to Crystal 0.25

## 0.3.3

* Fixed an issue with HTTP resource when proxy server which initialized without handlers can't properly read a response

## 0.3.2

* Fix compatibility with Kemal

## 0.3.1

* minor bug fixes

## 0.3.0

* Detach the fork and turn it into a standalone repository on GitHub
* Change shard name to `http_proxy`
* Add proxy client
* Add project to Travis CI

## 0.2.1

* Bug fixes

## 0.2.0

* First release after fork
* Change shard name to `http_proxy_server`
* Update to Crystal 0.23.0
* New project structure
* Bug fixes and performance improvement
