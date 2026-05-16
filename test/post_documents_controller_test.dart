import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:desafio/scr/controlers/post_documents_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

/// Magic bytes corretos para testes de arquivos válidos.
final _pdfMagic = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]); // %PDF
final _pngMagic = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
]); // \x89PNG...

void main() {
  group('PostDocumentsController - validações de upload', () {
    // ── Sem arquivo selecionado ──────────────────────────────────────────────

    blocTest<PostDocumentsController, PostDocumentsState>(
      'não emite estados quando nenhum arquivo está selecionado',
      build: () => PostDocumentsController(),
      act: (cubit) => cubit.uploadDocument(),
      expect: () => [],
    );

    // ── Tamanho > 25 MB ──────────────────────────────────────────────────────

    blocTest<PostDocumentsController, PostDocumentsState>(
      'emite erro quando arquivo excede 25 MB',
      build: () => PostDocumentsController(),
      seed: () => PostDocumentsState(
        status: PostDocumentsStatus.selected,
        selectedFile: PlatformFile(
          name: 'grande.pdf',
          size: 30 * 1024 * 1024,
          bytes: Uint8List(0),
        ),
      ),
      act: (cubit) => cubit.uploadDocument(),
      expect: () => [
        isA<PostDocumentsState>()
            .having((s) => s.status, 'status', PostDocumentsStatus.error)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Arquivo excede o limite de 25 MB.',
            ),
      ],
    );

    // ── Bytes nulos ──────────────────────────────────────────────────────────

    blocTest<PostDocumentsController, PostDocumentsState>(
      'emite erro quando bytes do arquivo são nulos',
      build: () => PostDocumentsController(),
      seed: () => PostDocumentsState(
        status: PostDocumentsStatus.selected,
        selectedFile: PlatformFile(
          name: 'sem_dados.pdf',
          size: 100,
          // bytes: null (padrão)
        ),
      ),
      act: (cubit) => cubit.uploadDocument(),
      expect: () => [
        isA<PostDocumentsState>()
            .having((s) => s.status, 'status', PostDocumentsStatus.error)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Nao foi possivel ler o arquivo.',
            ),
      ],
    );

    // ── Magic bytes inválidos — PDF ──────────────────────────────────────────

    blocTest<PostDocumentsController, PostDocumentsState>(
      'emite erro quando magic bytes do PDF são inválidos',
      build: () => PostDocumentsController(),
      seed: () => PostDocumentsState(
        status: PostDocumentsStatus.selected,
        selectedFile: PlatformFile(
          name: 'falso.pdf',
          size: 4,
          bytes: Uint8List.fromList([0x00, 0x00, 0x00, 0x00]),
        ),
      ),
      act: (cubit) => cubit.uploadDocument(),
      expect: () => [
        isA<PostDocumentsState>()
            .having((s) => s.status, 'status', PostDocumentsStatus.error)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Conteudo invalido para o tipo .pdf.',
            ),
      ],
    );

    // ── Magic bytes inválidos — PNG ──────────────────────────────────────────

    blocTest<PostDocumentsController, PostDocumentsState>(
      'emite erro quando magic bytes do PNG são inválidos',
      build: () => PostDocumentsController(),
      seed: () => PostDocumentsState(
        status: PostDocumentsStatus.selected,
        selectedFile: PlatformFile(
          name: 'falso.png',
          size: 8,
          bytes: Uint8List.fromList([
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
          ]),
        ),
      ),
      act: (cubit) => cubit.uploadDocument(),
      expect: () => [
        isA<PostDocumentsState>()
            .having((s) => s.status, 'status', PostDocumentsStatus.error)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Conteudo invalido para o tipo .png.',
            ),
      ],
    );

    // ── Magic bytes corretos (PDF) — passa validação, falha no Firebase ──────

    blocTest<PostDocumentsController, PostDocumentsState>(
      'emite uploading e depois erro de processamento para PDF com magic bytes válidos mas conteúdo corrompido',
      build: () => PostDocumentsController(),
      seed: () => PostDocumentsState(
        status: PostDocumentsStatus.selected,
        selectedFile: PlatformFile(
          name: 'corrompido.pdf',
          size: 4,
          bytes: _pdfMagic,
        ),
      ),
      act: (cubit) => cubit.uploadDocument(),
      expect: () => [
        isA<PostDocumentsState>().having(
          (s) => s.status,
          'status',
          PostDocumentsStatus.uploading,
        ),
        isA<PostDocumentsState>().having(
          (s) => s.status,
          'status',
          PostDocumentsStatus.error,
        ),
      ],
    );
  });

  group('PostDocumentsController - seleção de arquivo', () {
    // ── Estado inicial ───────────────────────────────────────────────────────

    test('estado inicial é PostDocumentsStatus.initial', () {
      final controller = PostDocumentsController();
      expect(controller.state.status, PostDocumentsStatus.initial);
      expect(controller.state.selectedFile, isNull);
      expect(controller.state.errorMessage, isNull);
      controller.close();
    });

    test('hasFile retorna false quando nenhum arquivo selecionado', () {
      final controller = PostDocumentsController();
      expect(controller.state.hasFile, isFalse);
      controller.close();
    });

    test('isUploading retorna false no estado inicial', () {
      final controller = PostDocumentsController();
      expect(controller.state.isUploading, isFalse);
      controller.close();
    });
  });
}
