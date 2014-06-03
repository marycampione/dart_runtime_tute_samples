/*
 * goes with docs/dart/staticfiles.html
 */

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:appengine/appengine.dart';
import 'package:cloud_datastore/cloud_datastore.dart';
import 'package:route/server.dart';
import 'package:mustache/mustache.dart' as mustache;

final HTML = new ContentType('text', 'html', charset: 'charset=utf-8');
final MAIN_PAGE = mustache.parse('''
<html>
  <body>
    <head>
      <title>Greetings page.</title>
      <link type="text/css" rel="stylesheet" href="stylesheets/main.css" />
    </head>
  </body>
  <div>
    <h1>Greetings from db :) [user: {{user}}]</h1>
    {{#entries}}
      <div style="border: 1px solid gray; margin: 10px;">
        Author: {{author}}<br />
        Date: {{date}}<br />
        Message:<br />
        <pre>{{content}}</pre>
      </div>
    {{/entries}}
    <br /><br />
    <form method="POST">
       Author: <input name="author" type="text" /><br/>
       <textarea name="text" rows="5" cols="60"></textarea><br/>
       <input type="submit" value="Submit to Guestbook" />
    </form>
  </div>
</html>
''');

Map convertGreeting(Greeting g) {
  return {'date' : g.date, 'author' : g.author, 'content' : g.content};
}

@ModelMetadata(const GreetingDesc())
class Greeting extends Model {
  String author;
  String content;
  DateTime date;
}

class GreetingDesc extends ModelDescription {
  final id = const IntProperty();
  final author = const StringProperty();
  final content = const StringProperty();
  final date = const DateTimeProperty();

  const GreetingDesc() : super('Greeting');
}

serveMainPage(HttpRequest request) {
  var context = contextFromRequest(request);
  var db = context.services.db;

  var users = context.services.users;

  if (users.currentUser == null) {
    return users.createLoginUrl('${request.uri}').then((String url) {
      return request.response.redirect(Uri.parse(url));
    });
  }

  Future saveGreeting(Greeting greeting) {
    return db.commit(inserts: [greeting]);
  }

  Future<List<Greeting>> queryEntries() {
    return (db.query(Greeting)..order('date')).run();
  }

  Future showGreetingList() {
    return queryEntries().then((List<Greeting> greetings) {
      var renderMap = {
        'entries' : greetings.map(convertGreeting).toList(),
        'user' : users.currentUser.email,
      };
      return sendResponse(request.response, MAIN_PAGE.renderString(renderMap));
    });
  }

  if (request.method == 'GET') {
    return showGreetingList();
  } else {
    return request.transform(UTF8.decoder).fold('', (a,b) => '$a$b').then((c) {
      var parms = Uri.splitQueryString(c);
      var greeting = new Greeting()
          ..parentKey = db.emptyKey
          ..author = parms['author'] + ' (${users.currentUser.email})'
          ..content  = parms['text']
          ..date = new DateTime.now();
      return saveGreeting(greeting).then((_) => showGreetingList());
    });
  }
}

/*
final CSS = new ContentType('text', 'css');

sendStyles(HttpRequest request) {
      File file = new File('stylesheets/main.css');
      file.exists().then((bool found) {
        if (found) {
          request..headers.contentType = CSS
                 ..headers.set("Cache-Control", "no-cache")
          file.openRead()
              .pipe(request.response)  // HttpResponse type.
              .catchError((e) => print(e.toString()));
          request.response.close();
        } else {
          request.response.statusCode = HttpStatus.NOT_FOUND;
          request.response.close();
        }
      });
}
*/

sendResponse(HttpResponse response, String message) {
  return (response
      ..headers.contentType = HTML
      ..headers.set("Cache-Control", "no-cache")
      ..statusCode = HttpStatus.OK
      ..add(UTF8.encode(message)))
      .close();
}

main() {
  runAppEngine(/*devappserver: true, docker: true*/)
      .then((Stream<HttpRequest> requestStream) {
    var router = new Router(requestStream)
      //..serve(new UrlPattern(r'/stylesheets')).listen(sendStyles)
      ..defaultStream.listen(serveMainPage);
  });
}
