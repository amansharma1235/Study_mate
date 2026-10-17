import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/local/app_database.dart';
import '../../data/models/document_model.dart';
import '../auth/auth_controller.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  String _searchQuery = '';
  String _selectedSubject = 'All';
  List<DocumentModel> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final user = ref.read(currentProfileProvider);
    final userId = user?.uid ?? 'guest';
    final db = ref.read(appDatabaseProvider);
    var list = await db.getDocuments(userId);

    if (list.isEmpty) {
      // Seed default reference guides
      final starterDocs = [
        DocumentModel(
          id: 'doc-1',
          userId: userId,
          title: 'Data Structures & Algorithms Cheat Sheet',
          subject: 'Computer Science',
          fileType: 'pdf',
          filePath: '/storage/studymate/dsa_reference.pdf',
          fileSizeBytes: 2450000,
          pageCount: 14,
          isBookmarked: true,
        ),
        DocumentModel(
          id: 'doc-2',
          userId: userId,
          title: 'Calculus & Integration Comprehensive Handbook',
          subject: 'Mathematics',
          fileType: 'pdf',
          filePath: '/storage/studymate/calculus_handbook.pdf',
          fileSizeBytes: 1820000,
          pageCount: 22,
        ),
        DocumentModel(
          id: 'doc-3',
          userId: userId,
          title: 'Mechanics & Electromagnetism Constants Guide',
          subject: 'Physics',
          fileType: 'pdf',
          filePath: '/storage/studymate/physics_constants.pdf',
          fileSizeBytes: 980000,
          pageCount: 8,
          isBookmarked: true,
        ),
      ];

      for (final d in starterDocs) {
        await db.insertDocument(d);
      }
      list = starterDocs;
    }

    if (mounted) {
      setState(() {
        _documents = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _documents.where((doc) {
      final matchesQuery =
          _searchQuery.isEmpty ||
          doc.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doc.subject.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSubject =
          _selectedSubject == 'All' || doc.subject == _selectedSubject;
      return matchesQuery && matchesSubject;
    }).toList();

    final subjects = ['All', ..._documents.map((d) => d.subject).toSet()];

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'PDF & Study Documents',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
            tooltip: 'Import PDF',
            onPressed: () => _showImportDocumentDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search documents by title or subject...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),

                // Subject Filters
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: subjects.length,
                    itemBuilder: (context, i) {
                      final sub = subjects[i];
                      final isSel = sub == _selectedSubject;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSubject = sub),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.primary
                                : (isDark ? AppColors.cardDark : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSel
                                  ? AppColors.primary
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Text(
                            sub,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isSel
                                  ? Colors.white
                                  : (isDark
                                        ? Colors.white
                                        : AppColors.textPrimaryLight),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Documents List
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No documents found',
                            style: TextStyle(color: AppColors.textMutedLight),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, idx) {
                            final doc = filtered[idx];
                            return _buildDocumentCard(doc, isDark);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Import Document',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        onPressed: () => _showImportDocumentDialog(context),
      ),
    );
  }

  Widget _buildDocumentCard(DocumentModel doc, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // PDF Icon Badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: AppColors.error,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        doc.subject,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${doc.formattedSize} • ${doc.pageCount} Pages',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Open Action
            IconButton(
              icon: const Icon(
                Icons.visibility_outlined,
                color: AppColors.primary,
              ),
              tooltip: 'View Document',
              onPressed: () => _showReaderSheet(doc),
            ),
          ],
        ),
      ),
    );
  }

  void _showReaderSheet(DocumentModel doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              AppBar(
                title: Text(doc.title, style: const TextStyle(fontSize: 15)),
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_rounded),
                    tooltip: 'Share Document',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Document ready for export/sharing!'),
                        ),
                      );
                    },
                  ),
                ],
                elevation: 0,
                backgroundColor: Colors.transparent,
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📖 Study Document Viewer',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Document Title: ${doc.title}\nSubject: ${doc.subject}\nPages: ${doc.pageCount} | Size: ${doc.formattedSize}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                        const Divider(height: 24),
                        const Text(
                          'Key Concepts & Formulas:\n\n1. Axiom of Completeness and Convergence Bounds\n2. Big-O Complexity and Asymptotic Analysis\n3. Proof by Mathematical Induction\n4. Closed-form summation formulas for Arithmetic & Geometric Progressions\n5. Boundary value condition checking in differential equations\n\nNotes are automatically indexed and available offline.',
                          style: TextStyle(fontSize: 14, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImportDocumentDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Import Document / PDF',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: titleCtrl,
              label: 'Document Title',
              hint: 'e.g. Unit 3 Handwritten Notes',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: subjectCtrl,
              label: 'Subject',
              hint: 'e.g. Computer Science',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (titleCtrl.text.isEmpty) return;
              final user = ref.read(currentProfileProvider);
              final userId = user?.uid ?? 'guest';
              final newDoc = DocumentModel(
                id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
                userId: userId,
                title: titleCtrl.text.trim(),
                subject: subjectCtrl.text.trim().isEmpty
                    ? 'General'
                    : subjectCtrl.text.trim(),
                filePath:
                    '/storage/studymate/${titleCtrl.text.trim().toLowerCase().replaceAll(' ', '_')}.pdf',
                fileSizeBytes: 1250000,
                pageCount: 10,
              );
              await ref.read(appDatabaseProvider).insertDocument(newDoc);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadDocuments();
            },
            child: const Text('Import', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
