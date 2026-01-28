extends Node

const IP_ADDRESS = 'localhost'
const PORT = 9001
const MAX_CLIENTS = 4

func start_server():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer
	
	print('Start server')
	
func start_client():
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer
	
	print('Start client')
	
