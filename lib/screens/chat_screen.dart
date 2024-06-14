import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  static const String id = 'ChatScreen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  User? loggedInUser;
  String? messageText;

  // Names in Firebase Firestore
  static const String MESSAGES_COLLECTION = 'messages';
  static const String SENDER_FIELD = 'sender';
  static const String TEXT_FIELD = 'text';

  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        debugPrint('Logged in user is ${loggedInUser!.email}');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void messagesStream() async {
    await for (var snapshot
        in _firestore.collection(MESSAGES_COLLECTION).snapshots()) {
      for (var message in snapshot.docs) {
        debugPrint(message.data().toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () async {
                debugPrint('Log out attempted for ${loggedInUser!.email}');

                try {
                  await _auth.signOut();
                  User? user = await _auth.currentUser;
                  loggedInUser = user;
                  debugPrint('User email is - ${loggedInUser?.email}');
                } catch (e) {
                  debugPrint(e.toString());
                }

                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  Column(children: [
                    TextButton(
                        onPressed: () {
                          messagesStream();
                        },
                        child: Text('debug print')),
                    TextButton(
                      onPressed: () {
                        final Map<String, dynamic> message_data = {
                          SENDER_FIELD: loggedInUser!.email,
                          TEXT_FIELD: messageText,
                        };
                        _firestore
                            .collection(MESSAGES_COLLECTION)
                            .add(message_data);
                      },
                      child: Text(
                        'Send',
                        style: kSendButtonTextStyle,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
