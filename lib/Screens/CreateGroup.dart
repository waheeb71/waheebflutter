import 'package:chatapp/CustomUI/AvtarCard.dart';
import 'package:chatapp/CustomUI/ButtonCard.dart';
import 'package:chatapp/CustomUI/ContactCard.dart';
import 'package:chatapp/Model/ChatModel.dart';
import 'package:chatapp/Screens/IndividualPage.dart'; // Import IndividualPage
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateGroup extends StatefulWidget {
  const CreateGroup({Key? key}) : super(key: key); // Add const here
  @override
  _CreateGroupState createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _username; // To store the username of the creator
  bool _isLoading = false; // Add loading state
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  ChatModel? _foundContact;

  List<ChatModel> groupmember = [];

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userDoc =
      await _firestore.collection('username').doc(_auth.currentUser!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _username = userDoc.data()!['username'];
        });
      }
    } catch (e) {
      print("Error loading username: $e");
      // Handle error (e.g., show a snackbar)
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchForContact(String uid) async {
    setState(() {
      _isLoading = true;
      _foundContact = null; // Clear previous search
    });

    try {
      final userDoc = await _firestore.collection('username').doc(uid).get();

      if (userDoc.exists) {
        setState(() {
          _foundContact = ChatModel(
            name: userDoc.data()!['username'],
            status: 'Available', // You can fetch status if you have it
            uid: uid,
          );
        });
      } else {
        // Handle the case where the user is not found
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

  Future<void> _createGroupInFirebase() async {
    final String groupName = _groupNameController.text.trim();
    print("Group Name: '$groupName'");
    print("Username: '$_username'"); // Add this line
    if (groupName.isEmpty || _username == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name cannot be empty.')),
      );
      return;
    }

    if (groupmember.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String chatId = _firestore.collection('chats').doc().id;

      // Extract member UIDs
      List<String> memberUids = [_auth.currentUser!.uid]; // Add creator

      memberUids.addAll(groupmember.map((member) => member.uid!).toList());

      await _firestore.collection('chats').doc(chatId).set({
        'chatId': chatId,
        'isGroup': true,
        'isPublic': true, // Set to public by default
        'members': memberUids,
        'admins': [_auth.currentUser!.uid], // Add the creator as admin
        'groupName': groupName,
        'groupIcon':
        'https://firebasestorage.googleapis.com/v0/b/flutter-chat-app-academind.appspot.com/o/group_default.png?alt=media&token=43036c2b-5d99-475d-8f20-5f1ef918f5cc', // Default group image URL
        'lastMessage': {
          'text': '',
          'senderId': '',
          'time': null,
        },
        'createdBy': _auth.currentUser!.uid,
        'createdByUsername': _username,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add the group to each member's document
      for (String memberUid in memberUids) {
        await _firestore.collection('username').doc(memberUid).update({
          'groups': FieldValue.arrayUnion([chatId])
        });
      }

      Navigator.pop(context); // Go back to the previous screen after creation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group created successfully!')),
      );
    } catch (e) {
      print("Error creating group: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create group: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToConversationAndSave(ChatModel chatModel) async {
    try {
      // Navigate to the conversation screen (replace IndividualPage with your actual conversation screen)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IndividualPage(
            chatModel: chatModel,
            sourchat: ChatModel(name: _username ?? "", isGroup: false, id: 0, uid: _auth.currentUser!.uid), // Provide sourchat
          ),
        ),
      );

      // Save the user or group to the user's data
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = _firestore.collection('username').doc(user.uid);

        if (chatModel.isGroup == true) {
          // It's a group, add the group ID to the user's groups list
          await userDoc.update({
            'groups': FieldValue.arrayUnion([chatModel.uid])
          });
        } else {
          // It's a contact, add the contact UID to the user's contacts list
          await userDoc.update({
            'contacts': FieldValue.arrayUnion([chatModel.uid])
          });
        }

        // Optionally, show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${chatModel.name} added to your chats.')),
        );
      }
    } catch (e) {
      print('Error saving contact/group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save contact/group.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "New Group",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Add participants",
                style: TextStyle(
                  fontSize: 13,
                ),
              )
            ],
          ),
          actions: [
            IconButton(
                icon: const Icon(
                  Icons.search,
                  size: 26,
                ),
                onPressed: () {}),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF128C7E),
          onPressed: _isLoading
              ? null
              : () {
            showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Group Name"),
                    content: TextField(
                      controller: _groupNameController,
                      decoration: const InputDecoration(
                        hintText: "Enter Group Name",
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _createGroupInFirebase();
                        },
                        child: const Text("Create"),
                      ),
                    ],
                  );
                });
          },
          child: _isLoading
              ? const CircularProgressIndicator(
            color: Colors.white,
          )
              : const Icon(Icons.arrow_forward),
        ),
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
                ? InkWell(
                onTap: () {
                  setState(() {
                    if (groupmember.contains(_foundContact)) {
                      groupmember.remove(_foundContact);
                    } else {
                      groupmember.add(_foundContact!);
                    }
                    _foundContact = null;
                    _searchController.clear();
                  });
                },
                child: ContactCard(contact: _foundContact!))
                : Container(),
            Expanded(
              child: ListView.builder(
                itemCount: groupmember.length,
                itemBuilder: (context, index) {
                  return InkWell(  // Wrap AvatarCard with InkWell
                    onTap: () {
                      _navigateToConversationAndSave(groupmember[index]);
                    },
                    child: AvatarCard(
                      chatModel: groupmember[index],
                    ),
                  );
                },
              ),
            ),
          ],
        ));
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}