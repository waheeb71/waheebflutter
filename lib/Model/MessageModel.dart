class MessageModel {
  String? type;
  String? message;
  String? time;
  String? senderId;
  String? senderName; // Add this line
  String? senderIcon; // Add this line

  MessageModel({this.message, this.type, this.time, this.senderId, this.senderName, this.senderIcon}); // Modify constructor
}