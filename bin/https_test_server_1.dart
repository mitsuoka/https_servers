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
  1. Attached NSS DB includes self-signed certificate. Your browser will complain
     about certificate is not valid (but can easily bypass it by telling browser
     that you trust this site). If you have NSS DB that includes certificate from
     trusted CA, replace cert9.db and key4.db with yours and change CER_NICKNAME
     and DB_PWD values.
  2. Other than on Windows, you may need to change the DB_DIR value.
  June 2013, by Terry Mitsuoka
  November 2013, API change (remoteHost -> remoteAddress) incorporated
*/

import 'dart:async';
import 'dart:io';

final HOST_NAME = 'localhost';   // use loop back address for the test
final int SERVER_PORT = 443;     // use well known HTTPS port number
final REQ_PATH = '/test';        // request path for this application
final CER_NICKNAME = 'myissuer'; // nickname of the certificate
final DB_PWD = 'changeit';       // NSS DB access pass word
final DB_DIR = r'..\nss';        // NSS DB directory path
final LOG_REQUESTS = true;

void main() {
  initializeSecureSocket();
  listenHttpsRequest();
}

void initializeSecureSocket() {
  SecureSocket.initialize(database: DB_DIR,
                          password: DB_PWD,
                          useBuiltinRoots: false);
  log('NSS library initialized.');
}

void listenHttpsRequest() {
  HttpServer.bindSecure(HOST_NAME,
                        SERVER_PORT,
                        certificateName: CER_NICKNAME)
  .then((HttpServer server) {
    server.listen(
      (HttpRequest req) {
        if (req.uri.path.contains(REQ_PATH)) processRequest(req);
        else {
          req.response.statusCode = HttpStatus.BAD_REQUEST;
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
  String mes = requestInf(req);
  if (LOG_REQUESTS) log('\n$mes');
  req.response.write(
    '''<!DOCTYPE html>This is a response from https_test_server_1.
    <pre>$mes</pre></html>''');
  req.response.close();
}

// adapt this function to your logger
void log(String s) {
  print('${new DateTime.now().toString()} - $s');
}

String requestInf(HttpRequest req) =>
  '''
  req.connectionInfo.remoteAddress : ${req.connectionInfo.remoteAddress}
  req.connectionInfo.remotePort : ${req.connectionInfo.remotePort}
  req.uri : ${req.uri}''';
