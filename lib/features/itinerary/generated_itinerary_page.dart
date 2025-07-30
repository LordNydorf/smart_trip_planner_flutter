import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive/hive.dart';
import '../../models/itinerary_model.dart';
import '../itinerary/itinerary_controller.dart';

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
      appBar: AppBar(
        title: const Text('Generated Itinerary'),
        actions: [
          if (state.generatedItinerary != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => _saveItinerary(state.generatedItinerary!),
            ),
        ],
      ),
      body: _buildBody(state),
      floatingActionButton: state.generatedItinerary != null
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToChat(),
              icon: const Icon(Icons.edit),
              label: const Text('Refine'),
            )
          : null,
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text(
                'Creating your itinerary...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (streamedContent.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Response:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    streamedContent,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 2,
                    height: 20,
                    color: Theme.of(context).primaryColor,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItineraryWidget(Itinerary itinerary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itinerary.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatDate(itinerary.startDate)} - ${_formatDate(itinerary.endDate)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${itinerary.days.length} days',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Days
          ...itinerary.days.asMap().entries.map((entry) {
            final dayIndex = entry.key;
            final day = entry.value;
            return _buildDayCard(dayIndex + 1, day);
          }),
        ],
      ),
    );
  }

  Widget _buildDayCard(int dayNumber, ItineraryDay day) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  radius: 16,
                  child: Text(
                    dayNumber.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Day $dayNumber',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDate(day.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              day.summary,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            ...day.items.map((item) => _buildItineraryItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildItineraryItem(ItineraryItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.time,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.activity,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.location,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.map, size: 20),
                      onPressed: () => _openInMaps(item.location),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
