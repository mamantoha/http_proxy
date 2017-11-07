require "spec"
require "../src/http_proxy"

describe HTTP::Proxy do
  it "should have version" do
    (HTTP::Proxy::VERSION).should_not be_nil
  end
end
