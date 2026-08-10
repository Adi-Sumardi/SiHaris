class PayslipDownloadModel {
  final String downloadUrl;
  final String filename;

  const PayslipDownloadModel({
    required this.downloadUrl,
    required this.filename,
  });

  factory PayslipDownloadModel.fromJson(Map<String, dynamic> json) {
    return PayslipDownloadModel(
      downloadUrl: json['download_url'],
      filename: json['filename'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'download_url': downloadUrl, 'filename': filename};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PayslipDownloadModel &&
        other.downloadUrl == downloadUrl &&
        other.filename == filename;
  }

  @override
  int get hashCode {
    return downloadUrl.hashCode ^ filename.hashCode;
  }
}
