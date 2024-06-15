import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
final _auth = FirebaseAuth.instance;
// Names in Firebase Firestore
const String MESSAGES_COLLECTION = 'messages';
const String SENDER_FIELD = 'sender';
const String TEXT_FIELD = 'text';

class ChatScreen extends StatefulWidget {
  static const String id = 'ChatScreen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController messageTextController = TextEditingController(text: "");

  User? loggedInUser;
  String? messageText;

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
            },
          ),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  Column(children: [
                    // TextButton(
                    //     onPressed: () {
                    //       messagesStream();
                    //     },
                    //     child: Text('debug print')),
                    TextButton(
                      onPressed: () {
                        if (messageText != null) {
                          final Map<String, dynamic> message_data = {
                            SENDER_FIELD: loggedInUser!.email,
                            TEXT_FIELD: messageText,
                          };
                          _firestore
                              .collection(MESSAGES_COLLECTION)
                              .add(message_data);

                          messageTextController.clear();
                        }
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

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection(MESSAGES_COLLECTION).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.lightBlueAccent,
              ),
            );
          }
          final messages = snapshot.data!.docs.reversed;
          List<MessageBubble> messageBubbles = [];
          for (var message in messages) {
            final messageData = message.data() as Map<String, dynamic>;
            final messageText = messageData[TEXT_FIELD];
            final messageSender = messageData[SENDER_FIELD];
            final messageBubble = MessageBubble(
                messageSender: messageSender, messageText: messageText);
            messageBubbles.add(messageBubble);
          }
          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              children: messageBubbles,
            ),
          );
        });
  }
}

class MessageBubble extends StatelessWidget {
  // const MessageBubble({super.key});

  MessageBubble({
    required this.messageSender,
    required this.messageText,
  });

  final String messageSender;
  final String messageText;

  @override
  Widget build(BuildContext context) {
    final bool isMe = FirebaseAuth.instance.currentUser!.email == messageSender;
    final double BUBBLE_RADIUS = 32.0;
    final BorderRadius pointingRight = BorderRadius.only(
      topLeft: Radius.circular(BUBBLE_RADIUS),
      bottomLeft: Radius.circular(BUBBLE_RADIUS),
      bottomRight: Radius.circular(BUBBLE_RADIUS),
    );
    final BorderRadius pointingLeft = BorderRadius.only(
      topRight: Radius.circular(BUBBLE_RADIUS),
      bottomLeft: Radius.circular(BUBBLE_RADIUS),
      bottomRight: Radius.circular(BUBBLE_RADIUS),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        // crossAxisAlignment: CrossAxisAlignment.start,
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                messageSender,
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 8.0,
          ),
          Material(
            color: isMe ? Colors.lightBlue : Colors.grey[600],
            borderRadius: isMe ? pointingRight : pointingLeft,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
              child: Text(
                '$messageText',
                style: TextStyle(fontSize: 16.0, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
