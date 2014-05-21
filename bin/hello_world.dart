import 'package:appengine/appengine.dart';

main() {
  runAppEngine().then((Stream<HttpRequest> requestStream) {
    requestStream.listen((request) {
      request.response.write('Hello, Universe!');
      request.response.close();
    });
  });
}
