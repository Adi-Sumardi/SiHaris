class FaceEnrollRequestModel {
  final List<double> descriptors;
  final double? qualityScore;
  final String? photoBase64;

  FaceEnrollRequestModel({
    required this.descriptors,
    this.qualityScore,
    this.photoBase64,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'embedding_data': {
        'version': '1.0',
        'model': 'mobilefacenet-tflite',
        'descriptors': descriptors,
      },
    };

    if (qualityScore != null) {
      json['quality_score'] = qualityScore;
    }

    if (photoBase64 != null) {
      json['photo_base64'] = photoBase64;
    }

    return json;
  }
}
