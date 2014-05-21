// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library memcache_raw_impl;

import 'dart:async';

import 'package:memcache/memcache_raw.dart' as raw;

import '../../api/errors.dart';
import '../protobuf_api/rpc/rpc_service.dart';
import '../protobuf_api/internal/memcache_service.pb.dart' as pb;
import '../protobuf_api/memcache_service.dart';

class RawMemcacheRpcImpl implements raw.RawMemcache {
  final MemcacheServiceClientRPCStub _clientRPCStub;

  RawMemcacheRpcImpl(RPCService rpcService, String ticket)
      : _clientRPCStub = new MemcacheServiceClientRPCStub(rpcService, ticket);

  bool _sameKey(a, b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<List<raw.GetResult>> get(List<raw.GetOperation> batch) {
    var request = new pb.MemcacheGetRequest();
    batch.forEach((operation) => request.key.add(operation.key));
    return _clientRPCStub.Get(request).then((pb.MemcacheGetResponse response) {
      if (response.item.length > request.key.length) {
        throw ProtocolError.INVALID_RESPONSE;
      }
      // The response from the memcache service only have the items which
      // where actually found. The items found are returned in the same order
      // as the keys in the request.
      var result = [];
      int remaining = response.item.length;
      int index = 0;
      for (int i = 0; i < batch.length; i++) {
        if (remaining == 0 ||
            !_sameKey(response.item[index].key, batch[i].key)) {
          // This key had no value found.
          result.add(new raw.GetResult(raw.Status.KEY_NOT_FOUND,
                                       null,
                                       0,
                                       null,
                                       null));
        } else {
          // Value found for key.
          result.add(new raw.GetResult(raw.Status.NO_ERROR,
                                       null,
                                       response.item[index].flags,
                                       null,
                                       response.item[index].value));
          remaining--;
          index++;
        }
      }
      return result;
    });
  }

  Future<List<raw.SetResult>> set(List<raw.SetOperation> batch) {
    var request = new pb.MemcacheSetRequest();
    batch.forEach((operation) {
      var item = new pb.MemcacheSetRequest_Item();
      item.key = operation.key;
      item.value = operation.value;
      switch (operation.operation) {
        case raw.SetOperation.SET:
          item.setPolicy = pb.MemcacheSetRequest_SetPolicy.SET;
          break;
        case raw.SetOperation.ADD:
          item.setPolicy = pb.MemcacheSetRequest_SetPolicy.ADD;
          break;
        case raw.SetOperation.REPLACE:
          item.setPolicy = pb.MemcacheSetRequest_SetPolicy.REPLACE;
          break;
        default:
          throw new UnsupportedError('Unsupported set operation $operation');
      }
      request.item.add(item);
    });
    return _clientRPCStub.Set(request).then((pb.MemcacheSetResponse response) {
      if (response.setStatus.length != request.item.length) {
        throw ProtocolError.INVALID_RESPONSE;
      }
      var result = [];
      response.setStatus.forEach((status) {
        switch (status) {
          case pb.MemcacheSetResponse_SetStatusCode.STORED:
            result.add(new raw.SetResult(raw.Status.NO_ERROR, null));
            break;
          case pb.MemcacheSetResponse_SetStatusCode.NOT_STORED:
            result.add(new raw.SetResult(raw.Status.NOT_STORED, null));
            break;
          case pb.MemcacheSetResponse_SetStatusCode.EXISTS:
            result.add(new raw.SetResult(raw.Status.KEY_EXISTS, null));
            break;
          case pb.MemcacheSetResponse_SetStatusCode.ERROR:
            result.add(new raw.SetResult(raw.Status.ERROR, null));
            break;
          default:
            throw new UnsupportedError('Unsupported set status $status');
        }
      });
      return result;
    });
  }

  Future<List<raw.RemoveResult>> remove(List<raw.RemoveOperation> batch) {
    var request = new pb.MemcacheDeleteRequest();
    batch.forEach((operation) {
      var item = new pb.MemcacheDeleteRequest_Item();
      item.key = operation.key;
      request.item.add(item);
    });
    return _clientRPCStub.Delete(request)
        .then((pb.MemcacheDeleteResponse response) {
          var result = [];
          response.deleteStatus.forEach((status) {
            if (status == pb.MemcacheDeleteResponse_DeleteStatusCode.DELETED) {
              result.add(
                  new raw.RemoveResult(raw.Status.NO_ERROR, null));
            } else if (status ==
                       pb.MemcacheDeleteResponse_DeleteStatusCode.NOT_FOUND) {
              result.add(
                  new raw.RemoveResult(raw.Status.KEY_NOT_FOUND, null));
            } else {
              throw new UnsupportedError('Unsupported delete status $status');
            }
          });
          return result;
    });
  }

  Future clear() {
    var request = new pb.MemcacheFlushRequest();

    return _clientRPCStub.FlushAll(request).then((_) => null);
  }
}
