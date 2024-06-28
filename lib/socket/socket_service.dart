import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? socket;

  void initializeSocket(id) {
    socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket!.connect();

    socket!.on('connect', (_) {
      print(id);
      // Handle user connected
      socket!.emit('user_connected', id);
    });

    socket!.on('disconnect', (_) {
      print('déconnecté');
      // Handle user disconnected
      socket!.emit('user_disconnected', 'USER_ID');
    });

    socket!.on('message', (data) {
      print('message: $data');
      // Handle incoming message
    });

    // Add more event handlers as needed
  }

  void sendMessage(String message) {
    socket!.emit('message', message);
  }

  void disconnect() {
    socket!.disconnect();
  }
}
