// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sous_tache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SousTacheAdapter extends TypeAdapter<SousTache> {
  @override
  final int typeId = 3;

  @override
  SousTache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SousTache(
      id: fields[0] as String,
      titre: fields[1] as String,
      estCompletee: fields[2] as bool,
      dateCreation: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SousTache obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.titre)
      ..writeByte(2)
      ..write(obj.estCompletee)
      ..writeByte(3)
      ..write(obj.dateCreation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SousTacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
