import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/error_tracking_service.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialogs.dart';

/// In-app Diagnostics, Error Tracking & Telemetry Dashboard.
/// Gives users and developers transparency into application health, errors, and local telemetry.
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tracker = ErrorTrackingService.instance;
    final analytics = AnalyticsService.instance;
    final errors = tracker.recentErrors;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Error Tracking & Diagnostics',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Diagnostics',
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // System Health Status Card
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: errors.isEmpty
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      errors.isEmpty
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      color: errors.isEmpty
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          errors.isEmpty ? 'All Systems Operational' : 'Minor Errors Captured',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1A1C29),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          errors.isEmpty
                              ? 'Zero crash exceptions logged during this session.'
                              : '${errors.length} non-fatal runtime issue(s) recorded.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Diagnostic Actions
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Copy Diagnostic Report',
                    icon: Icons.copy_rounded,
                    onPressed: () {
                      final report = tracker.generateDiagnosticReport();
                      Clipboard.setData(ClipboardData(text: report));
                      AppDialogs.showSnackBar(
                        context,
                        message: 'Diagnostics report copied to clipboard!',
                        isSuccess: true,
                      );
                    },
                  ),
                ),
                if (errors.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                    label: const Text('Clear'),
                    onPressed: () {
                      tracker.clear();
                      setState(() {});
                      AppDialogs.showSnackBar(context, message: 'Logs cleared.');
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Analytics Engagement Summary
            Text(
              'Session Telemetry Summary',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1C29),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Builder(
                builder: (context) {
                  final summary = analytics.getSummary();
                  if (summary.isEmpty) {
                    return const Text(
                      'No events logged yet in current session.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    );
                  }
                  return Column(
                    children: summary.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              e.key,
                              style: const TextStyle(fontSize: 12.5, fontFamily: 'monospace'),
                            ),
                            Text(
                              '${e.value}x',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Captured Error Logs Section
            Text(
              'Recent Error Logs (${errors.length})',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1C29),
              ),
            ),
            const SizedBox(height: 8),

            if (errors.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.shield_rounded, size: 36, color: Color(0xFF10B981)),
                    SizedBox(height: 8),
                    Text(
                      'No errors detected. App running smoothly!',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: errors.length,
                itemBuilder: (context, index) {
                  final err = errors[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                err.context ?? 'Error',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${err.timestamp.hour.toString().padLeft(2, '0')}:${err.timestamp.minute.toString().padLeft(2, '0')}:${err.timestamp.second.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          err.message,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1A1C29),
                          ),
                        ),
                        if (err.stackTrace != null && err.stackTrace!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            err.stackTrace!.split('\n').take(3).join('\n'),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
