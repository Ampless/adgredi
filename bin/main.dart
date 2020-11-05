import 'dart:io';

import 'dart:typed_data';

import 'package:utf/utf.dart';

void singleCheck(
  InternetAddress addr,
  List<int> packet,
  void Function(List<int>) callback,
) {
  Socket.connect(addr, 25565).then((sock) {
    var data = <int>[];
    sock.listen(
      (event) => data.addAll(event),
      onError: (e) => print(e is Error ? '$e\n\n${e.stackTrace}' : e),
      onDone: () => callback(data),
    );
    sock.add(packet);
  });
}

List<int> oldPacket(InternetAddress addr) {
  var l = [
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
    0x74
  ];
  l.add(7 + 2 * addr.host.length);
  l.add(0x4a);
  l.addAll(encodeUtf16be(addr.host));
  l.addAll([0x00, 0x00, 0x63, 0xdd]);
  return l;
}

List<int> newPacket(InternetAddress addr) {
  var l = [0x00, 0x00];
  final host = encodeUtf8(addr.host);
  l.add(host.length);
  l.addAll(host);
  l.addAll([0x63, 0xdd, 0x01]);
  return l;
}

Map<int, List<int>> oldChecks = {};
Map<int, List<int>> newChecks = {};

void check(List<int> ip) {
  final addr = InternetAddress.fromRawAddress(Uint8List.fromList(ip));
  singleCheck(addr, oldPacket(addr), (oldCheck) {
    oldChecks[1] = oldCheck;
    Future.delayed(
      Duration(seconds: 1),
      () => singleCheck(addr, newPacket(addr), (newCheck) {
        newChecks[1] = newCheck;
      }),
    );
  });
}

void checkThing() {
  Future.delayed(Duration(milliseconds: 100), () {
    if (newChecks.isEmpty)
      checkThing();
    else {
      print(decodeUtf8(oldChecks[1]));
      print(decodeUtf8(newChecks[1]));
    }
  });
}

void main(List<String> arguments) async {
  check([212, 224, 77, 85]); //this is just gommehd.net, it works.
  checkThing();
}
