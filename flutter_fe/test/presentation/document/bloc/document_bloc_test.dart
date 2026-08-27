import 'dart:io';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaji_pro/data/datasources/employee_document_remote_datasource.dart';
import 'package:gaji_pro/data/models/requests/upload_document_request_model.dart';
import 'package:gaji_pro/data/models/responses/employee_document_model.dart';
import 'package:gaji_pro/presentation/document/bloc/document_action/document_action_bloc.dart';
import 'package:gaji_pro/presentation/document/bloc/document_list/document_list_bloc.dart';
import 'package:gaji_pro/presentation/document/bloc/document_upload/document_upload_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockEmployeeDocumentRemoteDatasource extends Mock
    implements EmployeeDocumentRemoteDatasource {}

class FakeUploadDocumentRequestModel extends Fake
    implements UploadDocumentRequestModel {}

class FakeFile extends Fake implements File {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUploadDocumentRequestModel());
    registerFallbackValue(FakeFile());
  });

  late MockEmployeeDocumentRemoteDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockEmployeeDocumentRemoteDatasource();
  });

  const tDocuments = [
    EmployeeDocumentModel(
      id: 1,
      documentType: 'sk',
      documentTypeLabel: 'SK / Surat Keputusan',
      documentName: 'SK Guru Tetap Yayasan 2026',
      documentNumber: '800/10/YAPI/2026',
      fileName: 'sk.pdf',
      fileSize: 102400,
      humanFileSize: '100 KB',
      mimeType: 'application/pdf',
      isImage: false,
      isPdf: true,
    ),
  ];

  const tTypes = [
    DocumentTypeModel(
      type: 'sk',
      label: 'SK / Surat Keputusan',
      icon: 'description',
    ),
  ];

  group('DocumentListBloc', () {
    late DocumentListBloc bloc;

    setUp(() {
      bloc = DocumentListBloc(datasource: mockDatasource);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state should be DocumentListInitial', () {
      expect(bloc.state, equals(DocumentListInitial()));
    });

    blocTest<DocumentListBloc, DocumentListState>(
      'emits [DocumentListLoading, DocumentListLoaded] when GetDocuments succeeds',
      build: () {
        when(() => mockDatasource.getDocumentTypes())
            .thenAnswer((_) async => tTypes);
        when(() => mockDatasource.getDocuments(
              type: any(named: 'type'),
              search: any(named: 'search'),
            )).thenAnswer((_) async => tDocuments);
        return bloc;
      },
      act: (bloc) => bloc.add(const GetDocuments()),
      expect: () => [
        isA<DocumentListLoading>(),
        isA<DocumentListLoaded>()
            .having((s) => s.documents.length, 'documents.length', 1)
            .having((s) => s.types.length, 'types.length', 1),
      ],
    );

    blocTest<DocumentListBloc, DocumentListState>(
      'emits [DocumentListLoading, DocumentListError] when GetDocuments fails',
      build: () {
        when(() => mockDatasource.getDocumentTypes())
            .thenAnswer((_) async => tTypes);
        when(() => mockDatasource.getDocuments(
              type: any(named: 'type'),
              search: any(named: 'search'),
            )).thenThrow(Exception('Gagal memuat berkas'));
        return bloc;
      },
      act: (bloc) => bloc.add(const GetDocuments()),
      expect: () => [
        isA<DocumentListLoading>(),
        isA<DocumentListError>()
            .having((s) => s.message, 'message', 'Gagal memuat berkas'),
      ],
    );
  });

  group('DocumentUploadBloc', () {
    late DocumentUploadBloc bloc;

    setUp(() {
      bloc = DocumentUploadBloc(datasource: mockDatasource);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state should be DocumentUploadInitial', () {
      expect(bloc.state, equals(DocumentUploadInitial()));
    });

    blocTest<DocumentUploadBloc, DocumentUploadState>(
      'emits [DocumentUploadLoading, DocumentUploadSuccess] when uploadDocument succeeds',
      build: () {
        when(() => mockDatasource.uploadDocument(any(), any()))
            .thenAnswer((_) async => tDocuments.first);
        return bloc;
      },
      act: (bloc) => bloc.add(UploadDocument(
        request: const UploadDocumentRequestModel(
          documentType: 'sk',
          documentName: 'SK Guru',
        ),
        file: FakeFile(),
      )),
      expect: () => [
        isA<DocumentUploadLoading>(),
        isA<DocumentUploadSuccess>()
            .having((s) => s.document.id, 'document.id', 1),
      ],
    );
  });

  group('DocumentActionBloc', () {
    late DocumentActionBloc bloc;

    setUp(() {
      bloc = DocumentActionBloc(datasource: mockDatasource);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state should be DocumentActionInitial', () {
      expect(bloc.state, equals(DocumentActionInitial()));
    });

    blocTest<DocumentActionBloc, DocumentActionState>(
      'emits [DocumentActionLoading, DocumentActionDeleteSuccess] when deleteDocument succeeds',
      build: () {
        when(() => mockDatasource.deleteDocument(1))
            .thenAnswer((_) async => true);
        return bloc;
      },
      act: (bloc) => bloc.add(const DeleteDocumentEvent(1)),
      expect: () => [
        isA<DocumentActionLoading>(),
        isA<DocumentActionDeleteSuccess>().having((s) => s.id, 'id', 1),
      ],
    );
  });
}
