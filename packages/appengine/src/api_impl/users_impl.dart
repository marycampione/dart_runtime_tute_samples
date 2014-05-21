// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library users_impl;

import 'dart:async';

import 'package:appengine/api/users.dart';

import '../protobuf_api/user_service.dart';
import '../protobuf_api/rpc/rpc_service.dart';
import '../protobuf_api/internal/user_service.pb.dart' as pb;
import '../server/http_wrapper.dart';

class UserRpcImpl extends UserService {
  static String _HTTP_HEADER_AUTH_DOMAIN = 'x-appengine-auth-domain';
  static String _HTTP_HEADER_USER_EMAIL = 'x-appengine-user-email';
  static String _HTTP_HEADER_USER_ID = 'x-appengine-user-id';
  static String _HTTP_HEADER_USER_IS_ADMIN = 'x-appengine-user-is-admin';
  static String _HTTP_HEADER_FEDERATED_IDENTITY =
      'x-appengine-federated-identity';
  static String _HTTP_HEADER_FEDERATED_PROVIDER =
      'x-appengine-federated-provider';

  final UserServiceClientRPCStub _clientRPCStub;
  User _currentUser;

  UserRpcImpl(
      RPCService rpcService, String ticket, AppengineHttpRequest request)
      : _clientRPCStub = new UserServiceClientRPCStub(rpcService, ticket) {
    var userEmail = request.headers.value(_HTTP_HEADER_USER_EMAIL);
    var userId = request.headers.value(_HTTP_HEADER_USER_ID);
    var userIsAdmin = request.headers.value(_HTTP_HEADER_USER_IS_ADMIN) == '1';
    var authDomain = request.headers.value(_HTTP_HEADER_AUTH_DOMAIN);
    var federatedIdentity =
        request.headers.value(_HTTP_HEADER_FEDERATED_IDENTITY);
    var federatedProvider =
        request.headers.value(_HTTP_HEADER_FEDERATED_PROVIDER);

    if ((userEmail != null && !userEmail.isEmpty) ||
        (federatedIdentity != null && !federatedIdentity.isEmpty)) {
      _currentUser = new User(
          authDomain: authDomain,
          email: userEmail, id: userId,
          federatedIdentity: federatedIdentity,
          federatedProvider: federatedProvider,
          isAdmin: userIsAdmin);
    }
  }

  User get currentUser => _currentUser;

  Future<String> createLoginUrl(String destination,
                                {String federatedIdentity}) {
    var request = new pb.CreateLoginURLRequest();
    request.destinationUrl = destination;
    if (federatedIdentity != null) {
      request.federatedIdentity = federatedIdentity;
    }
    return _clientRPCStub.CreateLoginURL(request)
        .then((response) => response.loginUrl);
  }

  Future<String> createLogoutUrl(String destination) {
    var request = new pb.CreateLogoutURLRequest();
    request.destinationUrl = destination;
    return _clientRPCStub.CreateLogoutURL(request)
        .then((response) => response.logoutUrl);
  }
}
