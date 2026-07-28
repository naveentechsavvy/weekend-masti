import 'package:cloud_firestore/cloud_firestore.dart';

class JoinRequest {
  final String id;
  final String groupId;
  final String groupName;
  final String organizerId;
  final String userId;
  final String userName;
  final String status;
  final DateTime requestedAt;

  JoinRequest({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.organizerId,
    required this.userId,
    required this.userName,
    required this.status,
    required this.requestedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "groupId": groupId,
      "groupName": groupName,
      "organizerId": organizerId,
      "userId": userId,
      "userName": userName,
      "status": status,
      "requestedAt": Timestamp.fromDate(requestedAt),
    };
  }

  factory JoinRequest.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return JoinRequest(
      id: doc.id,
      groupId: data["groupId"] ?? "",
      groupName: data["groupName"] ?? "",
      organizerId: data["organizerId"] ?? "",
      userId: data["userId"] ?? "",
      userName: data["userName"] ?? "",
      status: data["status"] ?? "pending",
      requestedAt:
          (data["requestedAt"] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}