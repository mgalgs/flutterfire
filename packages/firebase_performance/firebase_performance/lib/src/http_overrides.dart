// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_setters_without_getters

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_performance/firebase_performance.dart';

typedef HttpMetricOnRequestInterceptor = void Function(
  HttpClientRequest request,
  HttpMetric metric,
);

typedef HttpMetricOnResponseInterceptor = void Function(
  HttpClientResponse response,
  HttpMetric metric,
);

class FirebasePerformanceMonitoringHttpClientRequest
    implements HttpClientRequest {
  final HttpClientRequest request;

  final HttpMetric? metric;

  final HttpMetricOnResponseInterceptor? onResponse;

  FirebasePerformanceMonitoringHttpClientRequest(
    this.request,
    this.metric,
    this.onResponse,
  )   : maxRedirects = request.maxRedirects,
        bufferOutput = request.bufferOutput,
        contentLength = request.contentLength,
        encoding = request.encoding,
        followRedirects = request.followRedirects,
        persistentConnection = request.persistentConnection;

  @override
  bool bufferOutput;

  @override
  int contentLength;

  @override
  Encoding encoding;

  @override
  bool followRedirects;

  @override
  int maxRedirects;

  @override
  bool persistentConnection;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {
    return request.abort(exception, stackTrace);
  }

  @override
  void add(List<int> data) {
    return request.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    return request.addError(error, stackTrace);
  }

  @override
  Future addStream(Stream<List<int>> stream) {
    return request.addStream(stream);
  }

  @override
  Future<HttpClientResponse> close() async {
    final response = await request.close();
    if (metric != null) onResponse?.call(response, metric!);
    metric?.httpResponseCode = response.statusCode;
    metric?.responsePayloadSize = response.contentLength;
    metric?.responseContentType = response.headers.value('content-type');
    await metric?.stop();
    return response;
  }

  @override
  HttpConnectionInfo? get connectionInfo => request.connectionInfo;

  @override
  List<Cookie> get cookies => request.cookies;

  @override
  Future<HttpClientResponse> get done {
    return Future(() async {
      final response = await request.done;
      metric?.httpResponseCode = response.statusCode;
      metric?.responsePayloadSize = response.contentLength;
      metric?.responseContentType = response.headers.value('content-type');
      await metric?.stop();
      return response;
    });
  }

  @override
  Future flush() {
    return request.flush();
  }

  @override
  HttpHeaders get headers => request.headers;

  @override
  String get method => request.method;

  @override
  Uri get uri => request.uri;

  @override
  void write(Object? object) {
    return request.write(object);
  }

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    return request.writeAll(objects, separator);
  }

  @override
  void writeCharCode(int charCode) {
    return request.writeCharCode(charCode);
  }

  @override
  void writeln([Object? object = '']) {
    return request.writeln(object);
  }
}

class FirebasePerformanceMonitoringHttpClient implements HttpClient {
  FirebasePerformanceMonitoringHttpClient(
    this.client,
    this.performance, {
    this.onRequest,
    this.onResponse,
  })  : autoUncompress = client.autoUncompress,
        connectionTimeout = client.connectionTimeout,
        maxConnectionsPerHost = client.maxConnectionsPerHost,
        userAgent = client.userAgent,
        idleTimeout = client.idleTimeout;

  final FirebasePerformance performance;

  final HttpClient client;

  final HttpMetricOnRequestInterceptor? onRequest;

  final HttpMetricOnResponseInterceptor? onResponse;

  @override
  Future<FirebasePerformanceMonitoringHttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) {
    return withInterceptor(client.open(method, host, port, path));
  }

  @override
  Future<FirebasePerformanceMonitoringHttpClientRequest> openUrl(
    String method,
    Uri url,
  ) {
    return withInterceptor(client.openUrl(method, url));
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) {
    return open('get', host, port, path);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    return openUrl('get', url);
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) {
    return open('post', host, port, path);
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) {
    return openUrl('post', url);
  }

  @override
  Future<HttpClientRequest> put(String host, int port, String path) {
    return open('put', host, port, path);
  }

  @override
  Future<HttpClientRequest> putUrl(Uri url) {
    return openUrl('put', url);
  }

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) {
    return open('delete', host, port, path);
  }

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) {
    return openUrl('delete', url);
  }

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) {
    return open('patch', host, port, path);
  }

  @override
  Future<HttpClientRequest> patchUrl(Uri url) {
    return openUrl('patch', url);
  }

  @override
  Future<HttpClientRequest> head(String host, int port, String path) {
    return open('head', host, port, path);
  }

  @override
  Future<HttpClientRequest> headUrl(Uri url) {
    return openUrl('head', url);
  }

  @override
  set authenticate(
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) {
    client.authenticate = f;
  }

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) {
    client.addCredentials(url, realm, credentials);
  }

  @override
  set findProxy(String Function(Uri url)? f) {
    client.findProxy = f;
  }

  @override
  set authenticateProxy(
    Future<bool> Function(
      String host,
      int port,
      String scheme,
      String? realm,
    )?
        f,
  ) {
    client.authenticateProxy = f;
  }

  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) {
    client.addProxyCredentials(host, port, realm, credentials);
  }

  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? callback,
  ) {
    client.badCertificateCallback = callback;
  }

  @override
  void close({bool force = false}) {
    client.close(force: force);
  }

  Future<FirebasePerformanceMonitoringHttpClientRequest> withInterceptor(
    Future<HttpClientRequest> future,
  ) async {
    HttpClientRequest request = await future;
    HttpMethod? httpMethod;
    switch (request.method.toLowerCase()) {
      case 'get':
        httpMethod = HttpMethod.Get;
        break;
      case 'post':
        httpMethod = HttpMethod.Post;
        break;
      case 'put':
        httpMethod = HttpMethod.Put;
        break;
      case 'delete':
        httpMethod = HttpMethod.Delete;
        break;
      case 'patch':
        httpMethod = HttpMethod.Patch;
        break;
      case 'head':
        httpMethod = HttpMethod.Head;
        break;
      case 'trace':
        httpMethod = HttpMethod.Trace;
        break;
      case 'connect':
        httpMethod = HttpMethod.Connect;
        break;
      case 'options':
        httpMethod = HttpMethod.Options;
        break;
    }
    HttpMetric? metric;
    if (httpMethod != null) {
      metric = performance.newHttpMetric(request.uri.toString(), httpMethod);
    }
    await metric?.start();
    metric?.requestPayloadSize = request.contentLength;
    if (metric != null) onRequest?.call(request, metric);
    return FirebasePerformanceMonitoringHttpClientRequest(
      request,
      metric,
      onResponse,
    );
  }

  @override
  bool autoUncompress;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout;

  @override
  int? maxConnectionsPerHost;

  @override
  String? userAgent;
}

class FirebasePerformanceHttpOverrides extends HttpOverrides {
  FirebasePerformanceHttpOverrides(
    this.performance, {
    this.onRequest,
    this.onResponse,
  });

  final HttpOverrides? currentOverrides = HttpOverrides.current;

  final FirebasePerformance performance;

  final HttpMetricOnRequestInterceptor? onRequest;

  final HttpMetricOnResponseInterceptor? onResponse;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = currentOverrides != null
        ? currentOverrides!.createHttpClient(context)
        : super.createHttpClient(context);
    return FirebasePerformanceMonitoringHttpClient(
      client,
      performance,
      onRequest: onRequest,
      onResponse: onResponse,
    );
  }
}
