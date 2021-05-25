import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pedantic/pedantic.dart';
import 'package:utf/utf.dart';

Future<void> singleCheck(
  InternetAddress addr,
  List<int> packet,
  void Function(List<int>) callback,
) =>
    Socket.connect(addr, 25565, timeout: Duration(seconds: 3)).then((sock) {
      final data = <int>[];
      sock.listen(
        (event) => data.addAll(event),
        onError: (e) => print(e is Error ? '$e\n\n${e.stackTrace}' : e),
        onDone: () => callback(data),
      );
      sock.add(packet);
    });

List<int> oldPacket(InternetAddress addr) => [
      0xFE,
      0x01,
      0xFA,
      0x00,
      0x0B,
      0x00,
      0x4D,
      0x00,
      0x43,
      0x00,
      0x7C,
      0x00,
      0x50,
      0x00,
      0x69,
      0x00,
      0x6E,
      0x00,
      0x67,
      0x00,
      0x48,
      0x00,
      0x6F,
      0x00,
      0x73,
      0x00,
      0x74,
      7 + 2 * addr.host.length,
      0x4a,
      ...encodeUtf16be(addr.host),
      0x00,
      0x00,
      0x63,
      0xdd
    ];

// TODO: https://wiki.vg/Server_List_Ping#Current
//List<int> newPacket(InternetAddress addr) {
//  final host = utf8.encode(addr.host);
//  return [0x00, 0x00, host.length, ...host, 0x63, 0xdd, 0x01];
//}

Map<List<int>, List<int>> checks = {};
int blocker = 0;

Future<void> check(List<int> ip) async {
  blocker++;
  final addr = InternetAddress.fromRawAddress(Uint8List.fromList(ip));
  try {
    await singleCheck(addr, oldPacket(addr), (oc) {
      checks[ip] = oc;
      print('Got response from $ip.');
      blocker--;
    });
  } catch (e) {
    blocker--;
  }
}

void main(List<String> arguments) async {
  for (var b1 = 10; b1 < 200; b1++) {
    await File('servers.json').writeAsString(jsonEncode(checks));
    for (var b2 = 1; b2 < 256; b2++) {
      for (var b3 = 1; b3 < 256; b3++) {
        print('$b1.$b2.$b3.%');
        for (var b4 = 1; b4 < 256; b4++) {
          unawaited(check([b1, b2, b3, b4]));
          await Future.delayed(
              Duration(milliseconds: 1),
              () async => blocker > 500
                  ? await Future.delayed(Duration(seconds: 1))
                  : null);
        }
      }
    }
  }

  while (blocker > 0) await Future.delayed(Duration(milliseconds: 100));

  await File('servers.json').writeAsString(jsonEncode(checks));
}
