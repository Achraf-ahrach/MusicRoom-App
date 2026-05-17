import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/delegation_model.dart';

class DelegationService {
  String get _effectiveBaseUrl {
    final url = dotenv.env['API_URL'];
    if (url != null && url.isNotEmpty) {
      if (url.contains('localhost') && !kIsWeb && Platform.isAndroid) {
        return url.replaceAll('localhost', '10.0.2.2');
      }
      return url;
    }
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  static const String _delegationsPath = '/api/delegations';

  /// POST - Create delegation (add-delegation)
  Future<DelegationModel> createDelegation({
    required String delegateId,
    required String resourceId,
    required String resourceType, // PLAYLIST, EVENT
    required String permissionLevel, // OWNER, ADMIN, VIEWER
    required String token,
    DateTime? expiresAt,
  }) async {
    final url = Uri.parse('$_effectiveBaseUrl$_delegationsPath/add-delegation');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode({
        'delegateId': delegateId,
        'resourceId': resourceId,
        'resourceType': resourceType,
        'permissionLevel': permissionLevel,
        if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return DelegationModel.fromJson(decoded);
    } else {
      throw Exception('Failed to create delegation: ${response.statusCode} - ${response.body}');
    }
  }

  /// GET - Get all delegations for a resource
  Future<List<DelegationModel>> getDelegations({
    required String resourceId,
    required String resourceType,
    required String token,
  }) async {
    final url = Uri.parse('$_effectiveBaseUrl$_delegationsPath/resource/$resourceId?type=$resourceType');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((item) => DelegationModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch delegations: ${response.statusCode}');
    }
  }

  /// GET - Get all delegations received by a user
  Future<List<DelegationModel>> getUserDelegations(String token) async {
    final url = Uri.parse('$_effectiveBaseUrl$_delegationsPath/my-delegations');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((item) => DelegationModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch user delegations: ${response.statusCode}');
    }
  }

  /// POST - Check if user has access to a resource
  Future<Map<String, dynamic>> checkAccess({
    required String resourceId,
    required String resourceType,
    required String token,
  }) async {
    final url = Uri.parse('$_effectiveBaseUrl$_delegationsPath/check-access');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode({
        'resourceId': resourceId,
        'resourceType': resourceType,
      }),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to check access: ${response.statusCode}');
    }
  }

  /// GET - Get user's permission level for a resource
  Future<Map<String, dynamic>> getPermissionLevel({
    required String resourceId,
    required String resourceType,
    required String token,
  }) async {
    final url = Uri.parse('$_effectiveBaseUrl$_delegationsPath/permission-level?resourceId=$resourceId&type=$resourceType');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch permission level: ${response.statusCode}');
    }
  }

  /// PUT - Update permission level for a delegation
  Future<DelegationModel> updatePermission({
    required String delegationId,
    required String permissionLevel,
    required String token,
  }) async {
    final url = Uri.parse('$_effectiveBaseUrl$_delegationsPath/$delegationId');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode({
        'permissionLevel': permissionLevel,
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return DelegationModel.fromJson(decoded);
    } else {
      throw Exception('Failed to update permission: ${response.statusCode}');
    }
  }

  /// DELETE - Remove delegation
  Future<void> removeDelegation({
    required String delegationId,
    required String token,
  }) async {
    final url = Uri.parse('$_effectiveBaseUrl$_delegationsPath/$delegationId');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to remove delegation: ${response.statusCode}');
    }
  }
}
