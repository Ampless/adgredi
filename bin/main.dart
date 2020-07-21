import 'dart:io';

import 'dart:typed_data';

import 'package:utf/utf.dart';

Future<List<int>> singleCheck(InternetAddress addr, List<int> packet) async {
  var data = <int>[];
  var sock = await Socket.connect(addr, 25565);
  var eror = false;
  sock.listen((event) {
    data.addAll(event);
  }, onError: (err) {
    eror = true;
    print(err);
  });
  sock.write(packet);
  await sock.flush();
  await sock.close();
  return eror ? null : data;
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
  var host = encodeUtf8(addr.host);
  l.add(host.length);
  l.addAll(host);
  l.addAll([0x63, 0xdd, 0x01]);
  return l;
}

Future<List<int>> check(List<int> ip) async {
  var addr = InternetAddress.fromRawAddress(Uint8List.fromList(ip));
  var oldCheck = await singleCheck(addr, oldPacket(addr));
  if (oldCheck != null) return oldCheck;
  return singleCheck(addr, newPacket(addr));
}

void main(List<String> arguments) async {
  print(await check([127, 0, 0, 1]));
}
