import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive/hive.dart';
import '../../models/itinerary_model.dart';
import '../itinerary/itinerary_controller.dart';
import '../../theme/app_theme.dart';

class GeneratedItineraryPage extends ConsumerStatefulWidget {
  final String originalPrompt;

  const GeneratedItineraryPage({super.key, required this.originalPrompt});

  @override
  ConsumerState<GeneratedItineraryPage> createState() =>
      _GeneratedItineraryPageState();
}

class _GeneratedItineraryPageState
    extends ConsumerState<GeneratedItineraryPage> {
  @override
  void initState() {
    super.initState();
    // Start generating the itinerary when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(itineraryGenerationControllerProvider.notifier)
          .generateItinerary(widget.originalPrompt);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itineraryGenerationControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          state.generatedItinerary != null ? 'Home' : 'Home',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.accentTeal,
            child: Text(
              'S', // You can get user initial here
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(ItineraryGenerationState state) {
    if (state.error != null) {
      return _buildErrorWidget(state.error!);
    }

    if (state.generatedItinerary != null) {
      return _buildItineraryWidget(state.generatedItinerary!);
    }

    return _buildLoadingWidget(state.streamedContent);
  }

  Widget _buildLoadingWidget(String streamedContent) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Creating Itinerary title
          Text(
            'Creating Itinerary...',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 60),

          // Loading indicator
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentTeal),
            strokeWidth: 3,
          ),
          const SizedBox(height: 32),

          // Status message
          Text(
            'Curating a perfect plan for you...',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // Bottom buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: null, // Disabled during loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentTeal.withValues(alpha: 0.3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text(
                    'Follow up to refine',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: null, // Disabled during loading
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[400]!),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.download, color: Colors.grey[600]),
                  label: Text(
                    'Save Offline',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildItineraryWidget(Itinerary itinerary) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with emoji
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Itinerary Created 🏝️',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Days
                ...itinerary.days.asMap().entries.map((entry) {
                  final dayIndex = entry.key;
                  final day = entry.value;
                  return _buildDaySection(dayIndex + 1, day);
                }),

                // Flight info at bottom
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _openInMaps(''),
                        child: const Text(
                          'Open in maps',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('📍'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Mumbai to Bali, Indonesia | 11hrs 5mins',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 80), // Space for bottom buttons
              ],
            ),
          ),
        ),

        // Bottom action buttons
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToChat(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text(
                    'Follow up to refine',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _saveItinerary(itinerary),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.textSecondary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.download,
                    color: AppTheme.textSecondary,
                  ),
                  label: const Text(
                    'Save Offline',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDaySection(int dayNumber, ItineraryDay day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Day $dayNumber: ${day.summary}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...day.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 0, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppTheme.textPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${item.time}: ${item.activity}${item.location.isNotEmpty ? ' at ${item.location}' : ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(itineraryGenerationControllerProvider.notifier)
                    .generateItinerary(widget.originalPrompt);
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInMaps(String location) async {
    final encodedLocation = Uri.encodeComponent(location);
    final url = 'https://www.google.com/maps/search/$encodedLocation';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
      }
    }
  }

  Future<void> _saveItinerary(Itinerary itinerary) async {
    try {
      final box = Hive.box('savedTrips');
      await box.add(itinerary);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Itinerary saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  void _navigateToChat() {
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'originalPrompt': widget.originalPrompt,
        'itinerary': ref
            .read(itineraryGenerationControllerProvider)
            .generatedItinerary,
      },
    );
  }
}
