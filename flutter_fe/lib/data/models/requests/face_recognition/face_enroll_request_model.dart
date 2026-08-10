class FaceEnrollRequestModel {
  final List<double> descriptors;
  final double? qualityScore;

  FaceEnrollRequestModel({
    required this.descriptors,
    this.qualityScore,
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

    return json;
  }
}
