import 'package:chatapp/CustomUI/OwnMessgaeCrad.dart';
import 'package:chatapp/CustomUI/ReplyCard.dart';
import 'package:chatapp/Model/ChatModel.dart';
import 'package:chatapp/Model/MessageModel.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:intl/intl.dart'; // Import intl for date formatting
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class IndividualPage extends StatefulWidget {
  const IndividualPage({Key? key, required this.chatModel, required this.sourchat})
      : super(key: key);
  final ChatModel chatModel;
  final ChatModel sourchat;
  @override
  _IndividualPageState createState() => _IndividualPageState();
}

class _IndividualPageState extends State<IndividualPage> {
  bool show = false;
  FocusNode focusNode = FocusNode();
  bool sendButton = false;
  List<MessageModel> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  IO.Socket? socket;
  String? _lastSeen; // To store the last seen status

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  @override
  void initState() {
    super.initState();
    _lastSeen = "last seen today at 12:05"; // Initial value

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        setState(() {
          show = false;
        });
      }
    });
    //connect();  // Removed socket connection - using Firebase
    _loadMessages();
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    _controller.dispose();
    _scrollController.dispose();
    focusNode.dispose();
    super.dispose();
  }
  Future<void> _loadMessages() async {
    setState(() {
      messages = [];
    });

    try {
      _firestore
          .collection('messages')
          .where('chatId', isEqualTo: widget.chatModel.uid)
          .orderBy('time', descending: false)
          .snapshots()
          .listen((snapshot) {
        setState(() {
          messages = snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return MessageModel(
              type: data['type'],
              message: data['text'],
              time: DateFormat('MMM d, h:mm a').format((data['time'] as Timestamp).toDate()), // Format timestamp
              senderId: data['senderId'],
              senderName: data['senderName'], // Add senderName
              senderIcon: data['senderIcon'], // Add senderIcon
            );
          }).toList();
        });
        // Scroll to the latest message after loading messages
        if (messages.isNotEmpty) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error loading messages: $e');
      // Handle error
    }
  }
  Future<void> _sendMessage() async {
    String text = _controller.text.trim();
    if (text.isNotEmpty) {
      final String senderId = _auth.currentUser!.uid;
      final String messageId = _firestore.collection('messages').doc().id;
      final Timestamp time = Timestamp.now();

      try {
        // Get user document to retrieve username and profileImageUrl
        DocumentSnapshot userDoc =
        await _firestore.collection('username').doc(senderId).get();

        // Add this line:
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        String senderName = userData['username'] ?? "Unknown";
        String senderIcon = userData['profileImageUrl'] ?? "person";

        // Create a new message document
        await _firestore.collection('messages').doc(messageId).set({
          'chatId': widget.chatModel.uid,
          'senderId': senderId,
          'text': text,
          'time': time,
          'type': 'text',
          'senderName': senderName, // Add senderName
          'senderIcon': senderIcon, // Add senderIcon
        });

        // Update lastMessage in the chat document
        await _firestore.collection('chats').doc(widget.chatModel.uid).update({
          'lastMessage': {
            'text': text,
            'senderId': senderId,
            'time': time,
          },
        });
        _controller.clear();
        setState(() {
          sendButton = false;
        });

        // Scroll to the latest message after sending
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (e) {
        print('Error sending message: $e');
        // Handle the error appropriately
      }
    }

  }
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) {
          return;
        }
        if (show) {
          setState(() {
            show = false;
          });
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Image.asset(
              "assets/whatsapp_Back.png",
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.cover,
            ),
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: AppBar(
                  leadingWidth: 70,
                  titleSpacing: 0,
                  leading: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.arrow_back,
                          size: 24,
                        ),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.blueGrey,
                          child: SvgPicture.asset(
                            (widget.chatModel.isGroup ?? false)
                                ? "assets/groups.svg"
                                : "assets/person.svg",
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            height: 36,
                            width: 36,
                          ),
                        ),
                      ],
                    ),
                  ),
                  title: InkWell(
                    onTap: () {
                      // Handle tap on the title
                    },
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.chatModel.name ?? "No Name",
                            style: const TextStyle(
                              fontSize: 18.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _lastSeen ?? " ",
                            style: const TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    //IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
                    //IconButton(icon: const Icon(Icons.call), onPressed: () {}),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        // Handle menu item selection
                      },
                      itemBuilder: (BuildContext context) {
                        return const [
                          PopupMenuItem(
                            value: "View Contact",
                            child: Text("View Contact"),
                          ),
                          PopupMenuItem(
                            value: "Media, links, and docs",
                            child: Text("Media, links, and docs"),
                          ),
                          PopupMenuItem(
                            value: "Whatsapp Web",
                            child: Text("Whatsapp Web"),
                          ),
                          PopupMenuItem(
                            value: "Search",
                            child: Text("Search"),
                          ),
                          PopupMenuItem(
                            value: "Mute Notification",
                            child: Text("Mute Notification"),
                          ),
                          PopupMenuItem(
                            value: "Wallpaper",
                            child: Text("Wallpaper"),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
              ),
              body: SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          if (message.senderId == _auth.currentUser!.uid) {
                            // It's an own message
                            return OwnMessageCard(
                              message: message.message ?? "",
                              time: message.time ?? "",
                            );
                          } else {
                            return ReplyCard(
                              message: message.message ?? "",
                              time: message.time ?? "",
                            );
                          }
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        height: 70,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width - 60,
                                  child: Card(
                                    margin: const EdgeInsets.only(left: 2, right: 2, bottom: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: TextFormField(
                                      controller: _controller,
                                      focusNode: focusNode,
                                      textAlignVertical: TextAlignVertical.center,
                                      keyboardType: TextInputType.multiline,
                                      maxLines: 5,
                                      minLines: 1,
                                      onChanged: (value) {
                                        setState(() {
                                          sendButton = value.isNotEmpty;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: "Type a message",
                                        hintStyle: const TextStyle(color: Colors.grey),
                                        prefixIcon: IconButton(
                                          icon: Icon(
                                            show ? Icons.keyboard : Icons.emoji_emotions_outlined,
                                          ),
                                          onPressed: () {
                                            if (!show) {
                                              focusNode.unfocus();
                                              focusNode.canRequestFocus = false;
                                            }
                                            setState(() {
                                              show = !show;
                                            });
                                          },
                                        ),
                                        suffixIcon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.attach_file),
                                              onPressed: () {
                                                showModalBottomSheet(
                                                  backgroundColor: Colors.transparent,
                                                  context: context,
                                                  builder: (builder) => bottomSheet(),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.camera_alt),
                                              onPressed: () {},
                                            ),
                                          ],
                                        ),
                                        contentPadding: const EdgeInsets.all(5),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8, right: 2, left: 2),
                                  child: CircleAvatar(
                                    radius: 25,
                                    backgroundColor: const Color(0xFF128C7E),
                                    child: IconButton(
                                      icon: Icon(
                                        sendButton ? Icons.send : Icons.mic,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        if (sendButton) {
                                          _sendMessage();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            show ? emojiSelect() : Container(),
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
      ),
    );
  }

  Widget bottomSheet() {
    return SizedBox(
      height: 120,
      width: MediaQuery.of(context).size.width,
      child: Card(
        margin: const EdgeInsets.all(18.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconCreation(Icons.camera_alt, Colors.pink, "Camera"),
                  const SizedBox(width: 30),
                  iconCreation(Icons.insert_photo, Colors.purple, "Gallery"),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget iconCreation(IconData icons, Color color, String text) {
    return InkWell(
      onTap: () {
        // Handle the tap
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(
              icons,
              size: 29,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget emojiSelect() {
    return EmojiPicker(
      onEmojiSelected: (Category? category, Emoji emoji) {
        setState(() {
          _controller.text += emoji.emoji;
        });
      },
    );
  }
}