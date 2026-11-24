import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:filmo/core/network/api_failure.dart';
import 'package:filmo/core/network/dio_client.dart';
import 'package:filmo/features/household/domain/household_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'household_repository.g.dart';

class HouseholdRepository {
  HouseholdRepository(this._dio);

  final Dio _dio;

  Future<List<HouseholdEntry>?> householdCollection() async {
    try {
      final response = await _dio.get<List<dynamic>>('/household');
      return response.data!
          .map((res) => HouseholdEntry.fromJson(res as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiFailure.fromDio(e);
    }
  }

  Future<HouseholdEntry?> createHousehold(String name) async {
    try {
      final response = await _dio.post('/household', data: {"name": name});
      return HouseholdEntry.fromJson(response.data! as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> deleteHousehold(String householdId) async {
    try {
      _dio.delete('/household/${Uri.encodeComponent(householdId)}');
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> joinHousehold(String inviteCode) async {
    try {
      _dio.post('household/${Uri.encodeComponent(inviteCode)}/join');
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> leaveHousehold(String householdId) async {
    try {
      _dio.delete('/household/${Uri.encodeComponent(householdId)}/leave');
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}

@Riverpod(keepAlive: true)
HouseholdRepository householdRepository(Ref ref) =>
    HouseholdRepository(ref.watch(dioProvider));
