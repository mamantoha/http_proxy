class HTTP::Server
  class Response
    def clear
      @upgraded = false
      @output = @original_output
      @original_output.reset
    end
  end
end
