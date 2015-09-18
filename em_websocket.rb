require './boot'

$redis_pool.with do |redis|

end


class Channel
  def initialize

  end

end

EM.run {
  @clients = {}

  EM::WebSocket.run(:host => "0.0.0.0", :port => 8081) do |ws|
    ws.onopen { |handshake|
      puts "WebSocket connection open"
      @clients[ws.object_id] = ws
      # Access properties on the EM::WebSocket::Handshake object, e.g.
      # path, query_string, origin, headers

      # Publish message to the client
      #ws.send "Hello Client, you connected to #{handshake.path}"
      #ws.send ({candidate: ""}.to_json)
      ws.send "{}"
    }

    ws.onclose { puts "Connection closed" }

    ws.onmessage { |msg|
      puts "Recieved message: #{msg}"

      @clients.each do |object_id, socket|
        if object_id != ws.object_id
          socket.send  msg
        end
        #socket.send  msg
      end
      #ws.send "ws: #{ws}"
    }
  end
}