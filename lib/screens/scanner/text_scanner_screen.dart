import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sachcheck/core/theme.dart';
import 'package:sachcheck/services/ocr_service.dart';

/// Google Lens-like text scanner: shows the image with selectable text
/// block overlays. Users can tap blocks to select text, copy it,
/// or send it to the verification headline box.
class TextScannerScreen extends StatefulWidget {
  final String imagePath;
  final String? rawText;

  const TextScannerScreen({
    super.key,
    required this.imagePath,
    this.rawText,
  });

  @override
  State<TextScannerScreen> createState() => _TextScannerScreenState();
}

class _TextScannerScreenState extends State<TextScannerScreen> {
  OcrScanResult? _scanResult;
  bool _isLoading = true;
  final Set<int> _selectedIndexes = {};
  final TransformationController _transformCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    _scan();
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final ocr = OcrService();
    try {
      final result = await ocr.extractAllBlocks(widget.imagePath);
      if (mounted) {
        setState(() {
          _scanResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  String _getSelectedText() {
    if (_scanResult == null) return '';
    final sorted = _selectedIndexes.toList()..sort();
    return sorted.map((i) => _scanResult!.blocks[i].text).join('\n');
  }

  void _toggleBlock(int index) {
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else {
        _selectedIndexes.add(index);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIndexes.length == (_scanResult?.blocks.length ?? 0)) {
        _selectedIndexes.clear();
      } else {
        for (int i = 0; i < (_scanResult?.blocks.length ?? 0); i++) {
          _selectedIndexes.add(i);
        }
      }
    });
  }

  void _copySelected() {
    final text = _getSelectedText();
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Text copied to clipboard ✓',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _useAsHeadline() {
    final text = _getSelectedText();
    if (text.isEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final txtPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final txtSec =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final divColor = isDark ? AppColors.divider : AppColors.lightDivider;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Text'),
        actions: [
          if (_scanResult != null && _scanResult!.blocks.isNotEmpty)
            TextButton(
              onPressed: _selectAll,
              child: Text(
                _selectedIndexes.length == _scanResult!.blocks.length
                    ? 'Deselect All'
                    : 'Select All',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Scanning text blocks…',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            )
          : _scanResult == null || _scanResult!.blocks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('😕', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      const Text('No text blocks detected',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      const Text('The image may be too blurry or not contain text',
                          style: TextStyle(color: Colors.white60, fontSize: 13)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // ── Image with text block overlays ───────────────────
                    Expanded(
                      child: InteractiveViewer(
                        transformationController: _transformCtrl,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                // The image
                                Image.file(
                                  File(widget.imagePath),
                                  width: constraints.maxWidth,
                                  fit: BoxFit.fitWidth,
                                ),
                                // Overlay text blocks
                                ..._buildBlockOverlays(constraints.maxWidth),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    // ── Bottom panel ─────────────────────────────────────
                    Container(
                      color: surfColor,
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Selected text preview
                            if (_selectedIndexes.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                constraints:
                                    const BoxConstraints(maxHeight: 100),
                                child: SingleChildScrollView(
                                  child: Text(
                                    _getSelectedText(),
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: txtPrimary,
                                        height: 1.4),
                                  ),
                                ),
                              ),
                              Divider(height: 1, color: divColor),
                            ],
                            // Action buttons
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  Text(
                                    '${_selectedIndexes.length} block${_selectedIndexes.length == 1 ? '' : 's'} selected',
                                    style: TextStyle(
                                        fontSize: 12, color: txtSec),
                                  ),
                                  const Spacer(),
                                  if (_selectedIndexes.isNotEmpty) ...[
                                    _ActionChip(
                                      icon: Icons.copy_rounded,
                                      label: 'Copy',
                                      onTap: _copySelected,
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionChip(
                                      icon: Icons.verified_rounded,
                                      label: 'Use as Headline',
                                      isPrimary: true,
                                      onTap: _useAsHeadline,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  List<Widget> _buildBlockOverlays(double viewWidth) {
    if (_scanResult == null) return [];

    final scale = viewWidth / _scanResult!.imageWidth;
    final blocks = _scanResult!.blocks;

    return List.generate(blocks.length, (i) {
      final block = blocks[i];
      final isSelected = _selectedIndexes.contains(i);
      final r = block.rect;

      return Positioned(
        left: r.left * scale,
        top: r.top * scale,
        width: r.width * scale,
        height: r.height * scale,
        child: GestureDetector(
          onTap: () => _toggleBlock(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );
    });
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isPrimary ? Colors.white : AppColors.primary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPrimary ? Colors.white : AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
