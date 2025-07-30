// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItineraryAdapter extends TypeAdapter<Itinerary> {
  @override
  final int typeId = 0;

  @override
  Itinerary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Itinerary(
      title: fields[0] as String,
      startDate: fields[1] as DateTime,
      endDate: fields[2] as DateTime,
      days: (fields[3] as List).cast<ItineraryDay>(),
    );
  }

  @override
  void write(BinaryWriter writer, Itinerary obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.startDate)
      ..writeByte(2)
      ..write(obj.endDate)
      ..writeByte(3)
      ..write(obj.days);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItineraryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ItineraryDayAdapter extends TypeAdapter<ItineraryDay> {
  @override
  final int typeId = 1;

  @override
  ItineraryDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItineraryDay(
      date: fields[0] as DateTime,
      summary: fields[1] as String,
      items: (fields[2] as List).cast<ItineraryItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, ItineraryDay obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.summary)
      ..writeByte(2)
      ..write(obj.items);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItineraryDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ItineraryItemAdapter extends TypeAdapter<ItineraryItem> {
  @override
  final int typeId = 2;

  @override
  ItineraryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItineraryItem(
      time: fields[0] as String,
      activity: fields[1] as String,
      location: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ItineraryItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.time)
      ..writeByte(1)
      ..write(obj.activity)
      ..writeByte(2)
      ..write(obj.location);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItineraryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
