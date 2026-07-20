import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../mock_data/inventory_store.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const SettingsScreen({super.key, required this.onLogout});

  String _branchLabel(String? id) {
    switch (id) {
      case 'LIPA_CITY':
        return 'Lipa City Branch';
      case 'MAHABANG_PARANG':
        return 'Mahabang Parang Branch';
      case 'STA_RITA':
        return 'Sta. Rita Branch';
      default:
        return 'Unknown Branch';
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Change Password', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'Current Password'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'New Password'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 6) return 'At least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'Confirm New Password'),
                        validator: (v) => (v != newPasswordController.text) ? 'Passwords do not match' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSubmitting = true);

                          try {
                            final credential = EmailAuthProvider.credential(
                              email: user.email!,
                              password: currentPasswordController.text,
                            );
                            await user.reauthenticateWithCredential(credential);
                            await user.updatePassword(newPasswordController.text);

                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password updated successfully.')),
                            );
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() => isSubmitting = false);
                            final message = e.code == 'wrong-password' || e.code == 'invalid-credential'
                                ? 'Current password is incorrect.'
                                : (e.message ?? 'Could not update password.');
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(message)));
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Could not update password: $e')),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                        )
                      : const Text('Save', style: TextStyle(color: AppColors.accent)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = InventoryStore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.12),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.person, color: AppColors.accent, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.currentManagerName ?? 'Branch Manager',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _branchLabel(store.currentBranchId),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Preferences section (placeholder for future settings)
          const Text(
            'PREFERENCES',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.6),
          ),
          const SizedBox(height: 10),
          const _SettingsTile(
            icon: Icons.info,
            title: 'App Version',
            trailing: Text('v1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          const SizedBox(height: 24),

          // Account section
          const Text(
            'ACCOUNT',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.6),
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.lock,
            title: 'Change Password',
            onTap: () => _showChangePasswordDialog(context),
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Log Out',
            titleColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? titleColor;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.titleColor,
    this.iconColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.accent, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: titleColor ?? AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              if (trailing != null) trailing!,
              if (onTap != null && trailing == null)
                const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}