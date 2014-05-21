
import 'package:appengine/appengine.dart';
import 'dart:async';
import 'dart:io';
import 'package:route/server.dart';
import 'dart:convert';

String MAIN_PAGE_HTML = '''
<html>
  <body>
    <form action="/sign" method="post">
      <div><textarea name="content" rows="3" cols="60"></textarea></div>
      <div><input type="submit" value="Sign Guestbook"></div>
    </form>
  </body>
</html>
''';

serveSignBook(HttpRequest request) {
  List<String> dest = [];

  request.transform(UTF8.decoder).listen((data) {
      dest.add(data.toString());
    },
    onDone: () { 
      request.response.write('<html><body>You wrote:<pre>');
      // XX: how to I get clean content?
      request.response.write(dest);
      request.response.write('</pre></body></html>');
      request.response.close();
    });
}

serveMainPage(HttpRequest request) {
  request.response.write(MAIN_PAGE_HTML);
  request.response.close();
}

main() {
  runAppEngine(/*devappserver: true*/).then((Stream<HttpRequest> requestStream) {
    var router = new Router(requestStream)
        ..serve(new UrlPattern(r'/sign')).listen(serveSignBook)
        ..defaultStream.listen(serveMainPage);
  });
}
