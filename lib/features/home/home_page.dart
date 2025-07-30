import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../auth/auth_controller.dart';
import '../../models/itinerary_model.dart';
import '../../services/voice_input_service.dart';
import '../../theme/app_theme.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final savedTripsBox = Hive.box('savedTrips');

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with greeting and profile icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentTeal,
                        ),
                        children: [
                          const TextSpan(text: 'Hey '),
                          TextSpan(
                            text:
                                user?.displayName?.split(' ').first ?? 'there',
                          ),
                          const TextSpan(text: ' 👋'),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.accentTeal,
                      child: Text(
                        user?.displayName?.isNotEmpty == true
                            ? user!.displayName![0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // Main question
              Text(
                'What\'s your vision for this trip?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Large text input area with teal border
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.accentTeal, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    TextField(
                      controller: _promptController,
                      decoration: const InputDecoration(
                        hintText:
                            '7 days in Bali next April, 3 people, mid-range budget, wanted to explore less populated areas, it should be a peaceful trip!',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.fromLTRB(20, 20, 60, 20),
                      ),
                      maxLines: null,
                      minLines: 5,
                      style: const TextStyle(fontSize: 16),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: VoiceInputButton(
                        onResult: (result) {
                          _promptController.text = result;
                        },
                        tooltip: 'Voice input',
                        activeColor: AppTheme.accentTeal,
                        inactiveColor: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Create My Itinerary button
              ElevatedButton(
                onPressed: _createItinerary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Create My Itinerary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 48),

              // Offline Saved Itineraries section
              Text(
                'Offline Saved Itineraries',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Saved itineraries list
              ValueListenableBuilder(
                valueListenable: savedTripsBox.listenable(),
                builder: (context, Box box, _) {
                  if (box.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: List.generate(box.length, (index) {
                      final trip = box.getAt(index);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.accentTeal,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                trip is Itinerary
                                    ? '${trip.title}, ${trip.days.length} days vacation'
                                    : trip['title'] ?? 'Untitled Trip',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _createItinerary() {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your trip first')),
      );
      return;
    }

    Navigator.pushNamed(context, '/generate-itinerary', arguments: prompt);
  }
}
