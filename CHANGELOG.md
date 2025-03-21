# Changelog

## 0.13.0

* **(breaking-change)** Require Crystal >= 1.14.0
* Use `WaitGroup` instead of a `Channel(Nil)` in server implementation ([39](https://github.com/mamantoha/http_proxy/pull/39))

## 0.12.1

* Add the tag "network" to specs that require real network access ([92ec7c7](https://github.com/mamantoha/http_proxy/commit/92ec7c77c0aa334cb798b69be4c64958ac0e02a5))

## 0.12.0

* **(breaking-change)** Rename `HTTP::Proxy::Server::BasicAuth` to `HTTP::Proxy::Server::BasicAuthHandler` ([#37](https://github.com/mamantoha/http_proxy/pull/37))
* Add Windows to CI ([#36](https://github.com/mamantoha/http_proxy/pull/36))

## 0.11.0

* Make `HTTP::Proxy::Server` independent ([#35](https://github.com/mamantoha/http_proxy/pull/35))
* Remove deprecated method `HTTP::Proxy::Client#set_proxy` ([#35](https://github.com/mamantoha/http_proxy/pull/35))

## 0.10.3

* remove `*_timeout` ivars from `HTTP::Proxy::Client` ([#33](https://github.com/mamantoha/http_proxy/pull/33))

## 0.10.2

* Support Crystal >= 1.12.0 ([#32](https://github.com/mamantoha/http_proxy/pull/32))

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
