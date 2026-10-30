import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/gradient_button.dart';

class UrlInputCard extends StatelessWidget {
  const UrlInputCard({
    super.key,
    required this.controller,
    required this.loading,
    required this.onPaste,
    required this.onClear,
    required this.onDownload,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onPaste;
  final VoidCallback onClear;
  final VoidCallback onDownload;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) => TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              minLines: 1,
              maxLines: 3,
              onChanged: (_) => onChanged(),
              onSubmitted: (_) => onDownload(),
              decoration: InputDecoration(
                hintText: 'Paste video link here…',
                prefixIcon: const Icon(Icons.link_rounded),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: onClear),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onPaste,
                icon: const Icon(Icons.content_paste_rounded, size: 18),
                label: const Text('Paste'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  side: BorderSide(color: context.cs.outline),
                  foregroundColor: context.cs.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  label: 'Download',
                  icon: Icons.download_rounded,
                  loading: loading,
                  onPressed: onDownload,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
