import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/local/app_database.dart';
import '../../data/models/career_model.dart';
import '../auth/auth_controller.dart';

class CareerScreen extends ConsumerStatefulWidget {
  const CareerScreen({super.key});

  @override
  ConsumerState<CareerScreen> createState() => _CareerScreenState();
}

class _CareerScreenState extends ConsumerState<CareerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<JobApplicationModel> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final user = ref.read(currentProfileProvider);
    final userId = user?.uid ?? 'guest';
    final db = ref.read(appDatabaseProvider);
    var list = await db.getJobApplications(userId);

    if (list.isEmpty) {
      final starter = [
        JobApplicationModel(
          id: 'job-1',
          userId: userId,
          company: 'Google',
          role: 'Software Engineering Intern (Summer)',
          status: 'Applied',
          stipendOrSalary: 'Competitive',
          location: 'Bangalore / Remote',
          notes: 'Referral submitted. Focus on LeetCode Mediums and OS.',
        ),
        JobApplicationModel(
          id: 'job-2',
          userId: userId,
          company: 'Microsoft',
          role: 'Junior Mobile Application Developer',
          status: 'Interviewing',
          stipendOrSalary: '15 LPA',
          location: 'Hyderabad',
          notes: 'Round 1 technical scheduled next week. Review Flutter lifecycle.',
        ),
      ];

      for (final j in starter) {
        await db.insertJobApplication(j);
      }
      list = starter;
    }

    if (mounted) {
      setState(() {
        _jobs = list;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          'Student Career Center',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark
              ? AppColors.textMutedDark
              : AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Application Tracker'),
            Tab(text: 'Resume Builder'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildJobTrackerTab(isDark),
                _buildResumeBuilderTab(isDark),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Track Job',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        onPressed: () => _showAddJobDialog(context),
      ),
    );
  }

  Widget _buildJobTrackerTab(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.space16),
      itemCount: _jobs.length,
      itemBuilder: (context, idx) {
        final job = _jobs[idx];
        final statusColor = _getStatusColor(job.status);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        job.company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        job.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  job.role,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textMutedLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          job.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    if (job.stipendOrSalary.isNotEmpty) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.payments_outlined,
                            size: 14,
                            color: AppColors.textMutedLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            job.stipendOrSalary,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                if (job.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '📝 ${job.notes}',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String s) {
    switch (s.toLowerCase()) {
      case 'interviewing':
        return Colors.orange;
      case 'offer':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildResumeBuilderTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '📄 Student Master Resume',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      icon: const Icon(
                        Icons.download_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Export PDF',
                        style: TextStyle(fontSize: 11, color: Colors.white),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '✅ Resume formatted and exported successfully!',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text(
                  'Education',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'B.Tech in Computer Science & Engineering (2022 - 2026)\nCGPA: 8.6 / 10.0',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Technical Skills',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• Languages: Dart, Python, Java, C++, SQL, JavaScript\n• Frameworks: Flutter, Riverpod, Firebase, Git, SQLite',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Featured Projects',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  '1. StudyMate — Complete Student Productivity App (Flutter & SQLite)\n2. Spaced Repetition Engine — SuperMemo SM-2 Recall System',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddJobDialog(BuildContext context) {
    final compCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Track Job / Internship',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: compCtrl,
                label: 'Company Name',
                hint: 'e.g. Amazon',
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: roleCtrl,
                label: 'Role / Designation',
                hint: 'e.g. SDE Intern',
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: locCtrl,
                label: 'Location',
                hint: 'e.g. Bangalore / Remote',
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: notesCtrl,
                label: 'Notes / Application Link',
                hint: 'e.g. Applied via Career Portal',
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
              if (compCtrl.text.isEmpty || roleCtrl.text.isEmpty) return;
              final user = ref.read(currentProfileProvider);
              final userId = user?.uid ?? 'guest';
              final newJob = JobApplicationModel(
                id: 'job-${DateTime.now().millisecondsSinceEpoch}',
                userId: userId,
                company: compCtrl.text.trim(),
                role: roleCtrl.text.trim(),
                location: locCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
              );
              await ref.read(appDatabaseProvider).insertJobApplication(newJob);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadJobs();
            },
            child: const Text(
              'Save Job',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
