require "./spec_helper"

describe HTTP::Proxy::Client do
  describe "#initialize" do
    it "with host and port" do
      client = HTTP::Proxy::Client.new("127.0.0.1", 8080)
      (client.host).should eq("127.0.0.1")
      (client.port).should eq(8080)
      (client.username).should eq(nil)
      (client.password).should eq(nil)
    end

    it "with username and password" do
      client = HTTP::Proxy::Client.new("127.0.0.1", 8080, username: "user", password: "password")
      (client.username).should eq("user")
      (client.password).should eq("password")
    end
  end
end
