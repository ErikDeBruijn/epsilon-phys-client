# What is Empty Epsilon?
[Empty Epsilon](http://emptyepsilon.org) is an open source multiplayer space bridge simulation (mostly developed at [Ultimaker](https://ultimaker.com) in the evening hours). The core idea is that all players has to cooperate well in order to survive. The skills of crew and its captain are critical. 

# A physical-client add-on to EmptyEpsilon?
This is an add on that will allow things to happen in the real world while playing the game. When getting hit, you'll see actual flashes from a strobe, when shield are activated a signal light will turn on, when there's signficant damage to the ship's hull, there will be smoke, too.

# What does it look like?
See [this YouTube video](https://www.youtube.com/watch?v=dR8-D7AkZMs) that I made. It will show the strobe flashes and signal light and you may see some smoke.

# How does it work?
Ruby code to run a client that will interface with the Empty Epsilon server. It controls an Arduino, which has a shield connected to it, with relays. The relays are connected to power outlets which have equipment connected to them, such as a strobe, smoke machine or rotating signal light.
The ruby script will automatically detect the Arduino, even when it gets disconnected or reconnected. It will also scan for a running Empty Epsilon server in common IP ranges, so you don't need to know the IP.

# How to build it?
### Basic architecture
```
___________     ___________   ___________    ___________  
|   signal  |   |   strobe  | | smoke     |  | smoke     | 
|   light   |   |   light   | | trigger   |  | power     | 
 -----------     -----------   -----------    -----------  
     |                |             |              |
 ___________     ___________   ___________    ___________  
| Relay 1   |   | Relay 2   | | Relay 3   |  | Relay 4   | 
 -----------     -----------   -----------    -----------  
     |                |             |              |
  _____________________________________________________
 |                                                     |
 |                 Arduino Mega 2560                   |
 |                                                     |
 |                  (running duino)                    |
  -----------------------------------------------------
          |
          |  serial over USB
          |
  ____________________                       ______________
 | physical-client.rb |       http          | EmptyEpsilon |
 |                    |-----lua-script----->|  http server |
 |        ruby        |<----json response---|   enabled    |
 ---------------------                       --------------
```
### Bill of Materials
I've used the following parts:
 - A signal light with a 12V adapter running on 230V
 - Power outlets from the hardware store
 - An Arduino Mega 2650
 - 1.25 mm^2 wire
 - Relay shield (from [seeedstudio](http://www.seeedstudio.com/wiki/Relay_Shield_V2.0))

### Steps
Roughly, these were the steps I took to build this project.
 - Get some enclosures to make sure no 230V is exposed.
 - Connect the arduino with the relayshield
 - Figure our which pins to trigger in the relay shield documentation
 - Program an Arduino the "basic" with the IDE, let it respond to serial chars
 - Send those chars manually
 - Write a little client in ruby
 - Figure out that there's a gem called duino which makes reprogramming the arduino everytime obsolete, just work from ruby to develop all functionality.
 - Connect the 4 relays to 3 power outlets. One is used to control a switch of the smoke system.

### Caveats (read BEFORE YOU START)
 - IMPORTANT: You must have knowledge of how to work with 230V and make a safe circuit
 - Probably best to see if you can get the software running before you spend lots of money on hardware
 - Check pin settings in settings.yml to make sure to turn on the correct relay for the functions you want! Your setup may be connected differently
 - Enabled the httpserver for the PC running as EmptyEpsilon server by adding httpserver=80 to the options.ini
 - Upload the duino firmware (of the [duino ruby gem](https://github.com/austinbv/dino), which basically makes the Arduino a slave to be controlled by the ruby code.

### How to upload the duino firmware to the Arduino:

For info about dino: http://tutorials.jumpstartlab.com/projects/arduino/introducing_arduino.html

1. install inotool (found at: http://inotool.org/ )
2. Run in a terminal: 
```sh
cd du
ino build  -m mega2560
ino upload -m mega2560
```
4. ...
5. profit!

### Running the physical-client
Starting the client is easy:
```ruby physical-client.rb```

For testing purposes you can use ```fake_server.rb```. It will pretend to be an Empty Epsilon server which pretends to have a ship that is getting hit occasionally, until it is destroyed.

### Dependencies
- You need at least a working ruby binary.
- [inotool](http://inotool.org/)
- Several dependencies that I'm forgetting which I have installed.

### License
This ia **free software**. The code is licensed [GPLv3](https://www.gnu.org/copyleft/gpl.html). It comes with no warranty and I don't claim fitness for any purpose (other than to have a bit of fun and learn something).

