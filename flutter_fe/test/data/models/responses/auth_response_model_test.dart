import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/models/responses/auth_response_model.dart';

void main() {
  group('UserModel', () {
    test('should create instance with required fields', () {
      final user = UserModel(
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
      );

      expect(user.id, 1);
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
    });

    test('fromJson should parse correctly', () {
      final json = {
        'id': 1,
        'name': 'John Doe',
        'email': 'john@example.com',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 1);
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
    });

    test('fromJson should handle null values with defaults', () {
      final json = {
        'id': 1,
        'name': null,
        'email': null,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 1);
      expect(user.name, '');
      expect(user.email, '');
    });

    test('toJson should return correct map', () {
      final user = UserModel(
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
      );

      final json = user.toJson();

      expect(json['id'], 1);
      expect(json['name'], 'John Doe');
      expect(json['email'], 'john@example.com');
    });

    test('equality should work correctly', () {
      final user1 = UserModel(id: 1, name: 'John', email: 'john@test.com');
      final user2 = UserModel(id: 1, name: 'John', email: 'john@test.com');
      final user3 = UserModel(id: 2, name: 'Jane', email: 'jane@test.com');

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });

    test('hashCode should be consistent with equality', () {
      final user1 = UserModel(id: 1, name: 'John', email: 'john@test.com');
      final user2 = UserModel(id: 1, name: 'John', email: 'john@test.com');

      expect(user1.hashCode, equals(user2.hashCode));
    });
  });

  group('EmployeeModel', () {
    test('should create instance with required fields', () {
      final employee = EmployeeModel(
        id: 1,
        employeeId: 'EMP001',
        fullName: 'John Doe',
      );

      expect(employee.id, 1);
      expect(employee.employeeId, 'EMP001');
      expect(employee.fullName, 'John Doe');
      expect(employee.faceEnrolled, false); // default value
    });

    test('should create instance with all fields', () {
      final faceEmbedding = FaceEmbeddingModel(
        model: 'google_mlkit',
        version: '1.0.0',
        embedding: List.generate(128, (i) => i * 0.01),
      );

      final employee = EmployeeModel(
        id: 1,
        employeeId: 'EMP001',
        fullName: 'John Doe',
        firstName: 'John',
        lastName: 'Doe',
        phone: '08123456789',
        photo: 'photo.jpg',
        department: 'Engineering',
        position: 'Developer',
        hireDate: '2024-01-01',
        employmentStatus: 'permanent',
        faceEnrolled: true,
        faceEmbedding: faceEmbedding,
      );

      expect(employee.firstName, 'John');
      expect(employee.lastName, 'Doe');
      expect(employee.phone, '08123456789');
      expect(employee.photo, 'photo.jpg');
      expect(employee.department, 'Engineering');
      expect(employee.position, 'Developer');
      expect(employee.hireDate, '2024-01-01');
      expect(employee.employmentStatus, 'permanent');
      expect(employee.faceEnrolled, true);
      expect(employee.faceEmbedding, isNotNull);
      expect(employee.faceEmbedding!.model, 'google_mlkit');
      expect(employee.faceEmbedding!.embedding.length, 128);
    });

    test('fromJson should parse correctly', () {
      final json = {
        'id': 1,
        'employee_id': 'EMP001',
        'full_name': 'John Doe',
        'first_name': 'John',
        'last_name': 'Doe',
        'phone': '08123456789',
        'photo': 'photo.jpg',
        'department': 'Engineering',
        'position': 'Developer',
        'hire_date': '2024-01-01',
        'employment_status': 'permanent',
        'face_enrolled': true,
        'face_embedding': {
          'model': 'google_mlkit',
          'version': '1.0.0',
          'embedding': List.generate(128, (i) => i * 0.01),
        },
      };

      final employee = EmployeeModel.fromJson(json);

      expect(employee.id, 1);
      expect(employee.employeeId, 'EMP001');
      expect(employee.fullName, 'John Doe');
      expect(employee.firstName, 'John');
      expect(employee.lastName, 'Doe');
      expect(employee.department, 'Engineering');
      expect(employee.position, 'Developer');
      expect(employee.faceEnrolled, true);
      expect(employee.faceEmbedding, isNotNull);
      expect(employee.faceEmbedding!.model, 'google_mlkit');
      expect(employee.faceEmbedding!.version, '1.0.0');
      expect(employee.faceEmbedding!.embedding.length, 128);
    });

    test('fromJson should handle face_enrolled false', () {
      final json = {
        'id': 1,
        'employee_id': 'EMP001',
        'full_name': 'John Doe',
        'face_enrolled': false,
      };

      final employee = EmployeeModel.fromJson(json);

      expect(employee.faceEnrolled, false);
      expect(employee.faceEmbedding, isNull);
    });

    test('fromJson should handle face_embedding as empty array without crashing', () {
      final json = {
        'id': 1,
        'employee_id': 'EMP001',
        'full_name': 'John Doe',
        'face_enrolled': true,
        'face_embedding': [],
      };

      final employee = EmployeeModel.fromJson(json);

      expect(employee.faceEnrolled, true);
      expect(employee.faceEmbedding, isNull);
    });

    test('fromJson should handle null values', () {
      final json = {
        'id': 1,
        'employee_id': null,
        'full_name': null,
      };

      final employee = EmployeeModel.fromJson(json);

      expect(employee.id, 1);
      expect(employee.employeeId, '');
      expect(employee.fullName, '');
      expect(employee.firstName, isNull);
      expect(employee.lastName, isNull);
    });

    test('toJson should return correct map', () {
      final faceEmbedding = FaceEmbeddingModel(
        model: 'google_mlkit',
        version: '1.0.0',
        embedding: [0.1, 0.2, 0.3],
      );

      final employee = EmployeeModel(
        id: 1,
        employeeId: 'EMP001',
        fullName: 'John Doe',
        firstName: 'John',
        lastName: 'Doe',
        department: 'Engineering',
        position: 'Developer',
        faceEnrolled: true,
        faceEmbedding: faceEmbedding,
      );

      final json = employee.toJson();

      expect(json['id'], 1);
      expect(json['employee_id'], 'EMP001');
      expect(json['full_name'], 'John Doe');
      expect(json['first_name'], 'John');
      expect(json['last_name'], 'Doe');
      expect(json['department'], 'Engineering');
      expect(json['position'], 'Developer');
      expect(json['face_enrolled'], true);
      expect(json['face_embedding'], isNotNull);
      expect(json['face_embedding']['model'], 'google_mlkit');
    });

    test('toJson should handle null face_embedding', () {
      final employee = EmployeeModel(
        id: 1,
        employeeId: 'EMP001',
        fullName: 'John Doe',
        faceEnrolled: false,
      );

      final json = employee.toJson();

      expect(json['face_enrolled'], false);
      expect(json['face_embedding'], isNull);
    });

    test('should create instance with assigned_offices', () {
      final offices = [
        AssignedOfficeModel(
          id: 1,
          name: 'Kantor Pusat',
          latitude: -6.2088,
          longitude: 106.8456,
          isPrimary: true,
        ),
        AssignedOfficeModel(
          id: 2,
          name: 'Kantor Cabang',
          latitude: -6.9175,
          longitude: 107.6191,
        ),
      ];

      final employee = EmployeeModel(
        id: 1,
        employeeId: 'EMP001',
        fullName: 'John Doe',
        assignedOffices: offices,
      );

      expect(employee.assignedOffices.length, 2);
      expect(employee.assignedOffices[0].name, 'Kantor Pusat');
      expect(employee.primaryOffice?.name, 'Kantor Pusat');
    });

    test('fromJson should parse assigned_offices correctly', () {
      final json = {
        'id': 1,
        'employee_id': 'EMP001',
        'full_name': 'John Doe',
        'assigned_offices': [
          {
            'id': 1,
            'name': 'Kantor Pusat',
            'code': 'HQ',
            'latitude': -6.2088,
            'longitude': 106.8456,
            'radius': 100,
            'is_primary': true,
          },
          {
            'id': 2,
            'name': 'Kantor Cabang',
            'code': 'CB01',
            'latitude': -6.9175,
            'longitude': 107.6191,
            'radius': 150,
            'is_primary': false,
          },
        ],
      };

      final employee = EmployeeModel.fromJson(json);

      expect(employee.assignedOffices.length, 2);
      expect(employee.assignedOffices[0].name, 'Kantor Pusat');
      expect(employee.assignedOffices[0].isPrimary, true);
      expect(employee.assignedOffices[1].name, 'Kantor Cabang');
      expect(employee.primaryOffice?.id, 1);
    });

    test('primaryOffice should return first office if no primary is set', () {
      final offices = [
        AssignedOfficeModel(
          id: 1,
          name: 'Kantor A',
          latitude: -6.2088,
          longitude: 106.8456,
          isPrimary: false,
        ),
        AssignedOfficeModel(
          id: 2,
          name: 'Kantor B',
          latitude: -6.9175,
          longitude: 107.6191,
          isPrimary: false,
        ),
      ];

      final employee = EmployeeModel(
        id: 1,
        employeeId: 'EMP001',
        fullName: 'John Doe',
        assignedOffices: offices,
      );

      expect(employee.primaryOffice?.id, 1); // returns first office
    });

    test('primaryOffice should return null if no offices assigned', () {
      final employee = EmployeeModel(
        id: 1,
        employeeId: 'EMP001',
        fullName: 'John Doe',
      );

      expect(employee.primaryOffice, isNull);
    });

    test('toJson should include assigned_offices', () {
      final offices = [
        AssignedOfficeModel(
          id: 1,
          name: 'Kantor Pusat',
          latitude: -6.2088,
          longitude: 106.8456,
          isPrimary: true,
        ),
      ];

      final employee = EmployeeModel(
        id: 1,
        employeeId: 'EMP001',
        fullName: 'John Doe',
        assignedOffices: offices,
      );

      final json = employee.toJson();

      expect(json['assigned_offices'], isNotNull);
      expect(json['assigned_offices'].length, 1);
      expect(json['assigned_offices'][0]['name'], 'Kantor Pusat');
    });
  });

  group('FaceEmbeddingModel', () {
    test('should create instance with all fields', () {
      final embedding = FaceEmbeddingModel(
        model: 'google_mlkit',
        version: '1.0.0',
        embedding: [0.1, 0.2, 0.3, 0.4, 0.5],
      );

      expect(embedding.model, 'google_mlkit');
      expect(embedding.version, '1.0.0');
      expect(embedding.embedding.length, 5);
      expect(embedding.embedding[0], 0.1);
    });

    test('fromJson should parse correctly', () {
      final json = {
        'model': 'tflite',
        'version': '2.0.0',
        'embedding': [0.5, 0.6, 0.7],
      };

      final embedding = FaceEmbeddingModel.fromJson(json);

      expect(embedding.model, 'tflite');
      expect(embedding.version, '2.0.0');
      expect(embedding.embedding.length, 3);
    });

    test('fromJson should handle integer embedding values', () {
      final json = {
        'model': 'google_mlkit',
        'version': '1.0.0',
        'embedding': [1, 2, 3], // integers instead of doubles
      };

      final embedding = FaceEmbeddingModel.fromJson(json);

      expect(embedding.embedding[0], 1.0);
      expect(embedding.embedding[1], 2.0);
      expect(embedding.embedding[2], 3.0);
    });

    test('toJson should return correct map', () {
      final embedding = FaceEmbeddingModel(
        model: 'google_mlkit',
        version: '1.0.0',
        embedding: [0.1, 0.2, 0.3],
      );

      final json = embedding.toJson();

      expect(json['model'], 'google_mlkit');
      expect(json['version'], '1.0.0');
      expect(json['embedding'], [0.1, 0.2, 0.3]);
    });
  });

  group('AssignedOfficeModel', () {
    test('should create instance with required fields', () {
      final office = AssignedOfficeModel(
        id: 1,
        name: 'Kantor Pusat',
        latitude: -6.2088,
        longitude: 106.8456,
      );

      expect(office.id, 1);
      expect(office.name, 'Kantor Pusat');
      expect(office.latitude, -6.2088);
      expect(office.longitude, 106.8456);
      expect(office.radius, 100); // default
      expect(office.isPrimary, false); // default
    });

    test('should create instance with all fields', () {
      final office = AssignedOfficeModel(
        id: 1,
        name: 'Kantor Pusat',
        code: 'HQ',
        latitude: -6.2088,
        longitude: 106.8456,
        radius: 150,
        isPrimary: true,
      );

      expect(office.code, 'HQ');
      expect(office.radius, 150);
      expect(office.isPrimary, true);
    });

    test('fromJson should parse correctly', () {
      final json = {
        'id': 1,
        'name': 'Kantor Cabang',
        'code': 'CB01',
        'latitude': -6.9175,
        'longitude': 107.6191,
        'radius': 200,
        'is_primary': true,
      };

      final office = AssignedOfficeModel.fromJson(json);

      expect(office.id, 1);
      expect(office.name, 'Kantor Cabang');
      expect(office.code, 'CB01');
      expect(office.latitude, -6.9175);
      expect(office.longitude, 107.6191);
      expect(office.radius, 200);
      expect(office.isPrimary, true);
    });

    test('toJson should return correct map', () {
      final office = AssignedOfficeModel(
        id: 1,
        name: 'Kantor Pusat',
        code: 'HQ',
        latitude: -6.2088,
        longitude: 106.8456,
        radius: 150,
        isPrimary: true,
      );

      final json = office.toJson();

      expect(json['id'], 1);
      expect(json['name'], 'Kantor Pusat');
      expect(json['code'], 'HQ');
      expect(json['latitude'], -6.2088);
      expect(json['longitude'], 106.8456);
      expect(json['radius'], 150);
      expect(json['is_primary'], true);
    });
  });

  group('CompanyModel', () {
    test('should create instance with required fields', () {
      final company = CompanyModel(
        id: 1,
        name: 'PT Jago Gaji',
      );

      expect(company.id, 1);
      expect(company.name, 'PT Jago Gaji');
      expect(company.logo, isNull);
      expect(company.enableFaceRecognition, false); // default value
      expect(company.faceMatchThreshold, 0.48); // default value
      expect(company.enableGpsValidation, true); // default value
    });

    test('should create instance with all fields', () {
      final company = CompanyModel(
        id: 1,
        name: 'PT Jago Gaji',
        logo: 'logo.png',
        enableFaceRecognition: true,
        faceMatchThreshold: 0.8,
        enableGpsValidation: false,
      );

      expect(company.id, 1);
      expect(company.name, 'PT Jago Gaji');
      expect(company.logo, 'logo.png');
      expect(company.enableFaceRecognition, true);
      expect(company.faceMatchThreshold, 0.8);
      expect(company.enableGpsValidation, false);
    });

    test('fromJson should parse correctly', () {
      final json = {
        'id': 1,
        'name': 'PT Jago Gaji',
        'logo': 'logo.png',
        'enable_face_recognition': true,
        'face_match_threshold': 0.75,
        'enable_gps_validation': true,
      };

      final company = CompanyModel.fromJson(json);

      expect(company.id, 1);
      expect(company.name, 'PT Jago Gaji');
      expect(company.logo, 'logo.png');
      expect(company.enableFaceRecognition, true);
      expect(company.faceMatchThreshold, 0.75);
      expect(company.enableGpsValidation, true);
    });

    test('fromJson should handle null values with defaults', () {
      final json = {
        'id': 1,
        'name': null,
        'logo': null,
        'enable_face_recognition': null,
        'face_match_threshold': null,
        'enable_gps_validation': null,
      };

      final company = CompanyModel.fromJson(json);

      expect(company.id, 1);
      expect(company.name, '');
      expect(company.logo, isNull);
      expect(company.enableFaceRecognition, false);
      expect(company.faceMatchThreshold, 0.6);
      expect(company.enableGpsValidation, true);
    });

    test('fromJson should handle integer threshold', () {
      final json = {
        'id': 1,
        'name': 'PT Jago Gaji',
        'face_match_threshold': 1, // integer instead of double
      };

      final company = CompanyModel.fromJson(json);

      expect(company.faceMatchThreshold, 1.0);
    });

    test('toJson should return correct map', () {
      final company = CompanyModel(
        id: 1,
        name: 'PT Jago Gaji',
        logo: 'logo.png',
        enableFaceRecognition: true,
        faceMatchThreshold: 0.85,
        enableGpsValidation: false,
      );

      final json = company.toJson();

      expect(json['id'], 1);
      expect(json['name'], 'PT Jago Gaji');
      expect(json['logo'], 'logo.png');
      expect(json['enable_face_recognition'], true);
      expect(json['face_match_threshold'], 0.85);
      expect(json['enable_gps_validation'], false);
    });
  });

  group('AuthResponseModel', () {
    test('should create instance with required fields', () {
      final response = AuthResponseModel(
        success: true,
      );

      expect(response.success, true);
      expect(response.message, isNull);
      expect(response.token, isNull);
      expect(response.user, isNull);
    });

    test('should create instance with all fields', () {
      final user = UserModel(id: 1, name: 'John', email: 'john@test.com');
      final employee = EmployeeModel(
        id: 1,
        employeeId: 'EMP001',
        fullName: 'John Doe',
      );
      final company = CompanyModel(id: 1, name: 'PT Jago Gaji');

      final response = AuthResponseModel(
        success: true,
        message: 'Login berhasil',
        token: 'jwt-token-123',
        user: user,
        employee: employee,
        company: company,
      );

      expect(response.success, true);
      expect(response.message, 'Login berhasil');
      expect(response.token, 'jwt-token-123');
      expect(response.user, user);
      expect(response.employee, employee);
      expect(response.company, company);
    });

    test('fromJson should parse nested data structure', () {
      final json = {
        'success': true,
        'message': 'Login berhasil',
        'data': {
          'token': 'jwt-token-123',
          'user': {
            'id': 1,
            'name': 'John Doe',
            'email': 'john@example.com',
          },
          'employee': {
            'id': 1,
            'employee_id': 'EMP001',
            'full_name': 'John Doe',
            'department': 'Engineering',
            'position': 'Developer',
          },
          'company': {
            'id': 1,
            'name': 'PT Jago Gaji',
            'logo': 'logo.png',
          },
        },
      };

      final response = AuthResponseModel.fromJson(json);

      expect(response.success, true);
      expect(response.message, 'Login berhasil');
      expect(response.token, 'jwt-token-123');
      expect(response.user?.id, 1);
      expect(response.user?.name, 'John Doe');
      expect(response.employee?.employeeId, 'EMP001');
      expect(response.employee?.department, 'Engineering');
      expect(response.company?.name, 'PT Jago Gaji');
    });

    test('fromJson should parse flat structure (legacy)', () {
      final json = {
        'success': true,
        'message': 'Login berhasil',
        'token': 'jwt-token-123',
        'user': {
          'id': 1,
          'name': 'John Doe',
          'email': 'john@example.com',
        },
      };

      final response = AuthResponseModel.fromJson(json);

      expect(response.success, true);
      expect(response.token, 'jwt-token-123');
      expect(response.user?.id, 1);
    });

    test('fromJson should handle missing data', () {
      final json = {
        'success': false,
        'message': 'Invalid credentials',
      };

      final response = AuthResponseModel.fromJson(json);

      expect(response.success, false);
      expect(response.message, 'Invalid credentials');
      expect(response.token, isNull);
      expect(response.user, isNull);
      expect(response.employee, isNull);
      expect(response.company, isNull);
    });

    test('fromJson should handle null success with default false', () {
      final json = <String, dynamic>{};

      final response = AuthResponseModel.fromJson(json);

      expect(response.success, false);
    });

    test('toJson should return correct nested structure', () {
      final user = UserModel(id: 1, name: 'John', email: 'john@test.com');
      final employee = EmployeeModel(
        id: 1,
        employeeId: 'EMP001',
        fullName: 'John Doe',
      );
      final company = CompanyModel(id: 1, name: 'PT Jago Gaji');

      final response = AuthResponseModel(
        success: true,
        message: 'Login berhasil',
        token: 'jwt-token-123',
        user: user,
        employee: employee,
        company: company,
      );

      final json = response.toJson();

      expect(json['success'], true);
      expect(json['message'], 'Login berhasil');
      expect(json['data']['token'], 'jwt-token-123');
      expect(json['data']['user']['id'], 1);
      expect(json['data']['employee']['employee_id'], 'EMP001');
      expect(json['data']['company']['name'], 'PT Jago Gaji');
    });

    test('equality should work correctly', () {
      final user = UserModel(id: 1, name: 'John', email: 'john@test.com');

      final response1 = AuthResponseModel(
        success: true,
        message: 'OK',
        token: 'token123',
        user: user,
      );
      final response2 = AuthResponseModel(
        success: true,
        message: 'OK',
        token: 'token123',
        user: user,
      );
      final response3 = AuthResponseModel(
        success: false,
        message: 'Failed',
      );

      expect(response1, equals(response2));
      expect(response1, isNot(equals(response3)));
    });

    test('hashCode should be consistent with equality', () {
      final user = UserModel(id: 1, name: 'John', email: 'john@test.com');

      final response1 = AuthResponseModel(
        success: true,
        message: 'OK',
        token: 'token123',
        user: user,
      );
      final response2 = AuthResponseModel(
        success: true,
        message: 'OK',
        token: 'token123',
        user: user,
      );

      expect(response1.hashCode, equals(response2.hashCode));
    });
  });
}
