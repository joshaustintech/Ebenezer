require "socket"
server = TCPServer.new("127.0.0.1", 47123)
t = Thread.new do
  2.times do
    c = server.accept
    req = c.gets
    while (l = c.gets) && l != "\r\n"; end
    body = "ok " + req.split(" ")[1].to_s
    c.write("HTTP/1.1 200 OK\r\nContent-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}")
    c.close
  end
end
sleep 0.2
2.times do |i|
  s = TCPSocket.new("127.0.0.1", 47123)
  s.write("GET /p#{i} HTTP/1.1\r\nHost: x\r\n\r\n")
  puts s.read.split("\r\n\r\n").last
  s.close
end
t.join
puts "mtime ok: #{File.mtime(__FILE__).to_i > 0}"
