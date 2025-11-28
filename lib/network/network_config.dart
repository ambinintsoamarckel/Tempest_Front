import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import './get_network_config.dart'
    if (dart.library.io) 'mobile_network_config.dart'
    if (dart.library.html) 'web_network_config.dart';

class NetworkConfig {
  final _client = getClient()
    ..options = BaseOptions(
      baseUrl: dotenv.env['API_URL']!,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    );

  Dio get client => _client;
}
