class TrackedApp {
  final String packageName;
  final String displayName;
  final String? iconBase64;
  final bool isSystem;
  final bool isTracked;

  const TrackedApp({
    required this.packageName,
    required this.displayName,
    this.iconBase64,
    this.isSystem = false,
    this.isTracked = true,
  });

  TrackedApp copyWith({
    String? packageName,
    String? displayName,
    String? iconBase64,
    bool? isSystem,
    bool? isTracked,
  }) {
    return TrackedApp(
      packageName: packageName ?? this.packageName,
      displayName: displayName ?? this.displayName,
      iconBase64: iconBase64 ?? this.iconBase64,
      isSystem: isSystem ?? this.isSystem,
      isTracked: isTracked ?? this.isTracked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'displayName': displayName,
      'iconBase64': iconBase64,
      'isSystem': isSystem ? 1 : 0,
      'isTracked': isTracked ? 1 : 0,
    };
  }

  factory TrackedApp.fromMap(Map<String, dynamic> map) {
    return TrackedApp(
      packageName: (map['packageName'] ?? map['package']) as String,
      displayName: (map['displayName'] ?? map['appName'] ?? map['packageName']) as String,
      iconBase64: map['iconBase64'] as String?,
      isSystem: map['isSystem'] == true || map['isSystem'] == 1,
      isTracked: map['isTracked'] != 0,
    );
  }
}
