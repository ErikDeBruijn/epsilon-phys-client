# For info about dino: http://tutorials.jumpstartlab.com/projects/arduino/introducing_arduino.html
#
# Installation:
#
# gem install dino httparty
# dino generate-sketch serial
# cd du
# ino build -m mega2560
# ino upload -m mega2560
# 
# For testing, to run a fake server: 
# ruby fake_server.rb

# For HTTP script access to the EmptyEpsilon server:
require 'httparty'
# For arduino connection
require 'dino'
require 'json'
# For scanning for a SeriousProton server:
require 'socket'
require 'timeout'


require_relative 'phy-lib'

puts "===== Physical client ====="
$settings = Hash.new
$settings = load_settings()

$board = init_duino()
$portD.send(:on)

server_ip = scan_server_loop()

apiServer = "#{server_ip}:#{$settings[:httpServerPort]}"

$settings['last_server'] = server_ip
store_settings($settings);

values_old = { "shieldsUp" => false,"hull" => 0, "initial" => true }
jumpInitiated = false
i=0
while true
	i+=1
	sleep (1.0/$settings[:requestsPerSecond]).to_f
	response = luaPost("http://#{apiServer}#{$settings['apiEndpoint']}",$settings[:pollCode])
	if (response.success?)
		values = JSON.parse(response.body)
		responseState = preParseResponse(response,values_old)
		next unless responseState == 3
		print "Raw response: #{response.body}\r"
		$stdout.flush # clear the line
		hullPercentage = 100.0 * values["hull"].to_i / values["hullMax"].to_i
		if (values["shieldsUp"].to_s != values_old["shieldsUp"].to_s)
			puts "Shields changed from " + values_old["shieldsUp"].to_s + " to " + values["shieldsUp"].to_s + "..."
			sendToPort($signalLight,:on) if values["shieldsUp"] == true
			sendToPort($signalLight,:off) if values["shieldsUp"] == false
		end
		if (values["hull"].to_i < values_old["hull"].to_i)
			puts "Damage... (hull at #{hullPercentage.to_i}%)"
			enableForSeconds($strobeLight,0.4)
		end
		shields = values["shieldsPercentage"].to_i;
		# puts "Raw response: #{response.body}" if(i%10==0)
		# puts "        (shields at #{values['shieldsPercentage']}%, hull at #{hullPercentage}%)"
		if (values["shieldsPercentage"].to_i < values_old["shieldsPercentage"].to_i)
			puts "Damage... (shields at #{values['shieldsPercentage'].to_i}%, hull at #{hullPercentage.to_i}%)"
			enableForSeconds($strobeLight,0.2)
		end
		if hullPercentage < $settings[:smokeAtDamage].to_i
			if jumpInitiated == false
				jumpInitiated = true
				puts "JUMPING JUMPING"
				jumpResponse = luaPost("http://#{apiServer}#{$settings['apiEndpoint']}",$settings[:initJumpCode])
				puts jumpResponse.body
				puts "JUMPING JUMPING"
			end


			sleepTime = 0.5
			sleepTime = 0.8 if hullPercentage < 40
			sleepTime = 1.0 if hullPercentage < 30
			sleepTime = 1.2 if hullPercentage < 20
			sleepTime = 1.5 if hullPercentage < 10
			puts "Hull at #{hullPercentage.to_i}%! Repairs needed to fix smoke! (smoke time = #{sleepTime} s)"
			enableForSeconds($smokeSwitch,sleepTime)
		end
		values_old = values
	end
end

