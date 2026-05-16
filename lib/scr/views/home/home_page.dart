import 'package:desafio/scr/controlers/post_documents_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PostDocumentsController, PostDocumentsState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) {
        final message = state.errorMessage;
        if (message == null) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
      child: BlocBuilder<PostDocumentsController, PostDocumentsState>(
        builder: (context, state) {
          final controller = context.read<PostDocumentsController>();
          final selectedFile = state.selectedFile;
          final hasFile = state.hasFile;

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'Desafio da Kel Tech',
                style: TextStyle(
                  color: Color(0xFF0F766E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEEF6FF),
                    Color(0xFFE8FFF4),
                    Color(0xFFFFF7E8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x19000000),
                                  blurRadius: 24,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Upload inteligente',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Envie seu arquivo de forma simples e segura.\nFormatos permitidos: XML, PNG e PDF.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF4B5563),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: hasFile
                                        ? const Color(0xFFF0FDF4)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: hasFile
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFD1D5DB),
                                      width: 1.3,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: hasFile
                                              ? const Color(0xFFDCFCE7)
                                              : const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Icon(
                                          hasFile
                                              ? Icons.check_rounded
                                              : Icons.upload_file_rounded,
                                          color: hasFile
                                              ? const Color(0xFF15803D)
                                              : const Color(0xFF334155),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              selectedFile?.name ??
                                                  'Nenhum arquivo selecionado',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF111827),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              hasFile
                                                  ? '${selectedFile!.extension?.toUpperCase() ?? '-'} • ${controller.formatFileSize(selectedFile.size)}'
                                                  : 'Toque no botao abaixo para escolher um arquivo.',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // ── Botão selecionar (oculto durante upload/sucesso) ──
                                if (!state.isUploading && !state.isSuccess)
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF0F766E,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      onPressed: state.isPicking
                                          ? null
                                          : controller.pickDocument,
                                      icon: state.isPicking
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.attach_file_rounded,
                                            ),
                                      label: Text(
                                        state.isPicking
                                            ? 'Selecionando...'
                                            : 'Selecionar arquivo',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),

                                // ── Botão enviar (visível quando arquivo selecionado) ──
                                if (state.status ==
                                    PostDocumentsStatus.selected) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1D4ED8,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      onPressed: controller.uploadDocument,
                                      icon: const Icon(
                                        Icons.cloud_upload_rounded,
                                      ),
                                      label: const Text(
                                        'Enviar arquivo',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                // ── Progresso de upload ───────────────────────────────
                                if (state.isUploading) ...[
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Processando documento...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      minHeight: 8,
                                      backgroundColor: const Color(0xFFE2E8F0),
                                      valueColor: const AlwaysStoppedAnimation(
                                        Color(0xFF0F766E),
                                      ),
                                    ),
                                  ),
                                ],

                                // ── Card de sucesso ───────────────────────────────────
                                if (state.isSuccess) ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFF16A34A),
                                        width: 1.3,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFF15803D),
                                          size: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Arquivo enviado com sucesso!',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF15803D),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'ID: ${state.uploadedDocumentId}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF4B5563),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (state.isSuccess) ...[
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () => Navigator.pushNamed(
                                          context,
                                          '/dashboard',
                                        ),
                                        icon: const Icon(
                                          Icons.list_alt_rounded,
                                        ),
                                        label: const Text(
                                          'Ver documentos salvos',
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF0F766E,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFF0F766E),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],

                                // ── Ação remover / novo upload ────────────────────────
                                if (hasFile && !state.isUploading) ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: controller.clearDocument,
                                      icon: Icon(
                                        state.isSuccess
                                            ? Icons.add_circle_outline
                                            : Icons.delete_outline,
                                      ),
                                      label: Text(
                                        state.isSuccess
                                            ? 'Novo upload'
                                            : 'Remover arquivo',
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
