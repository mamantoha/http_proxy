require "http"
require "socket"
require "base64"
{% if !flag?(:without_openssl) %}
  require "openssl"
{% end %}

require "./http/proxy/server"
require "./http/proxy/client"
