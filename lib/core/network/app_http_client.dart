import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AppHttpClient extends http.BaseClient {
  AppHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final stopwatch = Stopwatch()..start();
    if (kDebugMode) debugPrint('[HTTP] --> ${request.method} ${_sanitisedUrl(request.url)}');

    try {
      final streamed = await _inner.send(request);
      stopwatch.stop();
      final ms = stopwatch.elapsedMilliseconds;

      if (streamed.statusCode >= 400) {
        final body = await streamed.stream.toBytes();
        debugPrint('[HTTP] ✗ <-- ${streamed.statusCode} ${_sanitisedUrl(request.url)} (${ms}ms)\n[HTTP] body: ${String.fromCharCodes(body)}');
        return http.StreamedResponse(
          http.ByteStream.fromBytes(body),
          streamed.statusCode,
          contentLength: streamed.contentLength,
          request: streamed.request,
          headers: streamed.headers,
          isRedirect: streamed.isRedirect,
          persistentConnection: streamed.persistentConnection,
          reasonPhrase: streamed.reasonPhrase,
        );
      }
      if (kDebugMode) debugPrint('[HTTP] ✓ <-- ${streamed.statusCode} ${_sanitisedUrl(request.url)} (${ms}ms)');
      return streamed;
    } catch (e) {
      stopwatch.stop();
      debugPrint('[HTTP] ✗ ERROR ${_sanitisedUrl(request.url)} (${stopwatch.elapsedMilliseconds}ms): $e');
      rethrow;
    }
  }

  @override
  void close() => _inner.close();

  Uri _sanitisedUrl(Uri url) {
    if (url.queryParameters.isEmpty) return url;
    final safe = Map<String, String>.from(url.queryParameters)..remove('apikey');
    return url.replace(queryParameters: safe);
  }
}
