import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desafio/scr/models/document_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

enum PostDocumentsStatus {
  initial,
  picking,
  selected,
  uploading,
  success,
  error,
}

class PostDocumentsState {
  const PostDocumentsState({
    this.status = PostDocumentsStatus.initial,
    this.selectedFile,
    this.errorMessage,
    this.uploadedDocumentId,
  });

  final PostDocumentsStatus status;
  final PlatformFile? selectedFile;
  final String? errorMessage;
  final String? uploadedDocumentId;

  bool get isPicking => status == PostDocumentsStatus.picking;
  bool get hasFile => selectedFile != null;
  bool get isUploading => status == PostDocumentsStatus.uploading;
  bool get isSuccess => status == PostDocumentsStatus.success;

  PostDocumentsState copyWith({
    PostDocumentsStatus? status,
    PlatformFile? selectedFile,
    String? errorMessage,
    String? uploadedDocumentId,
    bool clearErrorMessage = false,
    bool clearSelectedFile = false,
    bool clearUploadedDocumentId = false,
  }) {
    return PostDocumentsState(
      status: status ?? this.status,
      selectedFile: clearSelectedFile
          ? null
          : (selectedFile ?? this.selectedFile),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      uploadedDocumentId: clearUploadedDocumentId
          ? null
          : (uploadedDocumentId ?? this.uploadedDocumentId),
    );
  }
}

class PostDocumentsController extends Cubit<PostDocumentsState> {
  PostDocumentsController() : super(const PostDocumentsState());

  static const List<String> _allowedExtensions = ['png', 'pdf'];
  static const int _maxFileSizeBytes = 25 * 1024 * 1024; // 25 MB

  /// Magic bytes: %PDF
  static const List<int> _pdfMagic = [0x25, 0x50, 0x44, 0x46];

  /// Magic bytes: \x89PNG\r\n\x1a\n
  static const List<int> _pngMagic = [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ];

  // ── Seleção ──────────────────────────────────────────────────────────────

  Future<void> pickDocument() async {
    emit(
      state.copyWith(
        status: PostDocumentsStatus.picking,
        clearErrorMessage: true,
      ),
    );

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        withData: true,
      );

      final selected = result?.files.single;
      if (selected == null) {
        emit(state.copyWith(status: PostDocumentsStatus.initial));
        return;
      }

      emit(
        state.copyWith(
          status: PostDocumentsStatus.selected,
          selectedFile: selected,
          clearErrorMessage: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: PostDocumentsStatus.error,
          errorMessage:
              'Nao foi possivel selecionar o arquivo. Tente novamente.',
        ),
      );
    }
  }

  // ── Validação de conteúdo ─────────────────────────────────────────────────

  bool _isValidMagicBytes(Uint8List bytes, String extension) {
    final magic = extension == 'pdf' ? _pdfMagic : _pngMagic;
    if (bytes.length < magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) return false;
    }
    return true;
  }

  // ── Upload ────────────────────────────────────────────────────────────────

  Future<void> uploadDocument() async {
    final file = state.selectedFile;
    if (file == null) return;

    final extension = (file.extension ?? '').toLowerCase();

    // 1. Tamanho máximo: 25 MB
    if (file.size > _maxFileSizeBytes) {
      emit(
        state.copyWith(
          status: PostDocumentsStatus.error,
          errorMessage: 'Arquivo excede o limite de 25 MB.',
        ),
      );
      return;
    }

    // 2. Leitura dos bytes (necessária para validação e upload)
    final bytes = file.bytes;
    if (bytes == null) {
      emit(
        state.copyWith(
          status: PostDocumentsStatus.error,
          errorMessage: 'Nao foi possivel ler o arquivo.',
        ),
      );
      return;
    }

    // 3. Validação de magic bytes (independente do MIME informado pelo cliente)
    if (!_isValidMagicBytes(bytes, extension)) {
      emit(
        state.copyWith(
          status: PostDocumentsStatus.error,
          errorMessage: 'Conteudo invalido para o tipo .$extension.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: PostDocumentsStatus.uploading,
        clearErrorMessage: true,
      ),
    );

    try {
      // 4. Extrai texto conforme o tipo
      final rawText = extension == 'pdf'
          ? await _extractPdfText(bytes)
          : await _extractImageText(file.path);

      // 5. Normaliza espaços e quebras de linha
      final normalizedText = _normalizeText(rawText);

      // 6. Identifica padrões estruturados
      final patterns = _findPatterns(normalizedText);

      // 7. Persiste apenas o texto no Firestore
      final now = DateTime.now();
      final docRef = await FirebaseFirestore.instance
          .collection('documents')
          .add(
            DocumentModel(
              id: '',
              fileName: file.name,
              fileType: extension,
              fileSizeBytes: file.size,
              status: 'completed',
              timestamp: now,
              extractedText: normalizedText,
              patterns: patterns.isEmpty ? null : patterns,
            ).toFirestore(),
          );

      emit(
        state.copyWith(
          status: PostDocumentsStatus.success,
          uploadedDocumentId: docRef.id,
          clearErrorMessage: true,
        ),
      );
    } on FirebaseException catch (e) {
      emit(
        state.copyWith(
          status: PostDocumentsStatus.error,
          errorMessage: 'Erro ao salvar: ${e.message ?? 'tente novamente.'}',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: PostDocumentsStatus.error,
          errorMessage: 'Erro ao processar o arquivo. Tente novamente.',
        ),
      );
    }
  }

  // ── Extração de texto ────────────────────────────────────────────

  /// Extrai texto de um PDF usando Syncfusion.
  Future<String> _extractPdfText(Uint8List bytes) async {
    final document = PdfDocument(inputBytes: bytes);
    final text = PdfTextExtractor(document).extractText();
    document.dispose();
    return text;
  }

  /// Extrai texto de uma imagem PNG via Google ML Kit OCR (on-device).
  Future<String> _extractImageText(String? filePath) async {
    if (filePath == null) return '';
    final inputImage = InputImage.fromFilePath(filePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(inputImage);
      return result.text;
    } finally {
      await recognizer.close();
    }
  }

  // ── Processamento de texto ────────────────────────────────────────

  /// Normaliza espaços em branco e quebras de linha excessivas.
  String _normalizeText(String text) => text
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  /// Identifica padrões estruturados no texto:
  /// - datas (dd/mm/aaaa)
  /// - valores monetários (R$ x,xx)
  /// - CPFs (xxx.xxx.xxx-xx)
  /// - CNPJs (xx.xxx.xxx/xxxx-xx)
  Map<String, List<String>> _findPatterns(String text) {
    final matchers = {
      'datas': RegExp(r'\b\d{2}/\d{2}/\d{4}\b'),
      'valores_monetarios': RegExp(r'R\$\s*\d{1,3}(?:\.\d{3})*(?:,\d{2})?'),
      'cpfs': RegExp(r'\b\d{3}\.\d{3}\.\d{3}-\d{2}\b'),
      'cnpjs': RegExp(r'\b\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}\b'),
    };
    final result = <String, List<String>>{};
    for (final entry in matchers.entries) {
      final matches = entry.value
          .allMatches(text)
          .map((m) => m.group(0)!)
          .toSet()
          .toList();
      if (matches.isNotEmpty) result[entry.key] = matches;
    }
    return result;
  }

  // ── Utilitários ──────────────────────────────────────────────────────────

  void clearDocument() {
    emit(
      state.copyWith(
        status: PostDocumentsStatus.initial,
        clearSelectedFile: true,
        clearErrorMessage: true,
        clearUploadedDocumentId: true,
      ),
    );
  }

  String formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
