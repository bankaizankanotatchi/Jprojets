// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'information.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InformationAdapter extends TypeAdapter<Information> {
  @override
  final int typeId = 4;

  @override
  Information read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Information(
      id: fields[0] as String,
      titre: fields[1] as String,
      points: (fields[2] as List).cast<String>(),
      images: (fields[3] as List?)?.cast<String>(),
      dateCreation: fields[4] as DateTime,
      dateModification: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Information obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.titre)
      ..writeByte(2)
      ..write(obj.points)
      ..writeByte(3)
      ..write(obj.images)
      ..writeByte(4)
      ..write(obj.dateCreation)
      ..writeByte(5)
      ..write(obj.dateModification);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InformationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
