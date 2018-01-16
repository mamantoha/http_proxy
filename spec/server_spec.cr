require "./spec_helper"

describe HTTP::Proxy::Server do
  describe "#initialize" do
    it "with params" do
      server = HTTP::Proxy::Server.new("localhost", 3128)
      (server.host).should eq("localhost")
      (server.port).should eq(3128)
    end

    it "with BasicAuth handler" do
      server = HTTP::Proxy::Server.new("localhost", 3128,
        [
          HTTP::Proxy::Server::BasicAuth.new("user", "passwd"),
        ]
      )
      (server.host).should eq("localhost")
      (server.port).should eq(3128)
    end
  end
end
