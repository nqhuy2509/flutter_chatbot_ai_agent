import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:rxdart/rxdart.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path_provider/path_provider.dart';

class Chat extends StatefulWidget {
  Chat({Key? key}) : super(key: key);

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final List<ChatMessage> _messages = <ChatMessage>[];
  final TextEditingController _textController = TextEditingController();
  FlutterSoundRecorder? _recorder;
  StreamSubscription? _recorderStatus;
  StreamSubscription<List<int>>? _audioStreamSubscription;
  BehaviorSubject<List<int>>? _audioStream;
  bool _isRecording = false;
  String? _audioFilePath;

  // Google Generative AI API Key (Replace with your key)
  final String apiKey =;
  late GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    _recorder = FlutterSoundRecorder();
    initRecorder();
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    super.dispose();
  }

  Future<void> initRecorder() async {
    await _recorder?.openRecorder();
    await _recorder?.setSubscriptionDuration(const Duration(milliseconds: 500));
  }

  Future<void> stopRecording() async {
    try {
      await _recorder?.stopRecorder();
      setState(() => _isRecording = false);
      print('Recording saved at: $_audioFilePath');
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> startRecording() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _audioFilePath = '${directory.path}/recording.aac';

      await _recorder?.startRecorder(
        toFile: _audioFilePath!,
        codec: Codec.aacADTS,
      );

      setState(() => _isRecording = true);
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  void handleSubmitted(String text) async {
    if (text.isEmpty) return;
    _textController.clear();

    setState(() {
      _messages.insert(0, ChatMessage(text: text, name: 'You', type: true));
    });

    try {
      final response = await _model.generateContent([Content.text(text)]);
      String botReply = response.text ?? 'I could not process that.';

      setState(() {
        _messages.insert(
          0,
          ChatMessage(text: botReply, name: 'Bot', type: false),
        );
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Flexible(
          child: ListView.builder(
            padding: EdgeInsets.all(8.0),
            reverse: true,
            itemBuilder: (_, int index) => _messages[index],
            itemCount: _messages.length,
          ),
        ),
        Divider(height: 1.0),
        Container(
          decoration: BoxDecoration(color: Theme.of(context).cardColor),
          child: IconTheme(
            data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: Icon(_isRecording ? Icons.mic_off : Icons.mic),
                    onPressed: _isRecording ? stopRecording : startRecording,
                  ),
                  Flexible(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: handleSubmitted,
                      decoration: InputDecoration.collapsed(
                        hintText: "Send a message",
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () => handleSubmitted(_textController.text),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage({required this.text, required this.name, required this.type});

  final String text;
  final String name;
  final bool type;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: type ? _myMessage(context) : _otherMessage(context),
      ),
    );
  }

  List<Widget> _myMessage(context) {
    return <Widget>[
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(name, style: Theme.of(context).textTheme.bodySmall),
            Container(
              margin: const EdgeInsets.only(top: 5.0),
              child: Text(text),
            ),
          ],
        ),
      ),
      CircleAvatar(child: Text(name[0])),
    ];
  }

  List<Widget> _otherMessage(context) {
    return <Widget>[
      CircleAvatar(child: Text('B')),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              margin: const EdgeInsets.only(top: 5.0),
              child: Text(text),
            ),
          ],
        ),
      ),
    ];
  }
}
