import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../auth/auth_controller.dart';
import '../../models/itinerary_model.dart';
import '../../services/voice_input_service.dart';
import '../../services/offline_mode_service.dart';

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
      appBar: AppBar(
        title: Text(
          'Hey${user?.displayName != null ? ', ${user!.displayName}' : ''}!',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineStatusBanner(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _promptController,
                    decoration: InputDecoration(
                      labelText: 'Describe your trip',
                      hintText:
                          'e.g., A weekend in Paris with museums and cafes',
                      border: const OutlineInputBorder(),
                      suffixIcon: VoiceInputButton(
                        onResult: (result) {
                          _promptController.text = result;
                        },
                        tooltip: 'Voice input',
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _createItinerary,
                      icon: const Icon(Icons.rocket_launch),
                      label: const Text('Create My Itinerary'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Offline Saved Itineraries',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: savedTripsBox.listenable(),
                      builder: (context, Box box, _) {
                        if (box.isEmpty) {
                          return const Center(
                            child: Text('No saved itineraries yet.'),
                          );
                        }

                        return ListView.builder(
                          itemCount: box.length,
                          itemBuilder: (context, index) {
                            final trip = box.getAt(index);
                            return Card(
                              child: ListTile(
                                title: Text(
                                  trip is Itinerary
                                      ? trip.title
                                      : trip['title'] ?? 'Untitled Trip',
                                ),
                                subtitle: Text(
                                  trip is Itinerary
                                      ? '${trip.days.length} days • ${_formatDate(trip.startDate)}'
                                      : trip['description'] ?? 'No description',
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  child: const Icon(
                                    Icons.flight_takeoff,
                                    color: Colors.white,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  // TODO: Navigate to trip details
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Trip details feature coming soon!',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
