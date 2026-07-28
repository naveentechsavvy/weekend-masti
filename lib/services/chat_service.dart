import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message_model.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ---------------- GROUP CHAT (all members of a meetup) ----------------

  Stream<List<ChatMessage>> groupMessagesStream(String groupId) {
    return _db
        .collection('meetup_groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatMessage.fromDoc(d)).toList());
  }

  Future<void> sendGroupMessage({
    required String groupId,
    required String text,
    required String senderName,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('You must be logged in.');
    if (text.trim().isEmpty) return;

    await _db
        .collection('meetup_groups')
        .doc(groupId)
        .collection('messages')
        .add({
      'senderId': uid,
      'senderName': senderName,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ---------------- DIRECT (1:1) CHAT ----------------

  String directChatId(String otherUid) {
    final uid = _uid;
    if (uid == null) throw Exception('You must be logged in.');
    final ids = [uid, otherUid]..sort();
    return ids.join('_');
  }

  Stream<List<ChatMessage>> directMessagesStream(String otherUid) {
    final chatId = directChatId(otherUid);
    return _db
        .collection('direct_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatMessage.fromDoc(d)).toList());
  }

  Future<void> sendDirectMessage({
    required String otherUid,
    required String otherName,
    required String text,
    required String senderName,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('You must be logged in.');
    if (text.trim().isEmpty) return;

    final chatId = directChatId(otherUid);
    final chatRef = _db.collection('direct_chats').doc(chatId);

    // Keep a parent doc with participants — needed for security rules / future "inbox" list
    await chatRef.set({
      'participants': [uid, otherUid],
      'participantNames': {uid: senderName, otherUid: otherName},
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await chatRef.collection('messages').add({
      'senderId': uid,
      'senderName': senderName,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}