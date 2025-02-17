import 'package:chatapp/CustomUI/ButtonCard.dart';
import 'package:chatapp/CustomUI/ContactCard.dart';
import 'package:chatapp/Model/ChatModel.dart';
import 'package:chatapp/Screens/CreateGroup.dart';
import 'package:chatapp/Screens/IndividualPage.dart'; // Import IndividualPage
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SelectContact extends StatefulWidget {
  SelectContact({Key? key}) : super(key: key);

  @override
  _SelectContactState createState() => _SelectContactState();
}

class _SelectContactState extends State<SelectContact> {
  final TextEditingController _searchController = TextEditingController();
  ChatModel? _foundContact;
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _searchForContact(String searchTerm) async {
    setState(() {
      _isLoading = true;
      _foundContact = null; // Clear previous search
    });

    try {
      // Try searching for a user by UID
      DocumentSnapshot userDoc =
      await _firestore.collection('username').doc(searchTerm).get();

      if (userDoc.exists) {
        // Add this line:
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _foundContact = ChatModel(
            name: userData['username'],
            status: 'Available', // You can fetch status if you have it
            uid: searchTerm,
            isGroup: false,
            icon: userData['profileImageUrl'] ?? 'person',
          );
        });
        return; // Stop searching if user is found
      }

      // If no user found, try searching for a group by name
      QuerySnapshot groupQuery = await _firestore
          .collection('chats')
          .where('groupName', isEqualTo: searchTerm)
          .get();

      if (groupQuery.docs.isNotEmpty) {
        // Assuming group names are unique, take the first result
        DocumentSnapshot groupDoc = groupQuery.docs.first;

        // Add this line:
        Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;

        setState(() {
          _foundContact = ChatModel(
            name: groupData['groupName'],
            uid: groupDoc.id,
            isGroup: true,
            icon: groupData['groupIcon'] ?? 'groups',
          );
        });
        return; // Stop searching if group is found
      }

      // Handle the case where the user/group is not found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User/Group not found.')),
      );
    } catch (e) {
      print('Error searching: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching.')),
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
            sourchat: ChatModel(
                name: _auth.currentUser!.displayName ?? "Me",
                isGroup: false,
                id: 0,
                uid: _auth.currentUser!.uid), // Provide sourchat
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
            Text(
              "Select Contact",
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Search for user/group", // Changed text
              style: TextStyle(
                fontSize: 13,
              ),
            )
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            padding: EdgeInsets.all(0),
            onSelected: (value) {
              print(value);
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  child: Text("Refresh"),
                  value: "Refresh",
                ),
                PopupMenuItem(
                  child: Text("Help"),
                  value: "Help",
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Enter User ID or Group Name',
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
              _navigateToConversationAndSave(_foundContact!);
            },
            child: ContactCard(contact: _foundContact!),
          )
              : Container(), // Show nothing if no contact found
          Expanded(
            child: ListView(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (builder) => CreateGroup()));
                  },
                  child: ButtonCard(
                    key: ValueKey("new_group_button"), // Provide a Key
                    icon: Icons.group,
                    name: "New group",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}