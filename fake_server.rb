require 'sinatra'
require 'socket'

server = TCPServer.new 35666 # Server bound to port 35666, just like EE

set :port, 8080

hull = 42
shields = 80

hullMax = 80

i = 0
post '/exec.lua' do
	i += 1
	hull = [0,hull - 0.3].max if shields <= 0
	shields = [0, shields - 15].max if (i%8==0)
	shieldsPerc = (shields / 100.0).to_f
	shields_active = rand(10) > 2
	puts "Got a post. Hull=#{hull}, shields=#{shields}, shieldsPerc=#{shieldsPerc}"
	"{\"shieldsUp\": #{shields_active},\"hull\": #{hull.to_i},\"hullMax\": #{hullMax.to_i}, \"shieldsPercentage\": #{shieldsPerc}}"
end