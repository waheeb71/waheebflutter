class ChatModel {
  String? name;
  String? icon;
  bool? isGroup;
  String? time;
  String? currentMessage;
  String? status;
  bool? select = false;
  int? id;
  String? lastSeen;
  String? uid; // Add this line
  String?senderId;
  bool? unreadMessages;
  ChatModel({
    this.name,
    this.unreadMessages,
    this.senderId,
    this.icon,
    this.isGroup,
    this.time,
    this.currentMessage,
    this.status,
    this.select = false,
    this.id,
    this.lastSeen, // Add this line
    this.uid, // Add this line
  });
}