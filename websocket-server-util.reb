REBOL [
	title:		"websocket-server-util"
	name:		"websocket-server-util"
	type:		'module
	version:	0.2.1
	date:		22-Sep-2013
	file:		%websocket-server-util.reb
	author: 	"Wayne Tsui"
	exports:	[ compute handshake get-request-data make-response-data ]
	
]

compute: func [ key [ string! binary! ] /local uuid ] [
	uuid: "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
	enbase checksum/method to-binary join to-string key uuid 'sha1
]

handshake: func [ data [ binary! string! ] port [ port! ] /local key ][
	parse data [ thru "Sec-WebSocket-Key: " copy key to "^M^/" ]
	write port to-binary rejoin [
		{HTTP/1.1 101 Switching Protocols^M^/Upgrade: websocket^M^/Connection: Upgrade^M^/Sec-WebSocket-Accept: } compute key "^M^/^M^/"]
]

get-request-data: func [ raw-data /local len index masks payload request-data ][
	len: ( pick raw-data 2 ) & 127 
	;?? len
	request-data: copy #{}
	index: 0
	case [
		len = 126 [
			masks: copy/part at raw-data 5 4
			payload: copy at raw-data 9
		]
		len = 127 [
			masks: copy/part at raw-data 11 4
			payload: copy at raw-data 15
		]
		true	  [
			masks: copy/part at raw-data 3 4
			payload: copy at raw-data 7
		]
	]

	foreach byte payload [
		append request-data byte xor (pick masks ((mod index 4) + 1))
		++ index
	]
	request-data
]

make-response-data: func [ data-to-send [ binary! ] /local len response-data ] [
	len: length? data-to-send
	;print len
	case [
		len <= 126 [ response-data: rejoin [ copy #{81} len data-to-send ]]
		all [ len > 125 len <= 65535 ][ 
			response-data: rejoin [ copy #{81} 126 
				(shift len -8) & 255 
				len & 255 
				data-to-send
			]
		]
		len > 65535 [
			response-data: rejoin [ copy #{81} 127 
				(shift len -56) & 255 
				(shift len -48) & 255 
				(shift len -40) & 255 
				(shift len -32) & 255 
				(shift len -24) & 255 
				(shift len -16) & 255 
				(shift len -8) & 255 
				len & 255 
				data-to-send
			]
		]	  
	]
	response-data
]