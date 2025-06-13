import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/chat_message_model.dart'; // Ensure this path is correct and contains 'class ChatMessage'
import '../../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String rideId;
  const ChatScreen({super.key, required this.rideId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Ride Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(widget.rideId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;
                return ListView(
                  children: messages.map((msg) => ListTile(
                    title: Text(msg.text),
                    subtitle: Text(msg.senderId == userId ? "You" : "Other"),
                  )).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(controller: _controller, decoration: const InputDecoration(hintText: "Type a message")),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (_controller.text.trim().isEmpty) return;
                    if (!await _chatService.canChat(widget.rideId)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chat is closed for this ride.")));
                      return;
                    }
                    await _chatService.sendMessage(
                      widget.rideId,
                      ChatMessage(
                        senderId: userId!,
                        text: _controller.text.trim(),
                        timestamp: DateTime.now(),
                      ),
                    );
                    _controller.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}