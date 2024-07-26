require "./spec_helper"

describe HTTP::Proxy::Server do
  describe "#initialize" do
    it "with params" do
      server = HTTP::Proxy::Server.new
      server.should be_a(HTTP::Proxy::Server)
    end

    it "with BasicAuthHandler handler" do
      server = HTTP::Proxy::Server.new([
        HTTP::Proxy::Server::BasicAuthHandler.new("user", "passwd"),
      ])
      server.should be_a(HTTP::Proxy::Server)
    end
  end
end
