import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../auth/auth_controller.dart';

// Simple usage tracking model
class UsageStats {
  final int totalRequests;
  final int totalTokens;
  final double estimatedCost;
  final DateTime lastUpdated;

  UsageStats({
    required this.totalRequests,
    required this.totalTokens,
    required this.estimatedCost,
    required this.lastUpdated,
  });

  factory UsageStats.fromMap(Map<String, dynamic> map) {
    return UsageStats(
      totalRequests: map['totalRequests'] ?? 0,
      totalTokens: map['totalTokens'] ?? 0,
      estimatedCost: (map['estimatedCost'] ?? 0.0).toDouble(),
      lastUpdated: DateTime.parse(
        map['lastUpdated'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalRequests': totalRequests,
      'totalTokens': totalTokens,
      'estimatedCost': estimatedCost,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  UsageStats copyWith({
    int? totalRequests,
    int? totalTokens,
    double? estimatedCost,
    DateTime? lastUpdated,
  }) {
    return UsageStats(
      totalRequests: totalRequests ?? this.totalRequests,
      totalTokens: totalTokens ?? this.totalTokens,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// Usage tracking provider
final usageStatsProvider =
    StateNotifierProvider<UsageStatsNotifier, UsageStats>((ref) {
      return UsageStatsNotifier();
    });

class UsageStatsNotifier extends StateNotifier<UsageStats> {
  UsageStatsNotifier()
    : super(
        UsageStats(
          totalRequests: 0,
          totalTokens: 0,
          estimatedCost: 0.0,
          lastUpdated: DateTime.now(),
        ),
      ) {
    _loadStats();
  }

  void _loadStats() {
    try {
      final box = Hive.box('userStats');
      final statsMap = box.get('usageStats');
      if (statsMap != null) {
        state = UsageStats.fromMap(Map<String, dynamic>.from(statsMap));
      }
    } catch (e) {
      // If error loading, keep default state
      debugPrint('Error loading usage stats: $e');
    }
  }

  Future<void> incrementUsage({int tokens = 0, double cost = 0.0}) async {
    state = state.copyWith(
      totalRequests: state.totalRequests + 1,
      totalTokens: state.totalTokens + tokens,
      estimatedCost: state.estimatedCost + cost,
      lastUpdated: DateTime.now(),
    );

    await _saveStats();
  }

  Future<void> _saveStats() async {
    try {
      final box = Hive.box('userStats');
      await box.put('usageStats', state.toMap());
    } catch (e) {
      debugPrint('Error saving usage stats: $e');
    }
  }

  Future<void> resetStats() async {
    state = UsageStats(
      totalRequests: 0,
      totalTokens: 0,
      estimatedCost: 0.0,
      lastUpdated: DateTime.now(),
    );
    await _saveStats();
  }
}

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final usageStats = ref.watch(usageStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Section
            _buildUserInfoCard(context, user),
            const SizedBox(height: 24),

            // Usage Statistics Section
            _buildUsageStatsSection(context, ref, usageStats),
            const SizedBox(height: 24),

            // Settings Section
            _buildSettingsSection(context),
            const SizedBox(height: 24),

            // Danger Zone
            _buildDangerZone(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context, user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                user?.displayName?.isNotEmpty == true
                    ? user!.displayName![0].toUpperCase()
                    : user?.email?[0].toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'User',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Premium User',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStatsSection(
    BuildContext context,
    WidgetRef ref,
    UsageStats stats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Usage Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => _showResetConfirmation(context, ref),
              child: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Requests',
                stats.totalRequests.toString(),
                Icons.chat_bubble_outline,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Tokens Used',
                _formatNumber(stats.totalTokens),
                Icons.token,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          context,
          'Estimated Cost',
          '\$${stats.estimatedCost.toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.orange,
          isWide: true,
        ),
        const SizedBox(height: 8),
        Text(
          'Last updated: ${_formatDate(stats.lastUpdated)}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isWide = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isWide
            ? Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notifications'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // TODO: Implement notification settings
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: false,
                  onChanged: (value) {
                    // TODO: Implement theme switching
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: const Text('Language'),
                subtitle: const Text('English'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to language settings
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to help page
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZone(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: const Text(
                  'Permanently delete your account and data',
                ),
                onTap: () => _showDeleteAccountConfirmation(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.orange),
                ),
                subtitle: const Text('Sign out of your account'),
                onTap: () => _signOut(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Usage Statistics'),
        content: const Text(
          'Are you sure you want to reset all usage statistics? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(usageStatsProvider.notifier).resetStats();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Usage statistics reset')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This will permanently delete all your data and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion not implemented yet'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/sign-in', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    }
  }
}
