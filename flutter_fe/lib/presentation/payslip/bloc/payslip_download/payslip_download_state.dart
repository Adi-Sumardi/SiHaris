part of 'payslip_download_bloc.dart';

abstract class PayslipDownloadState {
  const PayslipDownloadState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayslipDownloadState && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class PayslipDownloadInitial extends PayslipDownloadState {}

class PayslipDownloadLoading extends PayslipDownloadState {}

class PayslipDownloadSuccess extends PayslipDownloadState {
  final PayslipDownloadModel download;

  const PayslipDownloadSuccess(this.download);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PayslipDownloadSuccess && other.download == download;
  }

  @override
  int get hashCode => download.hashCode;
}

class PayslipDownloadError extends PayslipDownloadState {
  final String message;

  const PayslipDownloadError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PayslipDownloadError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
