import 'package:desafio/scr/controlers/get_documents_controller.dart';
import 'package:desafio/scr/models/document_model.dart';
import 'package:desafio/scr/views/dashboard/document_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<GetDocumentsController>().fetchDocuments();
  }

  static String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} às $h:$min';
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GetDocumentsController, GetDocumentsState>(
      listenWhen: (prev, curr) =>
          curr.deleteError != null && prev.deleteError != curr.deleteError,
      listener: (_, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.deleteError!),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Documentos salvos'),
          backgroundColor: const Color(0xFF0F766E),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            BlocBuilder<GetDocumentsController, GetDocumentsState>(
              builder: (context, state) => IconButton(
                tooltip: 'Atualizar',
                icon: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
                onPressed: state.isLoading
                    ? null
                    : () => context
                          .read<GetDocumentsController>()
                          .fetchDocuments(),
              ),
            ),
          ],
        ),
        body: BlocBuilder<GetDocumentsController, GetDocumentsState>(
          builder: (context, state) {
            // ── Carregando ──────────────────────────────────────────────────
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF0F766E)),
              );
            }

            // ── Erro ────────────────────────────────────────────────────────
            if (state.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: Color(0xFFDC2626),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.errorMessage ?? 'Erro desconhecido.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF374151)),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => context
                            .read<GetDocumentsController>()
                            .fetchDocuments(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tentar novamente'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // ── Vazio ────────────────────────────────────────────────────────
            if (state.documents.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 56,
                      color: Color(0xFF94A3B8),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Nenhum documento salvo ainda.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                    ),
                  ],
                ),
              );
            }

            // ── Estatísticas ─────────────────────────────────────────────────
            final total = state.documents.length;
            final pdfCount = state.documents
                .where((d) => d.fileType == 'pdf')
                .length;
            final pngCount = state.documents
                .where((d) => d.fileType == 'png')
                .length;
            final lastUpload = _formatDate(state.documents.first.timestamp);

            // ── Lista com header ─────────────────────────────────────────────
            return CustomScrollView(
              slivers: [
                // Card de resumo
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _StatsCard(
                      total: total,
                      pdfCount: pdfCount,
                      pngCount: pngCount,
                      lastUpload: lastUpload,
                    ),
                  ),
                ),

                // Cabeçalho da lista
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'Todos os documentos',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),

                // Lista de documentos
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: state.documents.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final doc = state.documents[index];
                      return _DocumentCard(
                        document: doc,
                        formattedDate: _formatDate(doc.timestamp),
                        formattedSize: _formatSize(doc.fileSizeBytes),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DocumentDetailPage(document: doc),
                          ),
                        ),
                        onDelete: () => context
                            .read<GetDocumentsController>()
                            .deleteDocument(doc.id),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Card de estatísticas ──────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.total,
    required this.pdfCount,
    required this.pngCount,
    required this.lastUpload,
  });

  final int total;
  final int pdfCount;
  final int pngCount;
  final String lastUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatBox(
                label: 'Total',
                value: '$total',
                icon: Icons.description_rounded,
              ),
              const SizedBox(width: 10),
              _StatBox(
                label: 'PDF',
                value: '$pdfCount',
                icon: Icons.picture_as_pdf_rounded,
              ),
              const SizedBox(width: 10),
              _StatBox(
                label: 'PNG',
                value: '$pngCount',
                icon: Icons.image_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: Colors.white60,
              ),
              const SizedBox(width: 6),
              Text(
                'Último upload: $lastUpload',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card do documento na lista ────────────────────────────────────────────────

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.formattedDate,
    required this.formattedSize,
    required this.onTap,
    required this.onDelete,
  });

  final DocumentModel document;
  final String formattedDate;
  final String formattedSize;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar documento?'),
        content: Text(
          'O registro "${document.fileName}" será removido permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = document.fileType == 'pdf';
    final iconColor = isPdf ? const Color(0xFFDC2626) : const Color(0xFF7C3AED);
    final icon = isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded;
    final hasText =
        document.extractedText != null && document.extractedText!.isNotEmpty;

    final preview = hasText
        ? document.extractedText!
              .split('\n')
              .map((l) => l.trim())
              .firstWhere((l) => l.isNotEmpty, orElse: () => '')
        : 'Sem texto extraído';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ícone do tipo
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),

              // Conteúdo central
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome do arquivo
                    Text(
                      document.fileName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Prévia do texto
                    Text(
                      preview,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Data e tamanho
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.data_usage_rounded,
                          size: 12,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedSize,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Ações
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Apagar',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                    onPressed: () => _confirmDelete(context),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFCBD5E1),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
