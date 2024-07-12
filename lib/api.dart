import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'main.dart';
class ApiService {
  final String clientId = dotenv.env['API42_UID']!;
  final String clientSecret = dotenv.env['API42_SECRET']!;
  String tokenEndpoint = 'https://api.intra.42.fr/oauth/token';
  String baseUrl = 'https://api.intra.42.fr/v2';
  List<String> scopes = [
    'public',
    'projects',
    'profile',
    'elearning',
    'tig',
    'forum'
  ];

  oauth2.Client? _client;

  Future<void> authenticate() async {
    final authorizationEndpoint = Uri.parse(tokenEndpoint);

    _client = await oauth2.clientCredentialsGrant(
      authorizationEndpoint,
      clientId,
      clientSecret,
      scopes: scopes,
      httpClient: http.Client()
    );

  }

  dynamic getUser(String endpoint) async {
    if (_client == null|| _client!.credentials.isExpired) {
      await authenticate();
    }

    final response = await _client!.get(Uri.parse('$baseUrl/$endpoint'));
    sleep(const Duration(milliseconds: 500));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      logging.info(response.statusCode);
      return (response.body);
    }
    else {
      logging.info(response.statusCode);
      return (1);
    }
  }

  dynamic getProjectsUser(String user) async {
    if (_client == null|| _client!.credentials.isExpired) {
      await authenticate();
    }

    dynamic myBody = '';
    dynamic response = await _client!.get(Uri.parse('$baseUrl/users/$user/projects_users?&page[size]=100'));
    sleep(const Duration(milliseconds: 500));
    myBody = response.body;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      logging.info(response.statusCode);
      return (myBody);
    }
    else {
      logging.info(response.statusCode);
      return (1);
    }

  }

}