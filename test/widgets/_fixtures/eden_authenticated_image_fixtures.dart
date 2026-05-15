// Do NOT regenerate via LLM — hand-built fixtures for EdenAuthenticatedImage.
//
// Includes:
//   * 1x1 transparent PNG bytes (the smallest valid PNG, 67 bytes).
//   * Sample headers map for the typical Bearer + X-Tenant signed-URL pattern.
//   * Fake HTTP overrides installer + uninstaller — NO mocking library, hand-rolled.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Sample headers + canned bytes for EdenAuthenticatedImage tests.
class EdenAuthenticatedImageFixtures {
  EdenAuthenticatedImageFixtures._();

  /// Smallest valid PNG — 1x1 transparent pixel.
  static final Uint8List tinyPngBytes = Uint8List.fromList(<int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x62, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);

  /// Typical Bearer + X-Tenant headers used by signed-URL fetches.
  static const Map<String, String> bearerHeaders = <String, String>{
    'Authorization': 'Bearer test-token-123',
    'X-Tenant': 'tenant-acme',
  };

  /// Track captured request URIs + headers — read by tests to verify the
  /// widget forwarded headers correctly.
  static final List<_CapturedRequest> capturedRequests = <_CapturedRequest>[];

  /// Install fake HttpOverrides that serve [responseBytes] for matching URIs
  /// with the given [statusCodes]. URIs not in [responseBytes] get a 404.
  static void installFakeHttp({
    Map<String, Uint8List>? responseBytes,
    Map<String, int>? statusCodes,
  }) {
    capturedRequests.clear();
    HttpOverrides.global = _FakeHttpOverrides(
      bytes: responseBytes ?? <String, Uint8List>{},
      codes: statusCodes ?? <String, int>{},
    );
  }

  /// Restore default HttpOverrides.
  static void uninstallFakeHttp() {
    HttpOverrides.global = null;
  }
}

class _CapturedRequest {
  _CapturedRequest(this.uri, this.headers);
  final Uri uri;
  final Map<String, String> headers;
}

class _FakeHttpOverrides extends HttpOverrides {
  _FakeHttpOverrides({required this.bytes, required this.codes});

  final Map<String, Uint8List> bytes;
  final Map<String, int> codes;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient(bytes: bytes, codes: codes);
  }
}

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient({required this.bytes, required this.codes});

  final Map<String, Uint8List> bytes;
  final Map<String, int> codes;

  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  int? maxConnectionsPerHost;

  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}

  @override
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials) {}

  @override
  set authenticate(
      Future<bool> Function(Uri url, String scheme, String? realm)? f) {}

  @override
  set authenticateProxy(
      Future<bool> Function(
              String host, int port, String scheme, String? realm)?
          f) {}

  @override
  set badCertificateCallback(
      bool Function(X509Certificate cert, String host, int port)? callback) {}

  @override
  set connectionFactory(
      Future<ConnectionTask<Socket>> Function(
              Uri url, String? proxyHost, int? proxyPort)?
          f) {}

  @override
  void close({bool force = false}) {}

  @override
  set findProxy(String Function(Uri url)? f) {}

  @override
  set keyLog(Function(String line)? callback) {}

  @override
  Future<HttpClientRequest> open(
      String method, String host, int port, String path) {
    final uri = Uri(scheme: 'http', host: host, port: port, path: path);
    return Future.value(_FakeHttpClientRequest(uri, bytes, codes));
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    return Future.value(_FakeHttpClientRequest(url, bytes, codes));
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      open('GET', host, port, path);

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      open('HEAD', host, port, path);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('HEAD', url);

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      open('PATCH', host, port, path);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('PATCH', url);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      open('POST', host, port, path);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      open('PUT', host, port, path);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('PUT', url);

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      open('DELETE', host, port, path);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('DELETE', url);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest(this.uri, this.bytes, this.codes);

  @override
  final Uri uri;
  final Map<String, Uint8List> bytes;
  final Map<String, int> codes;

  final _capturedHeaders = <String, String>{};

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    // Capture this request.
    _FakeHttpHeaders fakeHeaders = headers as _FakeHttpHeaders;
    _capturedHeaders.addAll(fakeHeaders.captured);
    EdenAuthenticatedImageFixtures.capturedRequests.add(
      _CapturedRequest(uri, Map.from(_capturedHeaders)),
    );
    final url = uri.toString();
    final body = bytes[url] ?? Uint8List(0);
    final code = codes[url] ?? (bytes.containsKey(url) ? 200 : 404);
    return _FakeHttpClientResponse(body, code);
  }

  @override
  bool bufferOutput = true;

  @override
  int contentLength = -1;

  @override
  late HttpConnectionInfo connectionInfo;

  @override
  List<Cookie> cookies = <Cookie>[];

  @override
  Future<HttpClientResponse> get done => close();

  @override
  Encoding encoding = const _NoopEncoding();

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  String method = 'GET';

  @override
  bool persistentConnection = true;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream<List<int>> stream) async {}

  @override
  Future flush() async {}

  @override
  void write(Object? obj) {}

  @override
  void writeAll(Iterable objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? obj = '']) {}
}

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, String> captured = <String, String>{};

  @override
  bool chunkedTransferEncoding = false;

  @override
  int contentLength = -1;

  @override
  ContentType? contentType;

  @override
  DateTime? date;

  @override
  DateTime? expires;

  @override
  String? host;

  @override
  DateTime? ifModifiedSince;

  @override
  bool persistentConnection = true;

  @override
  int? port;

  @override
  List<String>? operator [](String name) =>
      captured.containsKey(name) ? <String>[captured[name]!] : null;

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    captured[name] = value.toString();
  }

  @override
  void clear() => captured.clear();

  @override
  void forEach(void Function(String name, List<String> values) action) {
    captured.forEach((k, v) => action(k, <String>[v]));
  }

  @override
  void noFolding(String name) {}

  @override
  void remove(String name, Object value) {
    captured.remove(name);
  }

  @override
  void removeAll(String name) {
    captured.remove(name);
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    captured[name] = value.toString();
  }

  @override
  String? value(String name) => captured[name];
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse(this.bytes, this.statusCode);

  final Uint8List bytes;

  @override
  final int statusCode;

  @override
  X509Certificate? get certificate => null;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  int get contentLength => bytes.length;

  @override
  List<Cookie> get cookies => <Cookie>[];

  @override
  Future<Socket> detachSocket() => throw UnimplementedError();

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    final stream = Stream<List<int>>.fromIterable(<List<int>>[bytes]);
    return stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  bool get persistentConnection => true;

  @override
  String get reasonPhrase => statusCode == 200 ? 'OK' : 'Not Found';

  @override
  Future<HttpClientResponse> redirect(
          [String? method, Uri? url, bool? followLoops]) =>
      Future.value(this);

  @override
  List<RedirectInfo> get redirects => <RedirectInfo>[];
}

class _NoopEncoding extends Encoding {
  const _NoopEncoding();

  @override
  Converter<List<int>, String> get decoder => throw UnimplementedError();

  @override
  Converter<String, List<int>> get encoder => throw UnimplementedError();

  @override
  String get name => 'noop';
}
