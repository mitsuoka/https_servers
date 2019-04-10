/*
  Dart code sample: Simple HTTPS test server

  1. Run the https_test_1.dart as server.
  2. Access the server from Chrome: https://localhost/test
  Typical response of the server will be:
    This is a response from https_test_server_1.
      req.connectionInfo.remoteHost : ::28ed:9707:0:0
      req.connectionInfo.remotePort : 51045
      req.uri : /test

  Notes:
  1. This program runs on Dart-SDK 1.13.0 dev 1.0 or later.
  2. Tested on Windows.
  3. Attached OpenSSL holder includes self-signed certificate. Your browser will complain
     about certificate is not valid (but can easily bypass it by telling browser
     that you trust this site).
  4. Other than on Windows, you may need to change the path-to-pem file path value.

  June 2013, by Terry Mitsuoka
  November 2013, API change (remoteHost -> remoteAddress) incorporated
  October 2015, API change (NSS -> BoringSSL) incorporated
  April 2019, made Dart 2 compliant
*/

import 'dart:io';

final LOG_REQUESTS = true;       // set true for debugging
final HOST_NAME = 'localhost';   // use loop back address for the test
final int SERVER_PORT = 443;     // use well known HTTPS port number
final REQ_PATH = '/test';        // request path for this application
final CERT_PATH = 'openssl/my_crt.pem'; // path to pem cert file
final KEY_PATH = 'openssl/my_key.pem';  // path to pem private key file
final KEY_PASSWORD = 'changeit';        // password for the key file

SecurityContext serverContext;   // security context of this server

void main() {
  setSecurityContext();
  listenHttpsRequest();
}

void setSecurityContext() {
  serverContext = new SecurityContext()
    ..useCertificateChain(CERT_PATH)
    ..usePrivateKey(KEY_PATH, password: KEY_PASSWORD);
  log('BoringSSL security context initialized.');
}

void listenHttpsRequest() {
  HttpServer.bindSecure(HOST_NAME,
                        SERVER_PORT,
                        serverContext)
  .then((HttpServer server) {
    server.listen(
      (HttpRequest req) {
        if (req.uri.path.contains(REQ_PATH)) processRequest(req);
        else {
          req.response.statusCode = HttpStatus.badRequest;
          req.response.close();
        }
      },
      onError: (err) {
        print('listen: error: $err');
      },
      onDone: () {
        print('listen: done');
      },
      cancelOnError: false
      );
    log('https_test_1 server started.');
  });
}

void processRequest(HttpRequest req) {
  req.response.headers.add("Content-Type", "text/html; charset=UTF-8");
  String mes = requestInf(req);
  if (LOG_REQUESTS) log('\n$mes');
  req.response.write(
    '''<!DOCTYPE html>This is a response from https_test_server_1.
    <pre>$mes</pre></html>''');
  req.response.close();
}

// adapt this function to your logger
void log(String s) {
  print('${new DateTime.now().toString().substring(11)} - $s');
}

String requestInf(HttpRequest req) =>
  '''
  req.connectionInfo.remoteAddress : ${req.connectionInfo.remoteAddress}
  req.connectionInfo.remotePort : ${req.connectionInfo.remotePort}
  req.uri : ${req.uri}''';
