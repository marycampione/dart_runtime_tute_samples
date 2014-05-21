// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library memcache.impl;

import 'dart:async';
import 'dart:convert';

import '../memcache.dart';
import '../memcache_raw.dart' as raw;

class MemCacheImpl implements Memcache {
  raw.RawMemcache _raw;

  MemCacheImpl(this._raw);

  List<int> _createKey(Object key) {
    if (key is String) {
      key = UTF8.encode(key);
    } else {
      if (key is! List<int>) {
        throw new ArgumentError('Key must have type String or List<int>');
      }
    }
    return key;
  }

  List<int> _createValue(Object value) {
    if (value is String) {
      value = UTF8.encode(value);
    } else {
      if (value is! List<int>) {
        throw new ArgumentError('Value must have type String or List<int>');
      }
    }
    return value;
  }

  raw.GetOperation _createGetOperation(Object key) {
    return new raw.GetOperation(_createKey(key));
  }

  raw.SetOperation _createSetOperation(
      Object key, Object value, SetAction action) {
    var operation;
    switch (action) {
      case SetAction.SET: operation = raw.SetOperation.SET; break;
      case SetAction.ADD: operation = raw.SetOperation.ADD; break;
      case SetAction.REPLACE: operation = raw.SetOperation.REPLACE; break;
      default: throw new ArgumentError('Unsupported set action $action');
    }
    return new raw.SetOperation(operation,
                                _createKey(key),
                                0,
                                null,
                                _createValue(value));
  }

  raw.RemoveOperation _createRemoveOperation(Object key) {
    return new raw.RemoveOperation(_createKey(key));
  }

  Future get(Object key, {bool asBinary: false}) {
    return new Future.sync(() => _raw.get([_createGetOperation(key)]))
        .then((List<raw.GetResult> response) {
          if (response.length != 1) {
            throw new MemcacheError(null, 'Internal error');
          }
          var result = response.first;
          if (result.status == raw.Status.KEY_NOT_FOUND) return null;
          return asBinary ? result.value : UTF8.decode(result.value);
        });
  }

  Future<Map> getAll(Iterable keys, {bool asBinary: false}) {
    return new Future.sync(() {
      var keysList = keys is List ? keys : keys.toList();
      var request = new List(keysList.length);
      for (int i = 0; i < keysList.length; i++) {
        request[i] = _createGetOperation(keysList[i]);
      }
      return _raw.get(request).then((List<raw.GetResult> response) {
        if (response.length != request.length) {
          throw new MemcacheError(null, 'Internal error');
        }
        var result = new Map();
        for (int i = 0; i < keysList.length; i++) {
          var value;
          if (response[i].status == raw.Status.KEY_NOT_FOUND) {
            value = null;
          } else {
            value =
                asBinary ? response[i].value : UTF8.decode(response[i].value);
          }
          result[keysList[i]] = value;
        };
        return result;
      });
    });
  }

  Future set(key, value,
             {Duration expiration, SetAction action: SetAction.SET}) {
    return new Future.sync(
        () => _raw.set([_createSetOperation(key, value, action)]))
        .then((List<raw.SetResult> response) {
          if (response.length != 1) {
            // TODO(sgjesse): Improve error.
            throw new MemcacheError(null, 'Internal error');
          }
          var result = response.first;
          if (result.status == raw.Status.NO_ERROR) return null;
          if (result.status == raw.Status.NOT_STORED) {
            throw new NotStored(null);
          }
          throw new MemcacheError(result.status, 'Error storing item');
        });
  }

  Future setAll(Map keysAndValues,
                {Duration expiration, SetAction action: SetAction.SET}) {
    return new Future.sync(() {
      var request = [];
      keysAndValues.forEach((key, value) {
        request.add(_createSetOperation(key, value, action));
      });
      return _raw.set(request)
          .then((List<raw.SetResult> response) {
            if (response.length != request.length) {
              throw new MemcacheError(null, 'Internal error');
            }
            response.forEach((raw.SetResult result) {
              if (result.status == raw.Status.NO_ERROR) return;
              if (result.status == raw.Status.NOT_STORED) {
                // If one element is not stored throw NotStored.
                throw new NotStored(null);
              }
              // If one element has another status throw.
              throw new MemcacheError(result.status, 'Error storing item');
            });
            return null;
          });
    });
  }

  Future remove(key) {
    return new Future.sync(() => _raw.remove([_createRemoveOperation(key)]))
        .then((List<raw.RemoveResult> response) {
          // The remove is considered succesful no matter whether the key was
          // there or not.
          return null;
        });
  }

  Future removeAll(Iterable keys) {
    return new Future.sync(() {
      var request = [];
      keys.forEach((key) {
        request.add(_createRemoveOperation(key));
      });
      return _raw.remove(request).then((List<raw.RemoveResult> response) {
        if (response.length != request.length) {
          throw new MemcacheError(null, 'Internal error');
        }
        // The remove is considered succesful no matter whether the key was
        // there or not.
        return null;
      });
    });
  }

  Future clear({Duration expiration}) {
    return new Future.sync(() => _raw.clear());
  }
}