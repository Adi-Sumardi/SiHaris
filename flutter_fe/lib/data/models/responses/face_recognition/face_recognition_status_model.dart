class FaceRecognitionCompanySettings {
  final bool faceRecognitionEnabled;
  final bool livenessRequired;
  final double matchThreshold;

  FaceRecognitionCompanySettings({
    required this.faceRecognitionEnabled,
    required this.livenessRequired,
    required this.matchThreshold,
  });

  factory FaceRecognitionCompanySettings.fromJson(Map<String, dynamic> json) {
    return FaceRecognitionCompanySettings(
      // Support both API field names
      faceRecognitionEnabled: json['face_recognition_enabled'] as bool? ??
                              json['enable_face_recognition'] as bool? ?? false,
      livenessRequired: json['liveness_required'] as bool? ?? false,
      // Default samakan dengan backend (cosine similarity 0.6).
      matchThreshold: (json['match_threshold'] as num?)?.toDouble() ??
                      (json['face_match_threshold'] as num?)?.toDouble() ?? 0.6,
    );
  }
}

class FaceRecognitionStatusModel {
  final bool enrolled;
  final String? enrolledAt;
  final double? qualityScore;
  final FaceRecognitionCompanySettings? companySettings;

  FaceRecognitionStatusModel({
    required this.enrolled,
    this.enrolledAt,
    this.qualityScore,
    this.companySettings,
  });

  factory FaceRecognitionStatusModel.fromJson(Map<String, dynamic> json) {
    return FaceRecognitionStatusModel(
      enrolled: json['enrolled'] as bool? ?? false,
      enrolledAt: json['enrolled_at'] as String?,
      qualityScore: (json['quality_score'] as num?)?.toDouble(),
      companySettings: json['company_settings'] != null
          ? FaceRecognitionCompanySettings.fromJson(
              json['company_settings'] as Map<String, dynamic>)
          : null,
    );
  }
}

class FaceEnrollResponseModel {
  final bool enrolled;
  final double? qualityScore;

  FaceEnrollResponseModel({
    required this.enrolled,
    this.qualityScore,
  });

  factory FaceEnrollResponseModel.fromJson(Map<String, dynamic> json) {
    return FaceEnrollResponseModel(
      enrolled: json['enrolled'] as bool? ?? false,
      qualityScore: (json['quality_score'] as num?)?.toDouble(),
    );
  }
}

class FaceVerifyResponseModel {
  final bool matched;
  final double confidence;

  FaceVerifyResponseModel({
    required this.matched,
    required this.confidence,
  });

  factory FaceVerifyResponseModel.fromJson(Map<String, dynamic> json) {
    return FaceVerifyResponseModel(
      matched: json['matched'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String toConfidencePercentage() => '${(confidence * 100).round()}%';
}
