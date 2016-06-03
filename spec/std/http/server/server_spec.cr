require "spec"
require "http/server"

module HTTP
  class Server
    class ReverseResponseOutput
      include IO

      @output : IO

      def initialize(@output : IO)
      end

      def write(slice : Slice(UInt8))
        slice.reverse_each do |byte|
          @output.write_byte(byte)
        end
      end

      def read(slice : Slice(UInt8))
        raise "Not implemented"
      end

      def close
        @output.close
      end

      def flush
        @output.flush
      end
    end

    describe Response do
      it "closes" do
        io = MemoryIO.new
        response = Response.new(io)
        response.close
        io.to_s.should eq("HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n")
      end

      it "prints less then buffer's size" do
        io = MemoryIO.new
        response = Response.new(io)
        response.print("Hello")
        response.close
        io.to_s.should eq("HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nHello")
      end

      it "prints less then buffer's size to output" do
        io = MemoryIO.new
        response = Response.new(io)
        response.output.print("Hello")
        response.output.close
        io.to_s.should eq("HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nHello")
      end

      it "prints more then buffer's size" do
        io = MemoryIO.new
        response = Response.new(io)
        str = "1234567890"
        1000.times do
          response.print(str)
        end
        response.close
        first_chunk = str * 819
        second_chunk = str * 181
        io.to_s.should eq("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n1ffe\r\n#{first_chunk}\r\n712\r\n#{second_chunk}\r\n0\r\n\r\n")
      end

      it "prints with content length" do
        io = MemoryIO.new
        response = Response.new(io)
        response.headers["Content-Length"] = "10"
        response.print("1234")
        response.print("567890")
        response.close
        io.to_s.should eq("HTTP/1.1 200 OK\r\nContent-Length: 10\r\n\r\n1234567890")
      end

      it "prints with content length (method)" do
        io = MemoryIO.new
        response = Response.new(io)
        response.content_length = 10
        response.print("1234")
        response.print("567890")
        response.close
        io.to_s.should eq("HTTP/1.1 200 OK\r\nContent-Length: 10\r\n\r\n1234567890")
      end

      it "adds header" do
        io = MemoryIO.new
        response = Response.new(io)
        response.headers["Content-Type"] = "text/plain"
        response.print("Hello")
        response.close
        io.to_s.should eq("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 5\r\n\r\nHello")
      end

      it "sets content type" do
        io = MemoryIO.new
        response = Response.new(io)
        response.content_type = "text/plain"
        response.print("Hello")
        response.close
        io.to_s.should eq("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 5\r\n\r\nHello")
      end

      it "changes status and others" do
        io = MemoryIO.new
        response = Response.new(io)
        response.status_code = 404
        response.version = "HTTP/1.0"
        response.close
        io.to_s.should eq("HTTP/1.0 404 Not Found\r\nContent-Length: 0\r\n\r\n")
      end

      it "flushes" do
        io = MemoryIO.new
        response = Response.new(io)
        response.print("Hello")
        response.flush
        io.to_s.should eq("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n5\r\nHello\r\n")
        response.close
        io.to_s.should eq("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n5\r\nHello\r\n0\r\n\r\n")
      end

      it "wraps output" do
        io = MemoryIO.new
        response = Response.new(io)
        response.output = ReverseResponseOutput.new(response.output)
        response.print("1234")
        response.close
        io.to_s.should eq("HTTP/1.1 200 OK\r\nContent-Length: 4\r\n\r\n4321")
      end

      it "writes and flushes with HTTP 1.0" do
        io = MemoryIO.new
        response = Response.new(io, "HTTP/1.0")
        response.print("1234")
        response.flush
        io.to_s.should eq("HTTP/1.0 200 OK\r\n\r\n1234")
      end

      it "resets and clears headers and cookies" do
        io = MemoryIO.new
        response = Response.new(io)
        response.headers["Foo"] = "Bar"
        response.cookies["Bar"] = "Foo"
        response.reset
        response.headers.empty?.should be_true
        response.cookies.empty?.should be_true
      end

      it "writes cookie headers" do
        io = MemoryIO.new
        response = Response.new(io)
        response.cookies["Bar"] = "Foo"
        response.close
        io.to_s.should eq("HTTP/1.1 200 OK\r\nContent-Length: 0\r\nSet-Cookie: Bar=Foo; path=/\r\n\r\n")

        io = MemoryIO.new
        response = Response.new(io)
        response.cookies["Bar"] = "Foo"
        response.print("Hello")
        response.close
        io.to_s.should eq("HTTP/1.1 200 OK\r\nContent-Length: 5\r\nSet-Cookie: Bar=Foo; path=/\r\n\r\nHello")
      end

      it "responds with an error" do
        io = MemoryIO.new
        response = Response.new(io)
        response.content_type = "text/html"
        response.respond_with_error
        io.to_s.should eq("HTTP/1.1 500 Internal Server Error\r\nContent-Type: text/plain\r\nTransfer-Encoding: chunked\r\n\r\n1a\r\n500 Internal Server Error\n\r\n")

        io = MemoryIO.new
        response = Response.new(io)
        response.respond_with_error("Bad Request", 400)
        io.to_s.should eq("HTTP/1.1 400 Bad Request\r\nContent-Type: text/plain\r\nTransfer-Encoding: chunked\r\n\r\n10\r\n400 Bad Request\n\r\n")
      end
    end
  end

  describe HTTP::Server do
    it "re-sets special port zero after bind" do
      server = Server.new(0) { |ctx| }
      server.bind
      server.port.should_not eq(0)
    end

    it "re-sets port to zero after close" do
      server = Server.new(0) { |ctx| }
      server.bind
      server.close
      server.port.should eq(0)
    end

    it "doesn't raise on accept after close #2692" do
      server = Server.new("0.0.0.0", 0) { }

      spawn do
        server.close
        sleep 0.001
      end

      server.listen
    end
  end

  typeof(begin
    # Initialize with custom host
    server = Server.new("0.0.0.0", 0) { |ctx| }
    server.listen
    server.close

    server = Server.new("0.0.0.0", 0, [
      ErrorHandler.new,
      LogHandler.new,
      DeflateHandler.new,
      StaticFileHandler.new("."),
    ]
    )
    server.listen
    server.close

    server = Server.new("0.0.0.0", 0, [StaticFileHandler.new(".")]) { |ctx| }
    server.listen
    server.close

    # Initialize with default host
    server = Server.new(0) { |ctx| }
    server.listen
    server.close

    server = Server.new(0, [
      ErrorHandler.new,
      LogHandler.new,
      DeflateHandler.new,
      StaticFileHandler.new("."),
    ]
    )
    server.listen
    server.close

    server = Server.new(0, [StaticFileHandler.new(".")]) { |ctx| }
    server.listen
    server.close
  end)
end
