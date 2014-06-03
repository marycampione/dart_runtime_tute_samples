
import 'package:appengine/appengine.dart';
import 'dart:io';
import 'dart:async';

main() {
  runAppEngine().then((Stream<HttpRequest> requestStream) {
    requestStream.listen((request) {
      File file = new File('stylesheets/main.css');
      file.exists().then((bool found) {
        if (found) {
          request..headers.contentType = 'text/css'
                 ..headers.set("Cache-Control", "no-cache");
          file.openRead()
              .pipe(request.response)  // HttpResponse type.
              .catchError((e) => print(e.toString()));
        } else {
          request.response.statusCode = HttpStatus.NOT_FOUND;
          request.response.close();
        }
      });
    });
  });
}
