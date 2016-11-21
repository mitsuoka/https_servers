/*
  Dart code sample: Simple HTTPS test server

  1. Run the https_test_server_2.dart as server.
  2. Access the server from Chrome: https://localhost/test

  Notes:
  1. This program runs on Dart-SDK 1.13.0 dev 1.0 or later.
  2. Tested on Windows.
  3. Attached OpenSSL holder includes self-signed certificate. Your browser will complain
     about certificate is not valid (but can easily bypass it by telling browser
     that you trust this site).
  4. Other than on Windows, you may need to change the path-to-pem file path value.

  June 2013, by Terry Mitsuoka
  July 2013, ruggedized
  November 2013, API change (remoteHost -> remoteAddress) incorporated
  October 2015, API change (NSS -> BoringSSL) incorporated
*/

import 'dart:io';
import 'package:mime_type/mime_type.dart' as mime;

final LOG_REQUESTS = true;       // set true for debugging
final HOST_NAME = 'localhost';   // use loop back address for the test
final int SERVER_PORT = 443;     // use well known HTTPS port number
final REQ_PATH = '/test';        // request path for this application
final CERT_PATH = 'openssl/my_crt.pem';   // path to pem cert file
final KEY_PATH = 'openssl/my_key.pem';    // path to pem private key file
final KEY_PASSWORD = 'changeit';          // password for the key file
final SESSION_MAX_INACTIVE_INTERVAL = 20; // set this parameter in seconds.
                                 // Dart default timeout value is 20 minutes

SecurityContext serverContext;   // security context of this server
ServiceHandler service;
FileHandler fhandler;

void main() {
  service = new ServiceHandler();
  fhandler = new FileHandler();
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
    server.sessionTimeout = SESSION_MAX_INACTIVE_INTERVAL; // set session timeout
    server.listen(
      (HttpRequest req) {
        req.response.done.then((d){
          if (LOG_REQUESTS) log('sent response to the client for request : ${req.uri}');
        }).catchError((err) {
          log('Error occured while sending response.. $err');
        });
        if (req.uri.path.contains(REQ_PATH)) processRequest(req);
        else if (req.uri.toString().contains('favicon.ico'))
          fhandler.doService(req, 'resources/favicon.ico');
        else {
          req.response.statusCode = HttpStatus.BAD_REQUEST;
          req.response.close();
        }
      },
      onError: (err) {
        log('Listen request error.. $err');
      },
      onDone: () {
        log('Done request listening');
      },
      cancelOnError: false
      );
    log('https_test_2 server started. Serving $REQ_PATH on https://$HOST_NAME:$SERVER_PORT.');
  });
}


void processRequest(HttpRequest req) {
  try {
    if (LOG_REQUESTS) log('\n${requestInf(req)}');
    var pattern = REQ_PATH + '/resources';
    var uri = req.uri.toString();
    if (uri.contains(pattern)) {
      var fileName = uri.substring(uri.indexOf(pattern) + REQ_PATH.length + 1);
      fhandler.doService(req, fileName);
    }
    else {
      service.doService(req);
    }
  }catch (err, st) {
    log('Request processing error.. $err \n$st');
  }
}



/*
 * Service handler class
 * Performs services for requests from the client
 */
class ServiceHandler {

  var session;

  void doService(HttpRequest req) {
    session = new Session(req); // get session for the client
    // manage page transition
    if (req.uri.queryParameters["command"] == null || session.isNew) {
      sendFrontPage(req);
    }
    else if (req.uri.queryParameters["command"] == 'Start') {
      session.setAttribute('fromPage', 1);
      sendNextPage(req);
    }
    else if (req.uri.queryParameters["command"] == 'Next Page') {
      session.setAttribute('fromPage', session.getAttribute('fromPage') +1);
      sendNextPage(req);
    }
    else if (req.uri.queryParameters["command"] == 'Reset') {
      session.invalidate();
      session = new Session(req); // not necessary, just for log
      sendFrontPage(req);
    }
  }

  void sendFrontPage(HttpRequest req) {
    req.response.headers.add("Content-Type", "text/html; charset=UTF-8");
    var body = '''
      <!DOCTYPE html>
      <html>
        <head>
          <title>Https Server</title>
        </head>
        <body>
          <h1>
          <!--  <img src="$REQ_PATH/resources/dart_logo.jpg" -->
            <img src="$REQ_PATH/resources/dart_logo.jpg"
               align="middle" width="100" height="100">
            Welcome To My Secure Server</h1><br><br>
          <form method="get" action="$REQ_PATH">
            <input type="submit" name="command" value="Start">
          </form>
             ${requestInf(req)}
        </body>
      </html>''';
    req.response.write(body);
    req.response.close();
  }

  void sendNextPage(HttpRequest req) {
    req.response.headers.add("Content-Type", "text/html; charset=UTF-8");
    var body = '''
      <!DOCTYPE html>
      <html>
        <head>
          <title>HttpSessionTest</title>
        </head>
        <body>
          <h1>
            <img src="$REQ_PATH/resources/dart_logo.jpg"
               align="middle" width="100" height="100">
            Page ${session.getAttribute('fromPage')}</h1><br>
            Session will be expired after ${SESSION_MAX_INACTIVE_INTERVAL} seconds.<br>
          <form method="get" action="$REQ_PATH">
            <input type="submit" name="command" value="Next Page">
            <input type="submit" name="command" value="Reset">
          </form>
             ${requestInf(req)}
        </body>
      </html>''';
    req.response.write(body);
    req.response.close();
  }

  String requestInf(HttpRequest req) {
    return  '''<pre>*** Your request was ***
${createRequestLog(req).toString()}
${createSessionLog(session).toString()}
</per>''';
  }

  // create request log message
  StringBuffer createRequestLog(HttpRequest request, [String bodyString]) {
    var sb = new StringBuffer( '''request.headers.host : ${request.headers.host}
request.headers.port : ${request.headers.port}
request.connectionInfo.localPort : ${request.connectionInfo.localPort}
request.connectionInfo.remoteAddress : ${request.connectionInfo.remoteAddress}
request.connectionInfo.remotePort : ${request.connectionInfo.remotePort}
request.method : ${request.method}
request.persistentConnection : ${request.persistentConnection}
request.protocolVersion : ${request.protocolVersion}
request.contentLength : ${request.contentLength}
request.uri : ${request.uri}
request.uri.path : ${request.uri.path}
request.uri.query : ${request.uri.query}
request.uri.queryParameters :
''');
    request.uri.queryParameters.forEach((key, value){
      sb.write("  ${key} : ${value}\n");
    });
    sb.write('''request.cookies :
''');
    request.cookies.forEach((value){
      sb.write("  ${value.toString()}\n");
    });
    sb.write('''request.headers.expires : ${request.headers.expires}
request.headers :
  ''');
    var str = request.headers.toString();
    for (int i = 0; i < str.length - 1; i++){
      if (str[i] == "\n") { sb.write("\n  ");
      } else { sb.write(str[i]);
      }
    }
    sb.write('''\nrequest.session.id : ${request.session.id}
requset.session.isNew : ${request.session.isNew}''');
    if (request.method == "POST") {
      var enctype = request.headers["content-type"];
      if (enctype[0].contains("text")) {
        sb.write("request body string : ${bodyString.replaceAll('+', ' ')}");
      } else if (enctype[0].contains("urlencoded")) {
        sb.write("request body string (URL decoded): ${Uri.decodeFull(bodyString)}");
      }
    }
    sb.write("\n");
    return sb;
  }


   // Create session log message
  StringBuffer createSessionLog(Session session) {
    var sb = new StringBuffer("");
    sb.write('''*** Current Session object ***
session.isNew : ${session.isNew}
session.id : ${session.id}
session.getAttributeNames : ${session.getAttributeNames()}
session.getAttributes : ${session.getAttributes()}
''');
    return sb;
}
}


/*
 * Session class is a wrapper of the HttpSession
 * Makes it easier to transport Java server code to Dart server
 */
class Session{
  HttpSession _session;
  String _id;
  bool _isNew;

  Session(HttpRequest request){
    _session = request.session;
    _id = request.session.id;
    _isNew = request.session.isNew;
    request.session.onTimeout = (){
      print("${new DateTime.now().toString().substring(0, 19)} : "
       "timeout occurred for session ${_id}");
    };
  }

  // getters
  HttpSession get session => _session;
  String get id => _id;
  bool get isNew => _isNew;

  // getAttribute(String name)
  dynamic getAttribute(String name) => _session[name];

  // setAttribute(String name, dynamic value)
  setAttribute(String name, dynamic value) { _session[name] = value; }

  // getAttributes()
  Map getAttributes() {
    Map attributes = {};
    for(String x in _session.keys) attributes[x] = _session[x];
    return attributes;
  }

  // getAttributeNames()
  List getAttributeNames() {
    List names = [];
    for(String x in _session.keys) names.add(x);
    return names;
  }

  // removeAttribute()
  removeAttribute(String name) { _session.remove(name); }

  // invalidate()
  invalidate() { _session.destroy(); }
}


/*
 * File handler class
 * Returns static files in resouces directory to the client
 */
class FileHandler {

  // set the fileName like 'resources/file-name'
  void doService(HttpRequest req, [String fileName = null]) {
    File file;
    try {
      final HttpResponse res = req.response;
      if (fileName == null) {
        var pattern = REQ_PATH + '/resources';
        var uri = req.uri.toString();
        if (uri.contains(pattern)) {
          fileName = uri.substring(uri.indexOf(pattern) + REQ_PATH.length + 1);
        }
      }
      if (LOG_REQUESTS) log('Requested file : $fileName');
      file = new File(fileName);
      String mimeType;
      if (file.existsSync()) {
        mimeType = mime.mime(fileName);
        if (mimeType == null) mimeType = 'text/plain; charset=UTF-8'; // default
        res.headers.set('Content-Type', mimeType);
        // Get length of the file for Content-Length header.
        RandomAccessFile openedFile = file.openSync();
        res.contentLength = openedFile.lengthSync();
        openedFile.closeSync();
        // Pipe the file content into the response.
        file.openRead().pipe(res);
      } else {
        if (LOG_REQUESTS) log('File not found: $fileName');
        sendNotFoundPage(req);
      }
    } catch (err, st) {
    log('File Service error : $err/n$st');
    }
  }

  static final String notFoundPageHtml = '''
<html><head>
<title>404 Not Found</title>
</head><body>
<h1>Not Found</h1>
<p>The requested URL or File was not found on this server.</p>
</body></html>''';

  void sendNotFoundPage(HttpRequest req, [String notFoundPage = null]){
    final String notFoundPageHtml = '''
      <html><head>
      <title>404 Not Found</title>
      </head><body>
      <h1>Not Found</h1>
      <p>The requested URL or File was not found on this server.</p>
      </body></html>''';
    if (notFoundPage == null) notFoundPage = notFoundPageHtml;
    req.response
      ..statusCode = HttpStatus.NOT_FOUND
      ..headers.set('Content-Type', 'text/html; charset=UTF-8')
      ..write(notFoundPage)
      ..close();
  }
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
