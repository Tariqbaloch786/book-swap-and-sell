import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/supabase_service.dart';
import 'add_book_screen.dart';
import 'chat_screen.dart';
import 'chat_list_screen.dart';
import 'book_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Book> _allBooks = [];
  List<Book> _myBooks = [];
  bool _isLoading = true;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _loadBooks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    try {
      final allBooks = await SupabaseService.getBooks();
      final myBooks = await SupabaseService.getMyBooks();

      // Debug: Print book data to see what's coming from database
      for (var book in allBooks) {
        debugPrint('Book: ${book.title}');
        debugPrint('  imageUrl: ${book.imageUrl}');
        debugPrint('  ownerEmail: ${book.ownerEmail}');
      }

      setState(() {
        _allBooks = allBooks;
        _myBooks = myBooks;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.signOut();
    }
  }

  void _showAccountOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: Text(SupabaseService.currentUser?.email ?? 'User'),
              subtitle: const Text('Logged in as'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBookOptions(Book book) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Mark as Sold'),
              onTap: () async {
                Navigator.pop(context);
                await SupabaseService.updateBookStatus(book.id!, 'sold');
                _loadBooks();
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.orange),
              title: const Text('Mark as Swapped'),
              onTap: () async {
                Navigator.pop(context);
                await SupabaseService.updateBookStatus(book.id!, 'swapped');
                _loadBooks();
              },
            ),
            if (book.status != 'available')
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.blue),
                title: const Text('Mark as Available'),
                onTap: () async {
                  Navigator.pop(context);
                  await SupabaseService.updateBookStatus(book.id!, 'available');
                  _loadBooks();
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Book'),
                    content: const Text(
                        'Are you sure you want to delete this book?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await SupabaseService.deleteBook(book.id!);
                  _loadBooks();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _contactSeller(Book book) async {
    final chatRoom =
        await SupabaseService.getOrCreateChatRoom(book.id!, book.userId);
    if (chatRoom != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatRoomId: chatRoom.id,
            bookTitle: book.title,
            otherUserEmail: book.ownerEmail ?? 'Seller',
          ),
        ),
      );
    }
  }

  void _openBookDetail(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(book: book),
      ),
    );
  }

  Widget _buildBookCard(Book book, bool isMyBook) {
    final currentUserId = SupabaseService.currentUser?.id;

    return GestureDetector(
      onTap: () => _openBookDetail(book),
      child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: book.imageUrl != null
                ? Image.network(
                    book.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: Colors.grey[200],
                      child:
                          const Icon(Icons.book, size: 60, color: Colors.grey),
                    ),
                  )
                : Container(
                    height: 180,
                    color: Colors.grey[200],
                    child:
                        const Icon(Icons.book, size: 60, color: Colors.grey),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        book.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!book.isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: book.status == 'sold'
                              ? Colors.red[100]
                              : Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          book.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: book.status == 'sold'
                                ? Colors.red[700]
                                : Colors.orange[700],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Author
                Text(
                  'by ${book.author}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                // Description
                if (book.description != null)
                  Text(
                    book.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                const SizedBox(height: 12),
                // Price/Swap Tag and Actions
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: book.isSwap ? Colors.green : Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        book.isSwap
                            ? 'For Swap'
                            : '\$${book.price?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Show owner email for other's books
                    if (!isMyBook && book.ownerEmail != null)
                      Expanded(
                        child: Text(
                          book.ownerEmail!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    // Actions
                    if (isMyBook)
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showBookOptions(book),
                      )
                    else if (book.userId != currentUserId && book.isAvailable)
                      ElevatedButton.icon(
                        onPressed: () => _contactSeller(book),
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text('Contact'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildBookList(List<Book> books, bool isMyBooks) {
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isMyBooks ? 'You haven\'t posted any books yet' : 'No books available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (isMyBooks) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddBookScreen()),
                  );
                  if (result == true) _loadBooks();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Your First Book'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBooks,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: books.length,
        itemBuilder: (context, index) =>
            _buildBookCard(books[index], isMyBooks),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BookSwap'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Books', icon: Icon(Icons.public)),
            Tab(text: 'My Books', icon: Icon(Icons.person)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'Messages',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Account',
            onPressed: _showAccountOptions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookList(_allBooks, false),
                _buildBookList(_myBooks, true),
              ],
            ),
      floatingActionButton: _currentTabIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddBookScreen()),
                );
                if (result == true) _loadBooks();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Book'),
            )
          : null,
    );
  }
}
