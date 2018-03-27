require "http"
require "socket"
require "base64"

require "./http/proxy/server"
require "./http/proxy/client"

module HTTP
  module Proxy
    VERSION = "0.3.2"
  end
end