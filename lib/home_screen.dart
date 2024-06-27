import 'package:flutter/material.dart';
import 'package:giminichatapp/message_widget.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'env.dart'; // Import the env file

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  final FocusNode _textFieldFocus = FocusNode();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Content> _chatHistory = []; // Local list to manage chat history

  bool _loading = false;

  late stt.SpeechToText _speech; // Speech-to-text instance
  bool _isListening = false;
  String _voiceInput = '';

  late FlutterTts flutterTts; // Text-to-speech instance

  @override
  void initState() {
    super.initState();
    _initializeModel();
    _initializeSpeechToText();
    _initializeTextToSpeech();
  }

  void _initializeModel() {
    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-pro', // Replace with a valid model ID
        apiKey: Env.apiKey, // Use the loaded API key
        systemInstruction: Content.system('You are an AI that can chat about anything.'), // More general instruction
      );
      _chatSession = _model.startChat();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _initializeSpeechToText() {
    _speech = stt.SpeechToText();
    _speech.initialize(
      onStatus: (val) => setState(() => _isListening = val == 'listening'),
      onError: (val) => _showError('Speech recognition error: $val'),
    ).catchError((e) {
      _showError('Speech to Text initialization failed: $e');
    });
  }

  void _initializeTextToSpeech() {
    flutterTts = FlutterTts();
    flutterTts.setErrorHandler((msg) {
      _showError('Text to Speech error: $msg');
    });
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => setState(() => _isListening = val == 'listening'),
        onError: (val) => _showError('Speech recognition error: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _voiceInput = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _textController.text = _voiceInput;
              _sendChatMessage(_voiceInput);
            }
          }),
        );
      } else {
        setState(() => _isListening = false);
        _speech.stop();
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _speak(String text) async {
    try {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setPitch(1.0);
      await flutterTts.speak(text);
    } catch (e) {
      _showError("Error in TTS: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Build with Gemini',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Set title color to white
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final Content content = _chatHistory[index];
                final text = content.parts.whereType<TextPart>().map<String>((e) => e.text).join('');
                return MessageWidget(
                  text: text,
                  isFromUser: content.role == 'user',
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: true,
                    focusNode: _textFieldFocus,
                    decoration: textFieldDecoration(),
                    controller: _textController,
                    onSubmitted: _sendChatMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    _sendChatMessage(_textController.text);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: FloatingActionButton(
          onPressed: _listen,
          child: Icon(_isListening ? Icons.mic : Icons.mic_none),
        ),
      ),
    );
  }

  InputDecoration textFieldDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.all(15),
      hintText: 'Enter your message...',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25.0),
        borderSide: const BorderSide(color: Colors.blue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25.0),
        borderSide: const BorderSide(color: Colors.blue),
      ),
    );
  }

  Future<void> _sendChatMessage(String message) async {
    if (message.isEmpty) return;

    setState(() {
      _loading = true;
      _chatHistory.add(Content('user', [TextPart(message)])); // Add user message to chat history
    });

    try {
      final response = await _chatSession.sendMessage(Content.text(message));
      final text = response.text;
      if (text == null) {
        _showError('No response from API.');
        return;
      } else {
        setState(() {
          _chatHistory.add(Content('bot', [TextPart(text)])); // Add bot response to chat history
          _loading = false;
          _scrollDown();
        });
        _speak(text); // Speak out the bot response
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
      setState(() {
        _loading = false;
      });
    } finally {
      _textController.clear();
      setState(() {
        _loading = false;
      });
      _textFieldFocus.requestFocus();
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Oops, something went wrong'),
          content: SingleChildScrollView(
            child: SelectableText(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
