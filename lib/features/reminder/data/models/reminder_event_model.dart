import 'package:hive/hive.dart';

import '../../domain/entities/reminder_event.dart';

class ReminderEventModel extends ReminderEvent {
  const ReminderEventModel({
    required super.id,
    required super.title,
    required super.dateTime,
    required super.createdAt,
    super.location,
    super.sourceText,
    super.notificationScheduledAt,
    super.notificationError,
    super.sourceType,
    super.needsConfirmation,
  });

  factory ReminderEventModel.fromEntity(ReminderEvent event) {
    return ReminderEventModel(
      id: event.id,
      title: event.title,
      dateTime: event.dateTime,
      location: event.location,
      createdAt: event.createdAt,
      sourceText: event.sourceText,
      notificationScheduledAt: event.notificationScheduledAt,
      notificationError: event.notificationError,
      sourceType: event.sourceType,
      needsConfirmation: event.needsConfirmation,
    );
  }

  ReminderEvent toEntity() {
    return ReminderEvent(
      id: id,
      title: title,
      dateTime: dateTime,
      location: location,
      createdAt: createdAt,
      sourceText: sourceText,
      notificationScheduledAt: notificationScheduledAt,
      notificationError: notificationError,
      sourceType: sourceType,
      needsConfirmation: needsConfirmation,
    );
  }
}

class ReminderEventModelAdapter extends TypeAdapter<ReminderEventModel> {
  static const int typeIdValue = 1;

  @override
  int get typeId => typeIdValue;

  @override
  ReminderEventModel read(BinaryReader reader) {
    final fields = <int, dynamic>{};
    final count = reader.readByte();
    for (var i = 0; i < count; i++) {
      fields[reader.readByte()] = reader.read();
    }

    return ReminderEventModel(
      id: fields[0] as String,
      title: fields[1] as String,
      dateTime: fields[2] as DateTime,
      location: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      sourceText: fields[5] as String?,
      notificationScheduledAt: fields[6] as DateTime?,
      notificationError: fields[7] as String?,
      sourceType: _sourceTypeFromString(fields[8] as String?),
      needsConfirmation: fields[9] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, ReminderEventModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.dateTime)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.sourceText)
      ..writeByte(6)
      ..write(obj.notificationScheduledAt)
      ..writeByte(7)
      ..write(obj.notificationError)
      ..writeByte(8)
      ..write(obj.sourceType.name)
      ..writeByte(9)
      ..write(obj.needsConfirmation);
  }

  ReminderSourceType _sourceTypeFromString(String? value) {
    return ReminderSourceType.values.firstWhere(
      (ReminderSourceType type) => type.name == value,
      orElse: () => ReminderSourceType.manual,
    );
  }
}
