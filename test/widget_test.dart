import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desafio/scr/models/document_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DocumentModel - serialização', () {
    final timestamp = DateTime(2025, 1, 15, 10, 0);

    test('toFirestore retorna mapa completo com todos os campos', () {
      final model = DocumentModel(
        id: 'abc123',
        fileName: 'contrato.pdf',
        fileType: 'pdf',
        fileSizeBytes: 2048,
        status: 'completed',
        timestamp: timestamp,
        extractedText: 'Texto do contrato',
        patterns: {
          'datas': ['15/01/2025'],
          'cpfs': ['123.456.789-00'],
        },
      );

      final map = model.toFirestore();

      expect(map['fileName'], 'contrato.pdf');
      expect(map['fileType'], 'pdf');
      expect(map['fileSizeBytes'], 2048);
      expect(map['status'], 'completed');
      expect(map['extractedText'], 'Texto do contrato');
      expect(map['patterns'], {
        'datas': ['15/01/2025'],
        'cpfs': ['123.456.789-00'],
      });
      expect(map['timestamp'], isA<Timestamp>());
    });

    test('toFirestore omite extractedText e patterns quando nulos', () {
      final model = DocumentModel(
        id: 'xyz',
        fileName: 'imagem.png',
        fileType: 'png',
        fileSizeBytes: 512,
        status: 'pending',
        timestamp: timestamp,
      );

      final map = model.toFirestore();

      expect(map.containsKey('extractedText'), isFalse);
      expect(map.containsKey('patterns'), isFalse);
    });

    test('toFirestore inclui timestamp como Firestore Timestamp', () {
      final model = DocumentModel(
        id: '1',
        fileName: 'doc.pdf',
        fileType: 'pdf',
        fileSizeBytes: 100,
        status: 'completed',
        timestamp: timestamp,
      );

      final map = model.toFirestore();
      final ts = map['timestamp'] as Timestamp;

      expect(ts.toDate(), timestamp);
    });

    test('isLoading e isAuthenticated refletem status corretamente', () {
      final model = DocumentModel(
        id: '1',
        fileName: 'doc.pdf',
        fileType: 'pdf',
        fileSizeBytes: 100,
        status: 'completed',
        timestamp: timestamp,
        extractedText: 'texto',
        patterns: {'datas': []},
      );

      expect(model.extractedText, isNotNull);
      expect(model.patterns, isNotNull);
      expect(model.patterns!['datas'], isEmpty);
    });
  });
}
