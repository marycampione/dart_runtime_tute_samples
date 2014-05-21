
import 'package:appengine/appengine.dart';
import 'dart:async';
import 'dart:io';

main() {
  runAppEngine().then((Stream<HttpRequest> requestStream) {
    requestStream.listen((request) {
      var context = contextFromRequest(request);
      var users = context.services.users;

      if (users.currentUser != null) {
        request.response.write(users.currentUser.email);
        request.response.close();
      } else {
        return users.createLoginUrl('${request.uri}').then((String url) {
              return request.response.redirect(Uri.parse(url));
            });
      }
    });
  });
}