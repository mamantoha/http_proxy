require "./spec_helper"

describe HTTP::Proxy::Server do
  describe "#initialize" do
    it "without params" do
      server = HTTP::Proxy::Server.new
      (server.host).should eq("127.0.0.1")
      (server.port).should eq(8080)
    end

    it "with params" do
      server = HTTP::Proxy::Server.new("localhost", 3128)
      (server.host).should eq("localhost")
      (server.port).should eq(3128)
    end
  end
end
