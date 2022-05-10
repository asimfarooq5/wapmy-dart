import 'dart:io';

import 'package:connectanum/connectanum.dart';
import 'package:connectanum/json.dart';
import 'package:args/args.dart';

void main(List<String> args) async {
  var parser = ArgParser();

  parser.addOption('method', abbr: 'm');
  parser.addOption('realm', abbr: 'r', defaultsTo: 'realm1');
  parser.addOption('url', abbr: 'u', defaultsTo: 'ws://localhost:8080/ws');
  parser.addOption('topic', abbr: 't');
  parser.addOption('args', abbr: 'a', defaultsTo: "");

  var results = parser.parse(args);
  final Client conn = client(results['realm'], results['url']);
  final session = await conn.connect().first;

  switch (results['method']) {
    case 'call':
      call(session, results['topic'], results['args']);
      break;

    case 'register':
      if (!results['args'].isEmpty) {
        print("args not accepted, while registering procedure.");
      } else {
        register(session, results['topic'], results['args']);
      }
      break;
    case 'subscribe':
      if (!results['args'].isEmpty) {
        print("args not accepted while subscribing procedure.");
      }
      subscribe(session, results['topic']);
      break;

    case 'publish':
      publish(session, results['topic'], results['args']);
      break;
  }
}

client(realm, url) {
  final client = Client(
      realm: realm,
      transport: WebSocketTransport(
        url,
        Serializer(),
        WebSocketSerialization.SERIALIZATION_JSON,
      ));
  return client;
}

publish(session, topic, args) async {
  try {
    print('published to ' + topic);
    await session.publish(topic, arguments: [args]);
    await session.close();
  } on Abort catch (abort) {
    print(abort.message!.message);
  }
}

subscribe(session, topic) async {
  print('Subscribed to ' + topic);
  final subscription = await session.subscribe(topic);
  subscription.eventStream!.listen((event) => print(event.arguments![0]));
  await subscription.onRevoke.then((reason) =>
      print('The server has killed my subscription due to: ' + reason));
}

register(session, topic, args) async {
  print('Registered to ' + topic);
  final registered = await session.register(topic);
  registered
      .onInvoke((invocation) => invocation.respondWith(arguments: ["args"]));
}

call(session, topic, args) async {
  print(topic + ' is Called ');
  await session
      .call(topic, arguments: [args]).listen(onResult, onError: onError);
}

onResult(Result result) async {
  if (result.arguments != null) {
    print(result.arguments![0]);
  }
  exit(1);
}

onError(e) {}
