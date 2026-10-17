import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/remote/sync_service.dart';
import '../auth/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentProfileProvider);
    final syncState = ref.watch(syncStateProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Student Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => context.push(AppRoutes.editProfile),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space20),
        child: Column(
          children: [
            // Avatar & Name Card
            Center(
              child: Column(
                children: [
                  UserAvatar(
                    photoUrl: user?.photoUrl,
                    name: user?.displayName ?? 'Student',
                    size: 92,
                    showEditBadge: true,
                    onTap: () => context.push(AppRoutes.editProfile),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.displayName ?? 'Student',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'Not signed in',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space24),

            // Cloud Synchronization Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.cloud_sync_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cloud Sync (Firestore)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: syncState.isCloudConnected
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  syncState.isCloudConnected
                                      ? 'Connected to studymate-e8da6'
                                      : 'Local offline cache',
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
                        ),
                      ),
                      if (syncState.isSyncing)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.sync_rounded),
                          tooltip: 'Sync Now',
                          color: AppColors.primary,
                          onPressed: () async {
                            if (user == null || user.uid.isEmpty) return;
                            final res = await ref
                                .read(syncStateProvider.notifier)
                                .triggerSync(user.uid);
                            if (context.mounted) {
                              if (res.isSuccess) {
                                AppDialogs.showSnackBar(
                                  context,
                                  message:
                                      'Synced ${res.totalItems} items with Firestore successfully!',
                                  isSuccess: true,
                                );
                              } else {
                                AppDialogs.showSnackBar(
                                  context,
                                  message:
                                      'Sync notice: ${res.errorMessage ?? "Could not reach cloud"}',
                                  isError: true,
                                );
                              }
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Last Synced:',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      Text(
                        syncState.lastSyncedAt != null
                            ? DateFormat('hh:mm a, MMM d')
                                .format(syncState.lastSyncedAt!)
                            : 'On sign-in / Pending',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            // Profile Info Card
            AppCard(
              child: Column(
                children: [
                  _buildProfileRow(
                    icon: Icons.flag_rounded,
                    title: 'Daily Study Target',
                    value: '${user?.dailyGoalMinutes ?? 120} minutes',
                    isDark: isDark,
                  ),
                  const Divider(height: 24),
                  _buildProfileRow(
                    icon: Icons.verified_user_rounded,
                    title: 'Account Status',
                    value: 'Active Student',
                    isDark: isDark,
                  ),
                  const Divider(height: 24),
                  _buildProfileRow(
                    icon: Icons.storage_rounded,
                    title: 'Database Engine',
                    value: 'Offline-First SQLite',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space20),

            // Settings Links
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildMenuTile(
                    context,
                    icon: Icons.edit_note_rounded,
                    title: 'Edit Profile & Student Avatar',
                    onTap: () => context.push(AppRoutes.editProfile),
                    isDark: isDark,
                  ),
                  _buildMenuTile(
                    context,
                    icon: Icons.notifications_none_rounded,
                    title: 'Notification Preferences',
                    onTap: () => context.push(AppRoutes.notificationSettings),
                    isDark: isDark,
                  ),
                  _buildMenuTile(
                    context,
                    icon: Icons.palette_outlined,
                    title: 'Appearance & Theme',
                    onTap: () => context.push(AppRoutes.appearanceSettings),
                    isDark: isDark,
                  ),
                  _buildMenuTile(
                    context,
                    icon: Icons.download_rounded,
                    title: 'Export My Data (JSON)',
                    onTap: () => context.push(AppRoutes.dataExport),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space24),

            // Logout & Delete Buttons
            AppButton(
              text: 'Sign Out',
              variant: AppButtonVariant.outline,
              icon: Icons.logout_rounded,
              onPressed: () async {
                final confirm = await AppDialogs.showConfirmDialog(
                  context: context,
                  title: 'Sign Out',
                  message: 'Are you sure you want to sign out of your account?',
                  confirmText: 'Sign Out',
                );
                if (confirm == true) {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Delete Account',
              variant: AppButtonVariant.danger,
              icon: Icons.delete_forever_rounded,
              onPressed: () => context.push(AppRoutes.deleteAccount),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: AppColors.textMutedLight,
        ),
        onTap: onTap,
      ),
    );
  }
}
