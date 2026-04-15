// ============================================================
// PriVault – Dashboard Screen (BR-25) – Firebase
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pri_vault/features/notifications/notification_providers.dart';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/core/theme/app_theme.dart';
import 'package:pri_vault/core/router/app_router.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';
import 'package:pri_vault/features/auth/providers/profile_provider.dart';
import 'package:pri_vault/features/files/providers/files_provider.dart';
import 'package:pri_vault/features/files/screens/file_detail_screen.dart';
import 'package:pri_vault/features/setup/widgets/plan_selection_sheet.dart';
import 'package:pri_vault/features/sharing/providers/sharing_provider.dart';
import 'package:pri_vault/models/file_metadata.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

// --- Helpers ---

/// Classify a MIME type into one of four categories.
String _classifyMime(String mime) {
  final m = mime.toLowerCase();
  if (m.startsWith('image/')) return 'pictures';
  if (m.startsWith('video/')) return 'videos';
  if (m.startsWith('audio/')) return 'music';
  // PDFs, docs, spreadsheets, text, etc.
  if (m.startsWith('application/pdf') ||
      m.startsWith('application/msword') ||
      m.startsWith('application/vnd.') ||
      m.startsWith('text/')) {
    return 'documents';
  }
  return 'documents'; // default bucket
}

String _formatSize(int bytes) {
  if (bytes <= 0) return '0 B';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

// --- Providers ---

final dashboardStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final firestore = ref.read(firestoreProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return {};

  final userDoc = await firestore.collection('users').doc(uid).get();
  final userData = userDoc.data() ?? {};

  // Fetch ALL non-deleted files
  final filesSnap = await firestore
      .collection('users')
      .doc(uid)
      .collection('files')
      .where('isDeleted', isEqualTo: false)
      .get();

  // Build per-category stats
  final cats = <String, Map<String, int>>{
    'pictures': {'count': 0, 'bytes': 0},
    'documents': {'count': 0, 'bytes': 0},
    'videos': {'count': 0, 'bytes': 0},
    'music': {'count': 0, 'bytes': 0},
  };

  int totalUsedBytes = 0;

  // Collect recent files (raw docs sorted by updatedAt)
  final allDocs = filesSnap.docs.toList();

  for (final doc in allDocs) {
    final data = doc.data();
    final mime = (data['mimeType'] ?? data['mime_type'] ?? 'application/octet-stream') as String;
    final size = (data['sizeBytes'] ?? data['size_bytes'] ?? 0) as int;
    final cat = _classifyMime(mime);

    cats[cat]!['count'] = cats[cat]!['count']! + 1;
    cats[cat]!['bytes'] = cats[cat]!['bytes']! + size;
    totalUsedBytes += size;
  }

  // Sort by updatedAt descending for recent files
  allDocs.sort((a, b) {
    final aTime = a.data()['updatedAt'] ?? a.data()['updated_at'];
    final bTime = b.data()['updatedAt'] ?? b.data()['updated_at'];
    if (aTime == null && bTime == null) return 0;
    if (aTime == null) return 1;
    if (bTime == null) return -1;
    if (aTime is Timestamp && bTime is Timestamp) {
      return bTime.compareTo(aTime);
    }
    return 0;
  });

  final storageMaxBytes = userData['storageMaxBytes'] ?? userData['storage_max_bytes'] ?? 3221225472;

  return {
    'storage': {
      'storage_used_bytes': totalUsedBytes,
      'storage_max_bytes': storageMaxBytes,
    },
    'categories': cats,
    'total_files': allDocs.length,
  };
});

final dashboardActivityProvider =
    FutureProvider<List<dynamic>>((ref) async {
  final firestore = ref.read(firestoreProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return [];

  final snapshot = await firestore
      .collection('auditLogs')
      .where('userId', isEqualTo: uid)
      .orderBy('timestamp', descending: true)
      .limit(20)
      .get();
  return snapshot.docs.map((doc) => doc.data()).toList();
});

// --- Screen ---

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _checkPlanSelection();
  }

  Future<void> _checkPlanSelection() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final plan = userDoc.data()?['plan'];

      if (plan == null && mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: Colors.transparent,
          builder: (_) => const PlanSelectionSheet(isDismissible: false),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final userProfile = profileAsync.valueOrNull;

    // Extract profile info for the header
    final photoUrl = userProfile?['photoUrl'] as String?;
    final displayName = userProfile?['display_name'] as String? ??
        FirebaseAuth.instance.currentUser?.displayName ??
        'User';

    return Scaffold(
      backgroundColor: PriVaultColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            // (#7) Profile avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: PriVaultColors.surfaceLight,
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? const Icon(Icons.person_rounded,
                      color: PriVaultColors.textHint, size: 22,)
                  : null,
            ),
            const SizedBox(width: 12),
            // (#7) Welcome message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $displayName 👋',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final unread = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () => context.push(AppRoutes.notifications),
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: const BoxDecoration(
                          color: PriVaultColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(dashboardActivityProvider);
          },
          child: statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorView(
              error: e.toString(),
              onRetry: () => ref.invalidate(dashboardStatsProvider),
            ),
            data: (stats) => CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(24.0),
                  sliver: SliverToBoxAdapter(
                    child: _DashboardContent(stats: stats),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final Map<String, dynamic> stats;

  const _DashboardContent({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // (#2) Real storage data
    final storage = stats['storage'] as Map<String, dynamic>? ?? {};
    final storageUsedBytes = storage['storage_used_bytes'] as int? ?? 0;
    final storageMaxBytes =
        storage['storage_max_bytes'] as int? ?? 3221225472;
    final usedDisplay = _formatSize(storageUsedBytes);

    // (#3) Real category data
    final categories =
        stats['categories'] as Map<String, Map<String, int>>? ?? {};
    final picturesCat = categories['pictures'] ?? {'count': 0, 'bytes': 0};
    final documentsCat = categories['documents'] ?? {'count': 0, 'bytes': 0};
    final videosCat = categories['videos'] ?? {'count': 0, 'bytes': 0};
    final musicCat = categories['music'] ?? {'count': 0, 'bytes': 0};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // (#1) Banner REMOVED — nothing here

        // (#2) Donut Chart — real proportions
        SizedBox(
          height: 256,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(256, 256),
                painter: _StoragePieChartPainter(
                  picturesBytes: picturesCat['bytes']!,
                  documentsBytes: documentsCat['bytes']!,
                  videosBytes: videosCat['bytes']!,
                  musicBytes: musicCat['bytes']!,
                ),
              ),
              // Center text shows real used storage
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    usedDisplay,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Used',
                    style: TextStyle(
                      fontSize: 14,
                      color: PriVaultColors.textSecondary,
                    ),
                  ),
                  Text(
                    'of ${_formatSize(storageMaxBytes)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: PriVaultColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 32,
                child: _buildFloatingIcon(
                    Icons.image, [Colors.pink, Colors.pinkAccent],),
              ),
              Positioned(
                top: 100,
                right: 0,
                child: _buildFloatingIcon(
                    Icons.description, [Colors.amber, Colors.orangeAccent],),
              ),
              Positioned(
                bottom: 100,
                right: 8,
                child: _buildFloatingIcon(
                    Icons.videocam, [Colors.lightGreen, Colors.greenAccent],),
              ),
              Positioned(
                bottom: 16,
                left: 104,
                child: _buildFloatingIcon(
                    Icons.music_note, [Colors.cyan, Colors.lightBlueAccent],),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // (#3 & #4) Category Cards Grid — real data + navigation
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            _buildCategoryCard(
              context,
              name: 'Pictures',
              count: picturesCat['count']!,
              bytes: picturesCat['bytes']!,
              icon: Icons.image,
              gradient: [Colors.pink, Colors.pinkAccent],
              tabName: 'Images',
            ),
            _buildCategoryCard(
              context,
              name: 'Documents',
              count: documentsCat['count']!,
              bytes: documentsCat['bytes']!,
              icon: Icons.description,
              gradient: [Colors.amber, Colors.orange],
              tabName: 'Documents',
            ),
            _buildCategoryCard(
              context,
              name: 'Videos',
              count: videosCat['count']!,
              bytes: videosCat['bytes']!,
              icon: Icons.videocam,
              gradient: [Colors.lightGreen, Colors.green],
              tabName: 'Videos',
            ),
            _buildCategoryCard(
              context,
              name: 'Music',
              count: musicCat['count']!,
              bytes: musicCat['bytes']!,
              icon: Icons.music_note,
              gradient: [Colors.cyan, Colors.lightBlue],
              tabName: 'Music',
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Recent — horizontal story row (Firestore stream)
        const Text(
          'Recent',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        const _RecentStoryRow(),

        const SizedBox(height: 100), // Bottom nav padding
      ],
    );
  }

  Widget _buildFloatingIcon(IconData icon, List<Color> colors) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: Icon(icon, color: Colors.white, size: 16)),
    );
  }

  // (#3 & #4) Category card with real data and navigation
  Widget _buildCategoryCard(
    BuildContext context, {
    required String name,
    required int count,
    required int bytes,
    required IconData icon,
    required List<Color> gradient,
    required String tabName,
  }) {
    return GestureDetector(
      onTap: () {
        context.go(AppRoutes.files, extra: {'initialTab': tabName});
      },
      child: Container(
        decoration: BoxDecoration(
          color: PriVaultColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.0,
                    colors: [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(80),
                    topRight: Radius.circular(24),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child:
                            Center(child: Icon(icon, color: Colors.white)),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: PriVaultColors.textHint,),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$count Files',
                        style: const TextStyle(
                          fontSize: 12,
                          color: PriVaultColors.textSecondary,
                        ),
                      ),
                      Text(
                        _formatSize(bytes),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentStoryRow extends ConsumerWidget {
  const _RecentStoryRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return SizedBox(
      height: 100,
      child: Stack(
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('files')
                .where('isDeleted', isEqualTo: false)
                .orderBy('updatedAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return const Center(
                  child: Text(
                    'Could not load recent files',
                    style: TextStyle(color: PriVaultColors.textHint, fontSize: 12),
                  ),
                );
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No items yet',
                    style: TextStyle(color: PriVaultColors.textHint, fontSize: 13),
                  ),
                );
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < docs.length; i++) ...[
                      Builder(
                        builder: (context) {
                          final data = Map<String, dynamic>.from(docs[i].data());
                          data['id'] = docs[i].id;
                          data['user_id'] = uid;
                          return _RecentFileCard(fileData: data);
                        },
                      ),
                      if (i < docs.length - 1) const SizedBox(width: 10),
                    ],
                  ],
                ),
              );
            },
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 48,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      PriVaultColors.background.withValues(alpha: 0),
                      PriVaultColors.background,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// (#6) Recent file card widget
class _RecentFileCard extends ConsumerWidget {
  final Map<String, dynamic> fileData;
  const _RecentFileCard({required this.fileData});

  IconData _getFileIcon(String mime) {
    final m = mime.toLowerCase();
    if (m.startsWith('image/')) return Icons.image_rounded;
    if (m.startsWith('video/')) return Icons.videocam_rounded;
    if (m.startsWith('audio/')) return Icons.music_note_rounded;
    if (m.contains('pdf')) return Icons.picture_as_pdf_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _getFileColor(String mime) {
    final m = mime.toLowerCase();
    if (m.startsWith('image/')) return Colors.pinkAccent;
    if (m.startsWith('video/')) return Colors.greenAccent;
    if (m.startsWith('audio/')) return Colors.cyanAccent;
    if (m.contains('pdf')) return Colors.redAccent;
    return Colors.indigoAccent;
  }

  Future<String> _getDisplayName(WidgetRef ref) async {
    final encName = (fileData['encryptedName'] ??
        fileData['encrypted_name'] ??
        '') as String;
    if (encName.isEmpty) return 'Untitled';

    try {
      final vault = ref.read(vaultServiceProvider);
      final encryption = ref.read(encryptionServiceProvider);
      final seedBase64 = await vault.getMasterKeySeed();
      if (seedBase64 == null) return 'Encrypted File';
      final masterKey = CryptoUtils.fromBase64(seedBase64);
      final decryptedBytes = await encryption.decrypt(
        ciphertext: CryptoUtils.fromBase64(encName),
        key: masterKey,
      );
      return String.fromCharCodes(decryptedBytes);
    } catch (_) {
      return 'Encrypted File';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mime = (fileData['mimeType'] ??
        fileData['mime_type'] ??
        'application/octet-stream') as String;

    return FutureBuilder<String>(
      future: _getDisplayName(ref),
      builder: (context, snapshot) {
        final name = snapshot.data ?? 'Decrypting...';

        return GestureDetector(
          onTap: () {
            if (!snapshot.hasData) return;
            // Build FileMetadata from raw data to navigate
            try {
              final normalized = _normalizeForModel(fileData);
              final fileMeta = FileMetadata.fromJson(normalized);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FileViewerScreen(
                    file: fileMeta,
                    displayName: name,
                  ),
                ),
              );
            } catch (e) {
              debugPrint('RecentFileCard nav error: $e');
            }
          },
          child: SizedBox(
            width: 80,
            height: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getFileColor(mime).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: PriVaultColors.cardBorder),
                    ),
                    child: Center(
                      child: Icon(
                        _getFileIcon(mime),
                        color: _getFileColor(mime),
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _normalizeForModel(Map<String, dynamic> data) {
    // Ensure all keys the FileMetadata model expects are present
    final result = Map<String, dynamic>.from(data);
    result['id'] ??= '';
    result['userId'] ??= result['user_id'] ?? '';
    result['name'] ??= result['encryptedName'] ?? result['encrypted_name'] ?? '';
    result['encryptedName'] ??= result['encrypted_name'] ?? '';
    result['cloudinaryUrl'] ??= result['cloudinary_url'] ?? '';
    result['mimeType'] ??= result['mime_type'] ?? 'application/octet-stream';
    result['sizeBytes'] ??= result['size_bytes'] ?? 0;
    result['isFavorite'] ??= result['is_favorite'] ?? false;
    result['isDeleted'] ??= result['is_deleted'] ?? false;
    // Convert Firestore Timestamp fields to ISO strings for Freezed JSON parser
    if (result['createdAt'] is Timestamp) {
      result['createdAt'] = (result['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    if (result['updatedAt'] is Timestamp) {
      result['updatedAt'] = (result['updatedAt'] as Timestamp).toDate().toIso8601String();
    }
    if (result['deletedAt'] is Timestamp) {
      result['deletedAt'] = (result['deletedAt'] as Timestamp).toDate().toIso8601String();
    }
    return result;
  }
}

// (#2) Donut chart painter — single ring with proportional colored arcs
class _StoragePieChartPainter extends CustomPainter {
  final int picturesBytes;
  final int documentsBytes;
  final int videosBytes;
  final int musicBytes;

  _StoragePieChartPainter({
    required this.picturesBytes,
    required this.documentsBytes,
    required this.videosBytes,
    required this.musicBytes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 90.0;
    const strokeWidth = 24.0;
    const gapDeg = 4.0; // gap between arcs in degrees

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background ring (always visible)
    final bgPaint = Paint()
      ..color = PriVaultColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final total = picturesBytes + documentsBytes + videosBytes + musicBytes;

    // Arc colors for each category
    final arcDefs = <_ArcDef>[
      _ArcDef(picturesBytes, [Colors.pink, Colors.pinkAccent]),
      _ArcDef(documentsBytes, [Colors.amber, Colors.orangeAccent]),
      _ArcDef(videosBytes, [Colors.lightGreen, Colors.greenAccent]),
      _ArcDef(musicBytes, [Colors.cyan, Colors.lightBlueAccent]),
    ];

    const rad = math.pi / 180;

    if (total == 0) {
      // Empty state: draw four equally-spaced subtle arcs
      final emptyPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      for (var i = 0; i < arcDefs.length; i++) {
        final startAngle = (-90 + i * 90 + gapDeg / 2) * rad;
        const sweepAngle = (90 - gapDeg) * rad;
        final gradient = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: arcDefs[i].colors.map((c) => c.withValues(alpha: 0.15)).toList(),
        ).createShader(rect);
        emptyPaint.shader = gradient;
        canvas.drawArc(rect, startAngle, sweepAngle, false, emptyPaint);
      }
      return;
    }

    // Count how many categories have data — needed for gap calculation
    final activeCount = arcDefs.where((a) => a.bytes > 0).length;
    final totalGapDeg = activeCount > 1 ? gapDeg * activeCount : 0.0;
    final availableDeg = 360.0 - totalGapDeg;

    double currentAngle = -90.0; // start from 12 o'clock

    for (final arc in arcDefs) {
      if (arc.bytes <= 0) continue;

      final sweepDeg = math.max((arc.bytes / total) * availableDeg, 8.0);
      final startRad = currentAngle * rad;
      final sweepRad = sweepDeg * rad;

      final gradient = SweepGradient(
        startAngle: startRad,
        endAngle: startRad + sweepRad,
        colors: arc.colors,
      ).createShader(rect);

      final arcPaint = Paint()
        ..shader = gradient
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startRad, sweepRad, false, arcPaint);

      currentAngle += sweepDeg + (activeCount > 1 ? gapDeg : 0);
    }
  }

  @override
  bool shouldRepaint(covariant _StoragePieChartPainter oldDelegate) =>
      oldDelegate.picturesBytes != picturesBytes ||
      oldDelegate.documentsBytes != documentsBytes ||
      oldDelegate.videosBytes != videosBytes ||
      oldDelegate.musicBytes != musicBytes;
}

class _ArcDef {
  final int bytes;
  final List<Color> colors;
  const _ArcDef(this.bytes, this.colors);
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: PriVaultColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
