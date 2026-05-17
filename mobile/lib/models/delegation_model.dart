class DelegationModel {
  final String id;
  final String ownerId;
  final String delegateId;
  final String resourceType; // PLAYLIST, EVENT
  final String resourceId;
  final String permissionLevel; // OWNER, ADMIN, VIEWER
  final bool active;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  DelegationModel({
    required this.id,
    required this.ownerId,
    required this.delegateId,
    required this.resourceType,
    required this.resourceId,
    required this.permissionLevel,
    required this.active,
    this.expiresAt,
    this.createdAt,
  });

  factory DelegationModel.fromJson(Map<String, dynamic> json) {
    return DelegationModel(
      id: json['id'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      delegateId: json['delegateId'] as String? ?? '',
      resourceType: json['resourceType'] as String? ?? '',
      resourceId: json['resourceId'] as String? ?? '',
      permissionLevel: json['permissionLevel'] as String? ?? 'VIEWER',
      active: json['active'] as bool? ?? false,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'delegateId': delegateId,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'permissionLevel': permissionLevel,
      'active': active,
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
