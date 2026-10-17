import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/local/app_database.dart';
import '../../data/models/study_group_model.dart';
import '../auth/auth_controller.dart';

class StudyGroupsScreen extends ConsumerStatefulWidget {
  const StudyGroupsScreen({super.key});

  @override
  ConsumerState<StudyGroupsScreen> createState() => _StudyGroupsScreenState();
}

class _StudyGroupsScreenState extends ConsumerState<StudyGroupsScreen> {
  List<StudyGroupModel> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final db = ref.read(appDatabaseProvider);
    var list = await db.getStudyGroups();

    if (list.isEmpty) {
      final starter = [
        StudyGroupModel(
          id: 'grp-1',
          name: 'Computer Science Masters Group',
          description: 'Collaborative problem solving on algorithms and distributed systems',
          subject: 'Computer Science',
          adminUserId: 'admin-1',
          joinCode: 'CS-8921',
          memberCount: 6,
          sharedNotesCount: 12,
        ),
        StudyGroupModel(
          id: 'grp-2',
          name: 'Calculus & Engineering Math Squad',
          description:
              'Daily practice on differential equations and vector calculus',
          subject: 'Mathematics',
          adminUserId: 'admin-2',
          joinCode: 'MATH-4410',
          memberCount: 4,
          sharedNotesCount: 8,
        ),
      ];

      for (final g in starter) {
        await db.insertStudyGroup(g);
      }
      list = starter;
    }

    if (mounted) {
      setState(() {
        _groups = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Collaborative Study Groups',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_rounded),
            tooltip: 'Join by Code',
            onPressed: () => _showJoinCodeDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
          ? Center(
              child: Text(
                'No study groups joined yet',
                style: TextStyle(color: AppColors.textMutedLight),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.space16),
              itemCount: _groups.length,
              itemBuilder: (context, idx) {
                final group = _groups[idx];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.groups_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${group.subject} • Join Code: ${group.joinCode}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          group.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: AppColors.textMutedLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${group.memberCount} Members',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.folder_shared_outlined,
                              size: 14,
                              color: AppColors.textMutedLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${group.sharedNotesCount} Shared Notes',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                minimumSize: Size.zero,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Opening shared workspace for ${group.name}...',
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Open Group',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Create Group',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        onPressed: () => _showCreateGroupDialog(context),
      ),
    );
  }

  void _showJoinCodeDialog(BuildContext context) {
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Group by Code'),
        content: AppTextField(
          controller: codeCtrl,
          label: '6-Digit Join Code',
          hint: 'e.g. CS-8921',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Joined study group successfully!'),
                ),
              );
            },
            child: const Text(
              'Join Group',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final subCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Study Group'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: nameCtrl,
                label: 'Group Name',
                hint: 'e.g. Algorithms Study Circle',
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: subCtrl,
                label: 'Subject',
                hint: 'e.g. Computer Science',
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: descCtrl,
                label: 'Description',
                hint: 'e.g. Weekly problem discussions',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final user = ref.read(currentProfileProvider);
              final userId = user?.uid ?? 'guest';
              final newGroup = StudyGroupModel(
                id: 'grp-${DateTime.now().millisecondsSinceEpoch}',
                name: nameCtrl.text.trim(),
                subject: subCtrl.text.trim().isEmpty
                    ? 'General'
                    : subCtrl.text.trim(),
                description: descCtrl.text.trim(),
                adminUserId: userId,
                joinCode:
                    'ST-${(DateTime.now().millisecondsSinceEpoch % 9000) + 1000}',
              );
              await ref.read(appDatabaseProvider).insertStudyGroup(newGroup);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadGroups();
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
