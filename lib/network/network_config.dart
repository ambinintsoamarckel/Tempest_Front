import 'package:dio/dio.dart';
import './get_network_config.dart'
    if (dart.library.io) 'mobile_network_config.dart'
    if (dart.library.html) 'web_network_config.dart';

class NetworkConfig {
  final _client = getClient()
    ..options = BaseOptions(
      baseUrl: 'https://tempest-3hs7.onrender.com',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 6),
    );

  Dio get client => _client;
}
