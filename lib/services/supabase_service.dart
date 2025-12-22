import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://ucqxyfwevspfqbxqruhw.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjcXh5ZndldnNwZnFieHFydWh3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxMTIwNjUsImV4cCI6MjA4MDY4ODA2NX0.Hem9ixg6kPoNblppKMb1oL5WE3qeo-UC0PaDum6Sbnc';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // Auth methods
  static Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(email: email, password: password);
  }

  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static User? get currentUser => client.auth.currentUser;

  // Book methods
  static Future<List<Book>> getBooks() async {
    final response = await client
        .from('books')
        .select()
        .eq('status', 'available')
        .order('created_at', ascending: false);
    return (response as List).map((json) => Book.fromJson(json)).toList();
  }

  static Future<List<Book>> getMyBooks() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final response = await client
        .from('books')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List).map((json) => Book.fromJson(json)).toList();
  }

  static Future<void> addBook(Book book) async {
    await client.from('books').insert(book.toJson());
  }

  static Future<void> deleteBook(String id) async {
    await client.from('books').delete().eq('id', id);
  }

  static Future<void> updateBookStatus(String id, String status) async {
    await client.from('books').update({'status': status}).eq('id', id);
  }

  // Chat methods
  static Future<ChatRoom?> getOrCreateChatRoom(String bookId, String sellerId) async {
    final buyerId = currentUser?.id;
    if (buyerId == null) return null;

    // Check if chat room exists
    final existing = await client
        .from('chat_rooms')
        .select()
        .eq('book_id', bookId)
        .eq('seller_id', sellerId)
        .eq('buyer_id', buyerId)
        .maybeSingle();

    if (existing != null) {
      return ChatRoom.fromJson(existing, buyerId);
    }

    // Create new chat room
    final newRoom = await client
        .from('chat_rooms')
        .insert({
          'book_id': bookId,
          'seller_id': sellerId,
          'buyer_id': buyerId,
        })
        .select()
        .single();

    return ChatRoom.fromJson(newRoom, buyerId);
  }

  static Future<List<ChatRoom>> getMyChatRooms() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final response = await client
        .from('chat_rooms')
        .select('*, books(*)')
        .or('seller_id.eq.$userId,buyer_id.eq.$userId')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ChatRoom.fromJson(json, userId))
        .toList();
  }

  static Future<List<Message>> getMessages(String chatRoomId) async {
    final response = await client
        .from('messages')
        .select()
        .eq('chat_room_id', chatRoomId)
        .order('created_at', ascending: true);

    return (response as List).map((json) => Message.fromJson(json)).toList();
  }

  static Future<void> sendMessage(String chatRoomId, String message) async {
    final senderId = currentUser?.id;
    if (senderId == null) return;

    await client.from('messages').insert({
      'chat_room_id': chatRoomId,
      'sender_id': senderId,
      'message': message,
    });
  }

  static RealtimeChannel subscribeToMessages(
      String chatRoomId, void Function(Message) onMessage) {
    return client
        .channel('messages:$chatRoomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_room_id',
            value: chatRoomId,
          ),
          callback: (payload) {
            onMessage(Message.fromJson(payload.newRecord));
          },
        )
        .subscribe();
  }
}
