require './boot'
#inilize users for example
$redis_pool.with do |redis|
  #redis.hset "users_ids", "1", {"em_obj_id" => nil, "user_list_ids" => [2], "channel_list_ids" => []}.to_json
  #redis.hset "users_ids", "2", {"em_obj_id" => nil, "user_list_ids" => [1], "channel_list_ids" => []}.to_json
  redis.hset "users_ids", "1", {"em_obj_id"                => nil, 
                                "user_list_ids"            => [2, 3], 
                                "speaking_with_user_ids"      => [2, 3],
                                "who_is_called"            => "1",
                                }.to_json

  redis.hset "users_ids", "2", {"em_obj_id"                => nil, 
                                "user_list_ids"            => [1, 3], 
                                "speaking_with_user_ids"      => [1, 3],
                                "who_is_called"            => "1",
                                }.to_json
                                
  redis.hset "users_ids", "3", {"em_obj_id"                => nil, 
                                "user_list_ids"            => [1, 2],
                                "speaking_with_user_ids"      => [1, 2],
                                "who_is_called"            => "1", 
                                }.to_json
end


class Channel
  def initialize

  end

end

EM.run {
  @ws_object = {}#{user_id => ws_object}
  @users = {}#{ws.object_id => user_id, ...}
  #@users_ids = { "1" => {"em_obj_id" => nil, ...}, "2" => {"em_obj_id" => nil, ...} }

  EM::WebSocket.run(:host => "0.0.0.0", :port => 8081) do |ws|
    ws.onopen { |handshake|
      puts "WebSocket connection open"
      params = CGI.parse(handshake.query_string)
      user_id = params["user_id"][0]

      

      $redis_pool.with do |redis|
        user_ids = redis.hget "users_ids", user_id
        unless user_ids.nil?          
          begin  
            ### delete ?
              user_ids_json = JSON.parse(user_ids)
              user_ids_json["em_obj_id"] = ws.object_id
              redis.hset "users_ids", user_id, user_ids_json.to_json
            ###

            @users[ ws.object_id ] = user_id #save object_id for find user for this connection
            @ws_object[user_id] = ws
          rescue Exception => e
          
          end
        else
          ws.close(4000)
        end
      end
      
      
      # Access properties on the EM::WebSocket::Handshake object, e.g.
      # path, query_string, origin, headers

      # Publish message to the client
      #ws.send "Hello Client, you connected to #{handshake.path}"
      #ws.send ({candidate: ""}.to_json)
      #CGI.parse(handshake.query_string)["user_id"][0]
      unless ws.state == :closing
        ws.send "{}"
      end
    }

    ws.onclose { puts "Connection closed" 
      $redis_pool.with do |redis|
        current_user_id = @users[ ws.object_id ]
        unless current_user_id.nil?      
          current_user_settings = redis.hget "users_ids", current_user_id    
          begin  
            ###delete ?
              current_user_settings_json = JSON.parse(current_user_settings)
              current_user_settings_json["em_obj_id"] = nil
              redis.hset "users_ids", current_user_id, current_user_settings_json.to_json
            ###
            @ws_object.delete(current_user_id) #{user_id => ws_object}
            @users.delete(ws.object_id)        #{ws.object_id => user_id, ...}
          rescue Exception => e
          
          end
        
        end
      end

    }

    ws.onmessage { |msg|
      
      
      msg_split            = msg.split('_split_')
      msg_signal_inf       = msg_split[0]
      msg_from_user        = msg_split[1]
      msg_from_user        = JSON.parse(msg_from_user || "{}")

      puts "Recieved message: #{msg_signal_inf}"
      #msg_signal_inf_hash = JSON.parse(msg_signal_inf)
      #msg_signal_inf_hash

      current_user_id = @users[ ws.object_id ]
      current_user = "{}"
      unless current_user_id.nil?      
        $redis_pool.with do |redis|
          current_user = redis.hget "users_ids", current_user_id #select information obout user {"em_obj_id" => nil, "user_list_ids" => [2], "channel_list_ids" => []}
        end
      end

      begin  
        current_user_settings = JSON.parse(current_user)
        current_user_settings["user_list_ids"].each do |subscriber_id|
          @ws_object["#{subscriber_id}"].send msg_signal_inf
        end
      rescue Exception => e
          
      end
        
     
      #ws.send "ws: #{ws}"
    }
  end
}