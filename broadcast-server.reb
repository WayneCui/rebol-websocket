REBOL [
	title:		"A WebSocket Broadcast Server"
	date:		22-Sep-2013
	file:		%broadcast-server.reb
	author: 	"Wayne Tsui"
	version:	0.2.1
	needs:		[ websocket-server-util 0.2.1 ]
]

print "A WebSocket Broadcast Server in Rebol 3"

server: open tcp://:8080
ports: copy []
server/awake: func [ event /local port ] [
	if event/type = 'accept [
		port: first event/port 
		append ports port 
		;print length? ports 
		port/awake: func [ event /local data request-data ] [
			;probe port/type
			switch event/type [
				read [
					data: event/port/data
					;print ["Client said:" data ]
					either find to-string data "upgrade: websocket" [						
						handshake data event/port
					][
						request-data: get-request-data data
						;print to-string request-data			
						foreach port ports [
							write port to-binary make-response-data request-data	
						]		
					]
				]
				wrote [
					read event/port
				]
				close [
					close event/port 
					remove find ports event/port
					return true
				]
			]
			false
		]
		read port
	]
	false
]

wait [ server 1000 ]
close server