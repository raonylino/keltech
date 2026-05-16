import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa um registro de documento no Firestore.
///
/// Status possíveis: pending | processing | completed | error
class DocumentModel {
  const DocumentModel({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileSizeBytes,
    required this.status,
    required this.timestamp,
    this.extractedText,
    this.patterns,
  });

  final String id;
  final String fileName;

  /// Extensão sem ponto: pdf | png
  final String fileType;
  final int fileSizeBytes;

  final String status;
  final DateTime timestamp;

  /// Texto extraído do documento (preenchido após processamento).
  final String? extractedText;

  /// Padrões identificados agrupados por categoria, ex:
  /// { 'datas': ['01/01/2025'], 'cpfs': ['123.456.789-00'] }
  final Map<String, List<String>>? patterns;

  Map<String, dynamic> toFirestore() => {
    'fileName': fileName,
    'fileType': fileType,
    'fileSizeBytes': fileSizeBytes,
    'status': status,
    'timestamp': Timestamp.fromDate(timestamp),
    if (extractedText != null) 'extractedText': extractedText,
    if (patterns != null) 'patterns': patterns,
  };

  factory DocumentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return DocumentModel(
      id: doc.id,
      fileName: data['fileName'] as String,
      fileType: data['fileType'] as String,
      fileSizeBytes: data['fileSizeBytes'] as int,
      status: data['status'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      extractedText: data['extractedText'] as String?,
      patterns: (data['patterns'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, List<String>.from(value as List)),
      ),
    );
  }
}
