import 'package:chatapp/CustomUI/CustomCard.dart';
import 'package:chatapp/Model/ChatModel.dart';
import 'package:chatapp/Screens/SelectContact.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key, required this.chatmodels, required this.sourchat})
      : super(key: key); // Use Key? and required
  final List<ChatModel> chatmodels;
  final ChatModel sourchat;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (builder) =>  SelectContact(), // Use const here
            ),
          );
        },
        child: const Icon( // Use const here
          Icons.chat,
          color: Colors.white,
        ),
      ),
      body: widget.chatmodels.isEmpty
          ? const Center(
        child: Text("No chats yet!"), // Handle empty list
      )
          : ListView.separated( // Use ListView.separated
        itemCount: widget.chatmodels.length,
        separatorBuilder: (context, index) => const Divider(), // Add divider
        itemBuilder: (context, index) => CustomCard(
          chatModel: widget.chatmodels[index],
          sourchat: widget.sourchat,
        ),
      ),
    );
  }
}