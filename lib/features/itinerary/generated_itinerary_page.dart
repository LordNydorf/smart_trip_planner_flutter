import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive/hive.dart';
import '../../models/itinerary_model.dart';
import '../itinerary/itinerary_controller.dart';
import '../../theme/app_theme.dart';
import '../../services/location_service.dart';
import '../auth/auth_controller.dart';

class GeneratedItineraryPage extends ConsumerStatefulWidget {
  final String originalPrompt;

  const GeneratedItineraryPage({super.key, required this.originalPrompt});

  @override
  ConsumerState<GeneratedItineraryPage> createState() =>
      _GeneratedItineraryPageState();
}

class _GeneratedItineraryPageState
    extends ConsumerState<GeneratedItineraryPage> {
  TravelInfo? _travelInfo;
  bool _loadingTravelInfo = false;
  final LocationService _locationService = LocationService();

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

  Future<void> _loadTravelInfo(Itinerary itinerary) async {
    if (_travelInfo != null || _loadingTravelInfo) return;

    setState(() {
      _loadingTravelInfo = true;
    });

    try {
      final destination = _locationService.extractDestinationFromItinerary(
        itinerary,
      );
      final travelInfo = await _locationService.getTravelInfo(destination);

      if (mounted) {
        setState(() {
          _travelInfo = travelInfo;
          _loadingTravelInfo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingTravelInfo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itineraryGenerationControllerProvider);
    final user = ref.watch(authControllerProvider);

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
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            borderRadius: BorderRadius.circular(20),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.accentTeal,
              child: Text(
                user?.displayName?.isNotEmpty == true
                    ? user!.displayName![0].toUpperCase()
                    : 'S',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
    // Load travel info when itinerary is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTravelInfo(itinerary);
    });

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with emoji - centered
                Center(
                  child: Text(
                    'Itinerary Created 🏝️',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      fontSize: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Days
                ...itinerary.days.asMap().entries.map((entry) {
                  final dayIndex = entry.key;
                  final day = entry.value;
                  return _buildDaySection(dayIndex + 1, day);
                }),

                // Map section
                const SizedBox(height: 32),
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
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () => _openInMaps(
                          _travelInfo?.toLocation ?? 'Bali, Indonesia',
                        ),
                        child: const Text(
                          'Open in maps',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.open_in_new,
                        color: Colors.blue,
                        size: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildTravelInfoWidget(),
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

  Widget _buildTravelInfoWidget() {
    if (_loadingTravelInfo) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentTeal),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Getting travel information...',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      );
    }

    if (_travelInfo != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_travelInfo!.fromLocation} to ${_travelInfo!.toLocation}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_travelInfo!.duration.isNotEmpty &&
              !_travelInfo!.duration.contains('unavailable')) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _travelInfo!.mode == 'flight'
                      ? Icons.flight
                      : Icons.directions_car,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${_travelInfo!.duration}${_travelInfo!.distance.isNotEmpty && !_travelInfo!.distance.contains('unavailable') ? ' • ${_travelInfo!.distance}' : ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ],
        ],
      );
    }

    // Fallback for when location services are not available
    return Text(
      'Travel information unavailable',
      style: TextStyle(color: Colors.grey[600], fontSize: 14),
    );
  }

  Widget _buildDaySection(int dayNumber, ItineraryDay day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Day $dayNumber: ${day.summary}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...day.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, right: 12),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.textPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                          height: 1.6,
                        ),
                        children: [
                          if (item.time.isNotEmpty) ...[
                            TextSpan(
                              text: '${item.time}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          TextSpan(text: item.activity),
                          if (item.location.isNotEmpty) ...[
                            TextSpan(
                              text: ' at ${item.location}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ],
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
