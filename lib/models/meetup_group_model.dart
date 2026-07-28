import 'package:cloud_firestore/cloud_firestore.dart';

class MeetupGroup {
  final String id;
  final String name;
  final String category;
  final String description;
  final String createdBy;
  final String createdByName;
  final double latitude;
  final double longitude;
  final List<String> memberIds;
  final Map<String, String> memberDetails;
  final int maxMembers;
  final String status;
  final DateTime createdAt;
  final String eventType;
  final DateTime? scheduledAt;
  final String? imageUrl;
  final bool isPrivate;
  final String? inviteCode;
  final List<String> waitlistIds;
  final Map<String, String> waitlistDetails;
  final List<String> checkedInIds;
  final String? checkInCode;
  final bool approvalRequired;
  

  MeetupGroup({
    required this.id,
    required this.name,
    required this.category,
    this.description = '',
    required this.createdBy,
    required this.createdByName,
    required this.latitude,
    required this.longitude,
    required this.memberIds,
    required this.memberDetails,
    required this.maxMembers,
    required this.status,
    required this.createdAt,
    this.eventType = 'instant',
    this.scheduledAt,
    this.imageUrl,
    this.isPrivate = false,
    this.approvalRequired = false,
    this.inviteCode,
    this.waitlistIds = const [],
    this.waitlistDetails = const {},
    this.checkedInIds = const [],
    this.checkInCode,
  });

  bool get isFull => memberIds.length >= maxMembers;
  bool get isScheduled => eventType == 'scheduled' && scheduledAt != null;
  bool get isUpcoming => isScheduled && scheduledAt!.isAfter(DateTime.now());
  bool isCheckedIn(String? uid) => uid != null && checkedInIds.contains(uid);

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'latitude': latitude,
      'longitude': longitude,
      'memberIds': memberIds,
      'memberDetails': memberDetails,
      'maxMembers': maxMembers,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'eventType': eventType,
      'scheduledAt':
          scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'imageUrl': imageUrl,
      'isPrivate': isPrivate,
      'inviteCode': inviteCode,
      'waitlistIds': waitlistIds,
      'waitlistDetails': waitlistDetails,
      'checkedInIds': checkedInIds,
      'checkInCode': checkInCode,
      'approvalRequired': approvalRequired,
    };
  }

  factory MeetupGroup.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MeetupGroup(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? 'User',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      memberIds: List<String>.from(data['memberIds'] ?? []),
      memberDetails: Map<String, String>.from(data['memberDetails'] ?? {}),
      maxMembers: data['maxMembers'] ?? 10,
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      eventType: data['eventType'] ?? 'instant',
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate(),
      imageUrl: data['imageUrl'],
      isPrivate: data['isPrivate'] ?? false,
      approvalRequired: data['approvalRequired'] ?? false,
      inviteCode: data['inviteCode'],
      waitlistIds: List<String>.from(data['waitlistIds'] ?? []),
      waitlistDetails: Map<String, String>.from(data['waitlistDetails'] ?? {}),
      checkedInIds: List<String>.from(data['checkedInIds'] ?? []),
      checkInCode: data['checkInCode'],
    );
  }
}