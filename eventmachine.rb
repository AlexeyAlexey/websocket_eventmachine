require './boot'

module SignalingServer #< EventMachine::Connection
  def post_init
    puts "Connection with server"
  end

  def receive_data data
    send_data ">> #{data}"

    close_connection if data =~ /quit/i
  end

  def unbind
    puts "Connection closed"
  end
end


EventMachine::run{
  EventMachine::start_server '', 8081, SignalingServer
}