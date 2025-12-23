// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'projet.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjetAdapter extends TypeAdapter<Projet> {
  @override
  final int typeId = 1;

  @override
  Projet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Projet(
      id: fields[0] as String,
      titre: fields[1] as String,
      description: fields[2] as String?,
      images: (fields[3] as List?)?.cast<String>(),
      statut: fields[4] as String,
      taches: (fields[5] as List).cast<Tache>(),
      dateCreation: fields[6] as DateTime,
      dateModification: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Projet obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.titre)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.images)
      ..writeByte(4)
      ..write(obj.statut)
      ..writeByte(5)
      ..write(obj.taches)
      ..writeByte(6)
      ..write(obj.dateCreation)
      ..writeByte(7)
      ..write(obj.dateModification);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
