import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class VoiceInputService {
  static final VoiceInputService _instance = VoiceInputService._internal();
  factory VoiceInputService() => _instance;
  VoiceInputService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          _isListening = false;
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'notListening') {
            _isListening = false;
          }
        },
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Failed to initialize speech recognition: $e');
      return false;
    }
  }

  Future<bool> checkPermissions() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check if we already have permission
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    }

    // Request permission using system dialog
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
    Function()? onError,
    String locale = 'en_US',
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call();
        return;
      }
    }

    if (_isListening) {
      await stopListening();
    }

    try {
      _isListening = true;
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
            _isListening = false;
          } else if (onPartialResult != null) {
            onPartialResult(result.recognizedWords);
          }
        },
        localeId: locale,
        listenOptions: stt.SpeechListenOptions(
          partialResults: onPartialResult != null,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      _isListening = false;
      onError?.call();
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  Future<List<String>> getAvailableLocales() async {
    final locales = await _speech.locales();
    return locales.map((locale) => locale.localeId).toList();
  }

  void dispose() {
    _speech.cancel();
    _isListening = false;
  }
}

// Voice Input Widget for easy integration
class VoiceInputButton extends StatefulWidget {
  final Function(String) onResult;
  final Function(String)? onPartialResult;
  final Function()? onError;
  final String? tooltip;
  final Color? activeColor;
  final Color? inactiveColor;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.onPartialResult,
    this.onError,
    this.tooltip,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final VoiceInputService _voiceService = VoiceInputService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isListening = false;
  String _partialText = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    final hasPermission = await _voiceService.checkPermissions();
    if (!hasPermission) {
      // Permission was denied, show a simple snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for voice input'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _isListening = true;
      _partialText = '';
    });
    _animationController.forward();

    await _voiceService.startListening(
      onResult: (result) {
        setState(() {
          _isListening = false;
          _partialText = '';
        });
        _animationController.reverse();
        widget.onResult(result);
      },
      onPartialResult: widget.onPartialResult != null
          ? (partial) {
              setState(() => _partialText = partial);
              widget.onPartialResult!(partial);
            }
          : null,
      onError: () {
        setState(() {
          _isListening = false;
          _partialText = '';
        });
        _animationController.reverse();
        widget.onError?.call();
        _showErrorDialog();
      },
    );
  }

  Future<void> _stopListening() async {
    await _voiceService.stopListening();
    setState(() {
      _isListening = false;
      _partialText = '';
    });
    _animationController.reverse();
  }

  void _showErrorDialog() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition failed. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: IconButton(
                onPressed: _toggleListening,
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening
                      ? (widget.activeColor ?? Colors.red)
                      : (widget.inactiveColor ?? Colors.grey),
                ),
                tooltip:
                    widget.tooltip ??
                    (_isListening ? 'Stop listening' : 'Start voice input'),
              ),
            );
          },
        ),
        if (_partialText.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _partialText,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
