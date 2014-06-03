/*
 * goes with docs/dart/helloworld.html
 */

import 'package:appengine/appengine.dart';
import 'dart:async';
import 'dart:io';

main() {
  runAppEngine().then((Stream<HttpRequest> requestStream) {
    requestStream.listen((request) {
      request.response
        ..headers.contentType = new ContentType('text', 'plain')
        ..write('Hello, Universe!')
        ..close();
    });
  });
}
