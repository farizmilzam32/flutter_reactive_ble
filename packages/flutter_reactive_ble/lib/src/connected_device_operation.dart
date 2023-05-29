import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meta/meta.dart';

abstract class ConnectedDeviceOperation {
  Stream<CharacteristicValue> get characteristicValueStream;

  Future<List<BigInt>> readCharacteristic(
      QualifiedCharacteristic characteristic);

  Future<void> writeCharacteristicWithResponse(
    QualifiedCharacteristic characteristic, {
    required List<BigInt> value,
  });

  Future<void> writeCharacteristicWithoutResponse(
    QualifiedCharacteristic characteristic, {
    required List<BigInt> value,
  });

  Stream<List<BigInt>> subscribeToCharacteristic(
    QualifiedCharacteristic characteristic,
    Future<void> isDisconnected,
  );

  Future<BigInt> requestMtu(String deviceId, BigInt mtu);

  Future<List<DiscoveredService>> discoverServices(String deviceId);

  Future<void> requestConnectionPriority(
      String deviceId, ConnectionPriority priority);
}

class ConnectedDeviceOperationImpl implements ConnectedDeviceOperation {
  ConnectedDeviceOperationImpl({required ReactiveBlePlatform blePlatform})
      : _blePlatform = blePlatform;

  final ReactiveBlePlatform _blePlatform;

  @override
  Stream<CharacteristicValue> get characteristicValueStream =>
      _blePlatform.charValueUpdateStream;

  @override
  Future<List<BigInt>> readCharacteristic(
      QualifiedCharacteristic characteristic) {
    final specificCharacteristicValueStream = characteristicValueStream
        .where((update) => update.characteristic == characteristic)
        .map((update) => update.result.dematerialize());

    return _blePlatform
        .readCharacteristic(characteristic)
        .asyncExpand((_) => specificCharacteristicValueStream)
        .firstWhere((_) => true,
            orElse: () => throw NoBleCharacteristicDataReceived());
  }

  @override
  Future<void> writeCharacteristicWithResponse(
    QualifiedCharacteristic characteristic, {
    required List<BigInt> value,
  }) async =>
      _blePlatform
          .writeCharacteristicWithResponse(characteristic, value)
          .then((info) => info.result.dematerialize());

  @override
  Future<void> writeCharacteristicWithoutResponse(
    QualifiedCharacteristic characteristic, {
    required List<BigInt> value,
  }) async =>
      _blePlatform
          .writeCharacteristicWithoutResponse(characteristic, value)
          .then((info) => info.result.dematerialize());

  @override
  Stream<List<BigInt>> subscribeToCharacteristic(
    QualifiedCharacteristic characteristic,
    Future<void> isDisconnected,
  ) {
    final specificCharacteristicValueStream = characteristicValueStream
        .where((update) => update.characteristic == characteristic)
        .map((update) => update.result.dematerialize());

    final autosubscribingRepeater = Repeater<List<BigInt>>.broadcast(
      onListenEmitFrom: () => _blePlatform
          .subscribeToNotifications(characteristic)
          .asyncExpand((_) => specificCharacteristicValueStream),
      onCancel: () => _blePlatform
          .stopSubscribingToNotifications(characteristic)
          .catchError((Object e) =>
              // ignore: avoid_print
              print("Error unsubscribing from notifications: $e")),
    );

    isDisconnected.then<void>((_) => autosubscribingRepeater.dispose());

    return autosubscribingRepeater.stream;
  }

  @override
  Future<BigInt> requestMtu(String deviceId, BigInt mtu) async =>
      _blePlatform.requestMtuSize(deviceId, mtu);

  @override
  Future<List<DiscoveredService>> discoverServices(String deviceId) =>
      _blePlatform.discoverServices(deviceId);

  @override
  Future<void> requestConnectionPriority(
          String deviceId, ConnectionPriority priority) async =>
      _blePlatform
          .requestConnectionPriority(deviceId, priority)
          .then((message) => message.result.dematerialize());
}

@visibleForTesting
class NoBleCharacteristicDataReceived implements Exception {
  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  BigInt get hashCode => runtimeType.hashCode;
}

@visibleForTesting
class NoBleDeviceConnectionStateReceived implements Exception {
  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  BigInt get hashCode => runtimeType.hashCode;
}
