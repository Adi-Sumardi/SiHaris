import 'dart:io';

class UpdateProfileRequestModel {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? address;
  final File? photo;

  UpdateProfileRequestModel({
    this.firstName,
    this.lastName,
    this.phone,
    this.address,
    this.photo,
  });

  /// Returns form fields (String values only) for multipart/form-data request.
  /// Only includes non-null fields. Matches PATCH /auth/profile API.
  Map<String, String> toFields() {
    final fields = <String, String>{};
    if (firstName != null) fields['first_name'] = firstName!;
    if (lastName != null) fields['last_name'] = lastName!;
    if (phone != null) fields['phone'] = phone!;
    if (address != null) fields['address'] = address!;
    return fields;
  }

  bool get hasPhoto => photo != null;
}
