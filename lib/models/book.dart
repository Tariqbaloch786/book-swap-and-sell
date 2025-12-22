class Book {
  final String? id;
  final String userId;
  final String title;
  final String author;
  final String? description;
  final double? price;
  final bool isSwap;
  final String? imageUrl;
  final String status; // 'available', 'sold', 'swapped'
  final DateTime? createdAt;
  final String? ownerEmail;

  Book({
    this.id,
    required this.userId,
    required this.title,
    required this.author,
    this.description,
    this.price,
    this.isSwap = false,
    this.imageUrl,
    this.status = 'available',
    this.createdAt,
    this.ownerEmail,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      author: json['author'],
      description: json['description'],
      price: json['price']?.toDouble(),
      isSwap: json['is_swap'] ?? false,
      imageUrl: json['image_url'],
      status: json['status'] ?? 'available',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      ownerEmail: json['owner_email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'author': author,
      'description': description,
      'price': price,
      'is_swap': isSwap,
      'image_url': imageUrl,
      'status': status,
      'owner_email': ownerEmail,
    };
  }

  bool get isAvailable => status == 'available';
}

class ChatRoom {
  final String id;
  final String bookId;
  final String sellerId;
  final String buyerId;
  final DateTime createdAt;
  final Book? book;
  final String? otherUserEmail;

  ChatRoom({
    required this.id,
    required this.bookId,
    required this.sellerId,
    required this.buyerId,
    required this.createdAt,
    this.book,
    this.otherUserEmail,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json, String currentUserId) {
    String? otherEmail;
    if (json['seller_id'] == currentUserId) {
      final buyerProfile = json['buyer_profile'] as Map<String, dynamic>?;
      otherEmail = buyerProfile?['email'] as String?;
    } else {
      final sellerProfile = json['seller_profile'] as Map<String, dynamic>?;
      otherEmail = sellerProfile?['email'] as String?;
    }

    return ChatRoom(
      id: json['id'],
      bookId: json['book_id'],
      sellerId: json['seller_id'],
      buyerId: json['buyer_id'],
      createdAt: DateTime.parse(json['created_at']),
      book: json['books'] != null ? Book.fromJson(json['books']) : null,
      otherUserEmail: otherEmail,
    );
  }
}

class Message {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String message;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      chatRoomId: json['chat_room_id'],
      senderId: json['sender_id'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
