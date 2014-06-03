import 'package:appengine/appengine.dart';
import 'dart:async';
import 'dart:io';
import 'package:route/server.dart';

sayHello(HttpRequest request) {
  request.response.write('Hello, Universe!');
  request.response.close();
}

main() {
  runAppEngine().then((Stream<HttpRequest> requestStream) {
    var router = new Router(requestStream)
        ..defaultStream.listen(sayHello);
  });
}
