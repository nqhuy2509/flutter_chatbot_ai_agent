import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class Chat extends StatefulWidget {
  Chat({Key? key}) : super(key: key);

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final List<ChatMessage> _messages = <ChatMessage>[];
  final TextEditingController _textController = TextEditingController();
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  final String apiKey = 'YOUR_API_KEY';
  late GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    _speech.initialize();
  }

  void startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      showRecordingDialog();
      _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            handleSubmitted(result.recognizedWords);
          }
        },
      );
    }
  }

  void stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
    Navigator.of(context).pop();
  }

  void showRecordingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("Listening...", style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                ElevatedButton(onPressed: stopListening, child: Text("Stop")),
              ],
            ),
          ),
        );
      },
    );
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

  void cleanChat() {
    setState(() {
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bot Chat AI Agent'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      body: Column(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child:
                  _messages.isEmpty
                      ? Center(
                        child: Text(
                          'Start chatting with the bot!',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                      : ListView.builder(
                        padding: EdgeInsets.all(8.0),
                        reverse: true,
                        itemBuilder: (_, int index) => _messages[index],
                        itemCount: _messages.length,
                      ),
            ),
          ),
          if (_messages.isNotEmpty)
            ElevatedButton(onPressed: cleanChat, child: Text('Clear Chat')),
          SizedBox(height: 10),
          Divider(height: 1.0),

          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: IconTheme(
              data: IconThemeData(
                color: Theme.of(context).colorScheme.secondary,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                      onPressed: _isListening ? stopListening : startListening,
                    ),
                    Flexible(
                      child: TextField(
                        controller: _textController,
                        onSubmitted: handleSubmitted,
                        decoration: InputDecoration.collapsed(
                          hintText: "Send a message",
                        ),
                        style: TextStyle(fontSize: 16.0),
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
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final String name;
  final bool type; // true: user, false: bot

  const ChatMessage({
    super.key,
    required this.text,
    required this.name,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!type) CircleAvatar(child: Text(name[0])),
          if (!type) SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: type ? Colors.blue[100] : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: MarkdownBody(
                data: text, // Hiển thị nội dung Markdown
                selectable: true, // Cho phép chọn văn bản
              ),
            ),
          ),
          if (type) SizedBox(width: 10),
          if (type) CircleAvatar(child: Text(name[0])),
        ],
      ),
    );
  }
}
