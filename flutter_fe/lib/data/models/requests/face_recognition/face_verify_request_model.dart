enum VerificationType { clockIn, clockOut }

class FaceVerifyRequestModel {
  final List<double> descriptors;
  final VerificationType? verificationType;

  FaceVerifyRequestModel({
    required this.descriptors,
    this.verificationType,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'descriptors': descriptors,
    };

    if (verificationType != null) {
      json['verification_type'] = verificationType == VerificationType.clockIn
          ? 'clock_in'
          : 'clock_out';
    }

    return json;
  }
}
