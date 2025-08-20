/*
 * Copyright 2025 榆见晴天
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_steps_base.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyStepsBaseAdapter extends TypeAdapter<DailyStepsBase> {
  @override
  final int typeId = 4;

  @override
  DailyStepsBase read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyStepsBase(
      localDay: fields[0] as DateTime,
      baseStepCount: fields[1] as int,
      actualStepCount: fields[2] as int,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DailyStepsBase obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.localDay)
      ..writeByte(1)
      ..write(obj.baseStepCount)
      ..writeByte(2)
      ..write(obj.actualStepCount)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyStepsBaseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
