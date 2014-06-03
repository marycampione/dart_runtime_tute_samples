/*
 * goes with docs/dart/usingusers.html
 */

import 'package:appengine/appengine.dart';
import 'dart:async';
import 'dart:io';

main() {
  runAppEngine().then((Stream<HttpRequest> requestStream) {
    requestStream.listen((request) {
      var context = contextFromRequest(request);
      var users = context.services.users;

      if (users.currentUser != null) {
        request.response
           ..headers.contentType = new ContentType('text', 'plain')
           ..write(users.currentUser.email)
           ..close();
      } else {
        return users.createLoginUrl('${request.uri}').then((String url) {
              return request.response.redirect(Uri.parse(url));
            });
      }
    });
  });
}
