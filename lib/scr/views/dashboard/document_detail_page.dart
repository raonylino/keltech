import 'package:desafio/scr/models/document_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DocumentDetailPage extends StatelessWidget {
  const DocumentDetailPage({super.key, required this.document});

  final DocumentModel document;

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y às $h:$min';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  // ── Rótulos dos padrões ───────────────────────────────────────────────────

  static const _patternLabels = <String, (String, Color)>{
    'datas': ('Datas', Color(0xFF1D4ED8)),
    'valores_monetarios': ('Valores', Color(0xFF15803D)),
    'cpfs': ('CPFs', Color(0xFF7C3AED)),
    'cnpjs': ('CNPJs', Color(0xFFB45309)),
  };

  @override
  Widget build(BuildContext context) {
    final hasText =
        document.extractedText != null && document.extractedText!.isNotEmpty;
    final hasPatterns =
        document.patterns != null && document.patterns!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(document.fileName, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (hasText)
            IconButton(
              tooltip: 'Copiar texto',
              icon: const Icon(Icons.copy_rounded),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: document.extractedText!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Texto copiado!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Metadados ─────────────────────────────────────────────────
            _InfoCard(
              icon: document.fileType == 'pdf'
                  ? Icons.picture_as_pdf_rounded
                  : Icons.image_rounded,
              iconColor: document.fileType == 'pdf'
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF7C3AED),
              items: [
                ('Arquivo', document.fileName),
                ('Tipo', document.fileType.toUpperCase()),
                ('Tamanho', _formatSize(document.fileSizeBytes)),
                ('Enviado em', _formatDate(document.timestamp)),
                ('Status', document.status),
              ],
            ),
            const SizedBox(height: 20),

            // ── Padrões identificados ──────────────────────────────────────
            if (hasPatterns) ...[
              const _SectionTitle('Padrões identificados'),
              const SizedBox(height: 10),
              ...document.patterns!.entries.map((entry) {
                final label = _patternLabels[entry.key];
                final name = label?.$1 ?? entry.key;
                final color = label?.$2 ?? const Color(0xFF475569);
                return _PatternGroup(
                  label: name,
                  color: color,
                  values: entry.value,
                );
              }),
              const SizedBox(height: 20),
            ],

            // ── Texto extraído ─────────────────────────────────────────────
            const _SectionTitle('Texto extraído'),
            const SizedBox(height: 10),

            if (hasText)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                // SelectableText preserva \n e espaços exatamente como
                // foram armazenados no Firestore.
                child: SelectableText(
                  document.extractedText!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.65,
                    letterSpacing: 0.1,
                    color: Color(0xFF1E293B),
                    fontFamily: 'monospace',
                  ),
                ),
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.text_snippet_outlined,
                        size: 48,
                        color: Color(0xFF94A3B8),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Nenhum texto foi extraído deste documento.',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E293B),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.items,
  });

  final IconData icon;
  final Color iconColor;
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF374151),
                          ),
                          children: [
                            TextSpan(
                              text: '${item.$1}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            TextSpan(text: item.$2),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternGroup extends StatelessWidget {
  const _PatternGroup({
    required this.label,
    required this.color,
    required this.values,
  });

  final String label;
  final Color color;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: values
                .map(
                  (v) => Chip(
                    label: Text(
                      v,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: color.withValues(alpha: 0.08),
                    side: BorderSide(color: color.withValues(alpha: 0.25)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
