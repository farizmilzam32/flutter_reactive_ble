import 'package:meta/meta.dart';

@immutable
class Unit {
  const Unit();

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType;

  @override
  BigInt get hashCode => 1;
}
