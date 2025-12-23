// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TacheAdapter extends TypeAdapter<Tache> {
  @override
  final int typeId = 2;

  @override
  Tache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Tache(
      id: fields[0] as String,
      titre: fields[1] as String,
      description: fields[2] as String?,
      estCompletee: fields[3] as bool,
      sousTaches: (fields[4] as List?)?.cast<SousTache>(),
      checklist: (fields[5] as List?)?.cast<String>(),
      dateCreation: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Tache obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.titre)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.estCompletee)
      ..writeByte(4)
      ..write(obj.sousTaches)
      ..writeByte(5)
      ..write(obj.checklist)
      ..writeByte(6)
      ..write(obj.dateCreation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
