#!$MY_RUBY_HOME/ruby
require 'yaml' # Built in, no gem required


def preParseResponse(response,values_old=nil)
	values = JSON.parse(response.body)
	if values['ERROR'] == 'No game'
		print "Connected. Waiting for a game to start...\r"
		$stdout.flush # clear the line
		sleep 2
		return 1

	end
	if values['error'] == 'No ship'
		if(values_old['initial'])
			print "No ship yet. Waiting for it to be spawned...\r"
		else
			$signalLight.send(:off)
			$strobeLight.send(:off)
			$smokeSwitch.send(:off)
			$portD.send(:off)
			print "Ship not found anymore. Ejected?!\r"
		end
		$stdout.flush # clear the line
		sleep 1
		return 2
	end
	if values["hull"]
		return 3
	end
end



def port_open?(ip, port, seconds=1)
  Timeout::timeout(seconds) do
    begin
      TCPSocket.new(ip, port).close
      puts "#{ip} #{port} open"
      true
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH,Errno::ENETUNREACH
      # puts "#{ip} #{port} closed"
      false
    end
  end
  rescue Timeout::Error
  false
end

def is_valid_server?(ip)
	if(port_open? ip, $settings[:protonServerPort],0.05) 
		if(port_open? ip, $settings[:httpServerPort],0.1) 
			server_ip = ip
			return server_ip
		end
	end
end

def scan_for_server(start_ip=nil)
	local_ip = IPSocket.getaddress(Socket.gethostname)
	start_ip ||= local_ip
	puts "Scanning subnet of #{start_ip}"
	subnet = "#{start_ip.split('.')[0]}.#{start_ip.split('.')[1]}.#{start_ip.split('.')[2]}."

	start_ip = 1
	end_ip = 254
	until start_ip == end_ip do
		return "#{subnet}#{start_ip.to_s}" if(is_valid_server? "#{subnet}#{start_ip.to_s}")
	    start_ip += 1
	end
end

def ask_for_ip()
	puts "Type the server IP or press enter for localhost:"
	begin
	Timeout::timeout(5) do
		apiServer = gets.chomp
	end
	rescue Timeout::Error
		puts "No input recieved. Trying something..."
	end
	apiServer = '127.0.0.1' if apiServer.nil? or apiServer.empty?
	apiServer
end

def scan_server_loop()
	server_ip = nil
	puts "Scanning for server..."
	while server_ip == nil do
		server_ip ||= is_valid_server?($settings['last_server'])
		$settings['scan_ranges'].each { |range| server_ip ||= scan_for_server(range)}
		server_ip ||= scan_for_server()
		server_ip ||= scan_for_server(ask_for_ip())
		local_ip = Socket::getaddrinfo(Socket.gethostname,"echo",Socket::AF_INET)[0][3]
		server_ip ||= scan_for_server(local_ip)
		puts "Server IP: #{server_ip}"	
	end
	server_ip
end

def store_settings(settings)
	File.open('./settings.yml', 'w') {|f| f.write settings.to_yaml } #Store
end

def load_settings()
	YAML::load_file('./settings.yml') #Load
end

def luaPost(url,code)
	options = { body: code }
	begin
		response = HTTParty.post(url,options)
	rescue
		print "HTTP post unsuccesful. Retrying...\r"
		$stdout.flush # clear the line
		sleep 0.2
		retry
	end
	return response
end

def init_duino()
	puts "Connecting to Arduino board"
	begin
		board = Dino::Board.new(Dino::TxRx.new)
	rescue Dino::BoardNotFound
		print "."
		sleep 0.2
		retry
	end
	puts ". Arduino connected!"
	$signalLight = Dino::Components::Led.new(pin: $settings[:arduinoPins][:signal], board: board)
	$strobeLight = Dino::Components::Led.new(pin: $settings[:arduinoPins][:strobe], board: board)
	$smokeSwitch = Dino::Components::Led.new(pin: $settings[:arduinoPins][:smoke], board: board)
	$button = Dino::Components::Button.new(pin: $settings[:arduinoPins][:button], board: board)
	$portD = Dino::Components::Led.new(pin: $settings[:arduinoPins][:portD], board: board)
	$button.down do
	  puts "button down"
	end

	$button.up do
	  puts "button up"
	end

	return board
end



def sendToPort(port,state)
	begin
		port.send(state)
	rescue Errno::ENXIO
		# sleep 1
		puts "Waiting for Arduino."
		$board = init_duino()
		# retry
	end
end

def enableForSeconds(port,seconds)
	sendToPort(port,:on)
	sleep seconds
	sendToPort(port,:off)
end
