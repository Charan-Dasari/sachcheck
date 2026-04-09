import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sachcheck/core/theme.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:io';

class ChatroomScreen extends ConsumerStatefulWidget {
  const ChatroomScreen({super.key});

  @override
  ConsumerState<ChatroomScreen> createState() => _ChatroomScreenState();
}

class _ChatroomScreenState extends ConsumerState<ChatroomScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();
  bool _isSendingImage = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _user == null) return;

    _msgCtrl.clear();

    await _firestore.collection('messages').add({
      'text': text,
      'userId': _user!.uid,
      'userName': _user!.displayName ?? 'User',
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
    });

    // Auto-scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut);
      }
    });
  }

  /// Shares a verification result into the chatroom
  Future<void> shareVerification({
    required String headline,
    required String verdict,
    required double score,
  }) async {
    if (_user == null) return;

    await _firestore.collection('messages').add({
      'text': headline,
      'userId': _user!.uid,
      'userName': _user!.displayName ?? 'User',
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'verification_share',
      'verificationData': {
        'headline': headline,
        'verdict': verdict,
        'score': score,
      },
    });
  }

  /// Picks an image and sends it as a message
  Future<void> _pickAndSendImage(ImageSource source) async {
    if (_user == null) return;
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 60,
      maxWidth: 800,
    );
    if (picked == null || !mounted) return;

    setState(() => _isSendingImage = true);

    try {
      // Read and encode as base64
      final bytes = await File(picked.path).readAsBytes();
      final b64 = base64Encode(bytes);

      await _firestore.collection('messages').add({
        'text': '📷 Image',
        'userId': _user!.uid,
        'userName': _user!.displayName ?? 'User',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'image',
        'imageData': b64,
      });

      // Auto-scroll
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send image')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingImage = false);
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surface
          : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Share Media',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: const Color(0xFF6C63FF),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndSendImage(ImageSource.camera);
                    },
                  ),
                  _AttachOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: const Color(0xFF00B4D8),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndSendImage(ImageSource.gallery);
                    },
                  ),
                  _AttachOption(
                    icon: Icons.insert_drive_file_rounded,
                    label: 'Screenshot',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndSendImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : AppColors.lightBackground;
    final surfColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final txtPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final txtSec =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final divColor = isDark ? AppColors.divider : AppColors.lightDivider;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.verified,
              ),
            ),
            const SizedBox(width: 8),
            const Text('News ChatRoom'),
          ],
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('messages').snapshots(),
            builder: (ctx, snap) {
              final count = snap.data?.docs.length ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text('$count msgs',
                      style: TextStyle(fontSize: 11, color: txtSec)),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages List ──────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(200)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('💬', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 16),
                        Text('No messages yet',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: txtPrimary)),
                        const SizedBox(height: 6),
                        Text('Be the first to start the conversation!',
                            style: TextStyle(fontSize: 13, color: txtSec)),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg =
                        messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['userId'] == _user?.uid;
                    final type = msg['type'] ?? 'text';

                    if (type == 'verification_share') {
                      return _VerificationShareBubble(
                        data: msg,
                        isMe: isMe,
                        isDark: isDark,
                        surfColor: surfColor,
                        txtPrimary: txtPrimary,
                        txtSec: txtSec,
                      );
                    }

                    if (type == 'image') {
                      return _ImageBubble(
                        msg: msg,
                        isMe: isMe,
                        isDark: isDark,
                        surfColor: surfColor,
                        txtPrimary: txtPrimary,
                        txtSec: txtSec,
                      );
                    }

                    return _ChatBubble(
                      msg: msg,
                      isMe: isMe,
                      isDark: isDark,
                      surfColor: surfColor,
                      txtPrimary: txtPrimary,
                      txtSec: txtSec,
                    );
                  },
                );
              },
            ),
          ),

          // ── Divider ────────────────────────────────────────────────────
          Divider(height: 1, color: divColor),

          // ── Message Input ──────────────────────────────────────────────
          Container(
            color: surfColor,
            padding: EdgeInsets.fromLTRB(
                16, 8, 8, 8 + MediaQuery.of(context).padding.bottom),
            child: Row(
              children: [
                // Attachment button
                IconButton(
                  onPressed: _isSendingImage ? null : _showAttachmentOptions,
                  icon: _isSendingImage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        )
                      : Icon(Icons.attach_file_rounded,
                          color: txtSec, size: 22),
                ),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: TextStyle(color: txtPrimary, fontSize: 14),
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Share news or ask a question…',
                      hintStyle: TextStyle(color: txtSec, fontSize: 14),
                      filled: true,
                      fillColor: bgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat Message Bubble ────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isMe;
  final bool isDark;
  final Color surfColor;
  final Color txtPrimary;
  final Color txtSec;

  const _ChatBubble({
    required this.msg,
    required this.isMe,
    required this.isDark,
    required this.surfColor,
    required this.txtPrimary,
    required this.txtSec,
  });

  String _getInitial(String name) {
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'now';
    if (timestamp is Timestamp) {
      return timeago.format(timestamp.toDate(), allowFromNow: true);
    }
    return 'now';
  }

  @override
  Widget build(BuildContext context) {
    final name = msg['userName'] ?? 'User';
    final text = msg['text'] ?? '';
    final initial = _getInitial(name);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(initial,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : surfColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe
                    ? null
                    : Border.all(
                        color: isDark
                            ? AppColors.divider
                            : AppColors.lightDivider,
                        width: 0.5),
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(name,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  if (!isMe) const SizedBox(height: 2),
                  Text(text,
                      style: TextStyle(
                          fontSize: 14, color: txtPrimary, height: 1.4)),
                  const SizedBox(height: 4),
                  Text(_formatTime(msg['timestamp']),
                      style: TextStyle(fontSize: 10, color: txtSec)),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Verification Share Bubble ──────────────────────────────────────────────
class _VerificationShareBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMe;
  final bool isDark;
  final Color surfColor;
  final Color txtPrimary;
  final Color txtSec;

  const _VerificationShareBubble({
    required this.data,
    required this.isMe,
    required this.isDark,
    required this.surfColor,
    required this.txtPrimary,
    required this.txtSec,
  });

  Color _verdictColor(String verdict) {
    switch (verdict) {
      case 'verified':
        return AppColors.verified;
      case 'needs_caution':
        return AppColors.caution;
      default:
        return AppColors.notVerified;
    }
  }

  String _verdictLabel(String verdict) {
    switch (verdict) {
      case 'verified':
        return 'Verified ✅';
      case 'needs_caution':
        return 'Needs Caution ⚠️';
      default:
        return 'Not Verified ❌';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = data['userName'] ?? 'User';
    final vData =
        data['verificationData'] as Map<String, dynamic>? ?? {};
    final headline = vData['headline'] ?? '';
    final verdict = vData['verdict'] ?? 'not_verified';
    final score = (vData['score'] ?? 0.0).toDouble();
    final color = _verdictColor(verdict);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(name,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  if (!isMe) const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.fact_check_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text('Verification Shared',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: txtSec)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(headline,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: txtPrimary,
                          height: 1.4)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_verdictLabel(verdict),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ),
                      const Spacer(),
                      Text('${(score * 100).toInt()}% match',
                          style: TextStyle(fontSize: 11, color: txtSec)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Image Message Bubble ───────────────────────────────────────────────────
class _ImageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isMe;
  final bool isDark;
  final Color surfColor;
  final Color txtPrimary;
  final Color txtSec;

  const _ImageBubble({
    required this.msg,
    required this.isMe,
    required this.isDark,
    required this.surfColor,
    required this.txtPrimary,
    required this.txtSec,
  });

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'now';
    if (timestamp is Timestamp) {
      return timeago.format(timestamp.toDate(), allowFromNow: true);
    }
    return 'now';
  }

  @override
  Widget build(BuildContext context) {
    final name = msg['userName'] ?? 'User';
    final b64 = msg['imageData'] as String? ?? '';
    Uint8List? imageBytes;
    try {
      if (b64.isNotEmpty) imageBytes = base64Decode(b64);
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(name,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imageBytes != null
                      ? Image.memory(
                          imageBytes,
                          width: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 220,
                            height: 120,
                            color: surfColor,
                            child: const Center(
                              child: Icon(Icons.broken_image_rounded,
                                  color: Colors.grey),
                            ),
                          ),
                        )
                      : Container(
                          width: 220,
                          height: 120,
                          color: surfColor,
                          child: const Center(
                            child: Icon(Icons.image_not_supported_rounded,
                                color: Colors.grey),
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(_formatTime(msg['timestamp']),
                    style: TextStyle(fontSize: 10, color: txtSec)),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Attachment Option ──────────────────────────────────────────────────────
class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
