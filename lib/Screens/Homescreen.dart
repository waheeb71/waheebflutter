import 'package:chatapp/CustomUI/CustomCard.dart';
import 'package:chatapp/Model/ChatModel.dart';
import 'package:chatapp/Pages/CameraPage.dart';
import 'package:chatapp/Pages/ChatPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatapp/Screens/SelectContact.dart'; // Import SelectContact
class Homescreen extends StatefulWidget {
  const Homescreen({Key? key}) : super(key: key);
  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen>
    with SingleTickerProviderStateMixin {
  late TabController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 4, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Whatsapp Clone"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "Settings") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              }
              print(value);
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: "New group",
                  child: Text("New group"),
                ),
                const PopupMenuItem(
                  value: "New broadcast",
                  child: Text("New broadcast"),
                ),
                const PopupMenuItem(
                  value: "Whatsapp Web",
                  child: Text("Whatsapp Web"),
                ),
                const PopupMenuItem(
                  value: "Starred messages",
                  child: Text("Starred messages"),
                ),
                const PopupMenuItem(
                  value: "Settings",
                  child: Text("Settings"),
                ),
              ];
            },
          )
        ],
        bottom: TabBar(
          controller: _controller,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.camera_alt),
            ),
            Tab(
              text: "CHATS",
            ),
            Tab(
              text: "STATUS",
            ),
            Tab(
              text: "CALLS",
            )
          ],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: [
          const CameraPage(),
          ChatPage(), // Pass the lists of chats to ChatPage
          const StatusPage(),
          const CallsPage(),
        ],
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<ChatModel> chatmodels = [];
  ChatModel sourchat = ChatModel(
      name: "Default User",
      isGroup: false,
      currentMessage: "",
      time: "",
      icon: "",
      id: 0);

  final TextEditingController _searchController = TextEditingController();
  ChatModel? _foundContact;
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
      chatmodels = []; // Clear existing chats
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
        await _firestore.collection('username').doc(user.uid).get();

        if (userDoc.exists) {
          List<dynamic> contactUids =
          List.from(userDoc.data()!['contacts'] ?? []);
          List<dynamic> groupIds = List.from(userDoc.data()!['groups'] ?? []);

          List<ChatModel> chats = [];

          // **إضافة هنا:**
          print('Fetching contacts...');
          for (String uid in contactUids.cast<String>()) {
            final contactDoc =
            await _firestore.collection('username').doc(uid).get();
            if (contactDoc.exists) {
              final data = contactDoc.data() as Map<String, dynamic>;
              chats.add(ChatModel(
                name: data['username'],
                isGroup: false,
                currentMessage: "",
                time: "",
                icon: data['profileImageUrl'] ?? "assets/person.svg",
                id: 1,
                lastSeen: data['lastSeen'] ?? "",
                uid: uid,
              ));
            }
          }
          // **إضافة هنا:**
          print('Finished fetching contacts.');

          // **إضافة هنا:**
          print('Fetching groups...');
          for (String groupId in groupIds.cast<String>()) {
            final groupDoc = await _firestore.collection('chats').doc(groupId).get();
            if (groupDoc.exists) {
              final data = groupDoc.data() as Map<String, dynamic>;
              chats.add(ChatModel(
                name: data['groupName'],
                isGroup: true,
                currentMessage: "",
                time: "",
                icon: data['groupIcon'] ?? "assets/groups.svg",
                id: 2,
                lastSeen: " ",
                uid: groupId,
              ));
            }
          }
          // **إضافة هنا:**
          print('Finished fetching groups.');

          setState(() {
            chatmodels = chats;
          });
        }
      }
    } catch (e) {
      print('Error loading chats: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading chats.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchForContact(String uid) async {
    setState(() {
      _isLoading = true;
      _foundContact = null;
    });

    try {
      final userDoc = await _firestore.collection('username').doc(uid).get();

      if (userDoc.exists) {
        setState(() {
          _foundContact = ChatModel(
            name: userDoc.data()!['username'],
            isGroup: false,
            currentMessage: "",
            time: "",
            icon: "person",
            id: 1,
            uid: uid,
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User with UID $uid not found.')),
        );
      }
    } catch (e) {
      print('Error searching for user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching for user.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Enter User ID',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _searchForContact(_searchController.text);
                  },
                ),
              ),
            ),
          ),
          _isLoading
              ? CircularProgressIndicator()
              : _foundContact != null
              ? CustomCard(
            chatModel: _foundContact!,
            sourchat: sourchat,
          )
              : Container(),
          Expanded(
            child: ListView.builder(
              itemCount: chatmodels.length,
              itemBuilder: (context, index) {
                return CustomCard(
                  chatModel: chatmodels[index],
                  sourchat: sourchat,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton( // Add FloatingActionButton
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (builder) => SelectContact())); // Navigate to SelectContact
        },
        child: Icon(Icons.add),
        backgroundColor: Color(0xFF128C7E),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
// Placeholder Widgets
class StatusPage extends StatelessWidget {
  const StatusPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Status Page Content"));
  }
}
class CallsPage extends StatelessWidget {
  const CallsPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Calls Page Content"));
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: const Center(child: Text("Settings Page Content")),
    );
  }
}