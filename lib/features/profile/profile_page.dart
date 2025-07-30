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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Main content card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // User Info Section
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF2D5E5E),
                        child: Text(
                          user?.displayName?.isNotEmpty == true
                              ? user!.displayName![0].toUpperCase()
                              : user?.email?[0].toUpperCase() ?? 'S',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'User Name',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? 'user@example.com',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Request Tokens
                  _buildUsageCard(
                    'Request Tokens',
                    '${usageStats.totalRequests}/1000',
                    usageStats.totalRequests / 1000,
                    const Color(0xFF2D5E5E),
                  ),

                  const SizedBox(height: 16),

                  // Response Tokens
                  _buildUsageCard(
                    'Response Tokens',
                    '${usageStats.totalTokens}/1000',
                    usageStats.totalTokens / 1000,
                    const Color(0xFFE74C3C),
                  ),

                  const SizedBox(height: 16),

                  // Total Cost
                  _buildCostCard(
                    'Total Cost',
                    '\$${usageStats.estimatedCost.toStringAsFixed(2)} USD',
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Log Out Button
            TextButton(
              onPressed: () => _signOut(context, ref),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: Color(0xFFE74C3C),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageCard(
    String title,
    String value,
    double progress,
    Color progressColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF27AE60),
            ),
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
