import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../database/database_helper.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../widgets/post_card.dart';
import 'add_edit_post_screen.dart';
import 'post_detail_screen.dart';
import 'login_screen.dart';

class PostsScreen extends StatefulWidget {
  final User user;
  const PostsScreen({super.key, required this.user});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Post> _posts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _postCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final posts = await _dbHelper.getAllPosts(widget.user.id!);
      final count = await _dbHelper.getPostCount(widget.user.id!);

      setState(() {
        _posts = posts;
        _postCount = count;
        _isLoading = false;
      });

      print('✅ Loaded ${posts.length} posts for user ${widget.user.name}');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load posts: ${e.toString()}';
        _isLoading = false;
      });

      Fluttertoast.showToast(
        msg: 'Error loading posts',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _deletePost(Post post) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text('Delete Post'),
        content: Text('Are you sure you want to delete "${post.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final result =
                    await _dbHelper.deletePost(post.id!, widget.user.id!);
                if (result > 0) {
                  setState(() {
                    _posts.removeWhere((p) => p.id == post.id);
                    _postCount--;
                  });

                  Fluttertoast.showToast(
                    msg: 'Post deleted successfully',
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                  );
                }
              } catch (e) {
                Fluttertoast.showToast(
                  msg: 'Failed to delete post: ${e.toString()}',
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
                (route) => false,
              );
              Fluttertoast.showToast(
                msg: 'Logged out successfully',
                backgroundColor: Colors.green,
                textColor: Colors.white,
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Offline Posts Manager',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_postCount',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPosts,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'clear_all') {
                await _showClearAllDialog();
              } else if (value == 'stats') {
                _showStatsDialog();
              } else if (value == 'logout') {
                _logout();
              }
            },
            icon: const Icon(Icons.account_circle),
            tooltip: 'Account',
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'account',
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 20, color: Colors.teal),
                    const SizedBox(width: 12),
                    Text(widget.user.name),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, size: 20, color: Colors.teal),
                    SizedBox(width: 12),
                    Text('Statistics'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Clear All Posts',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                  SizedBox(height: 20),
                  Text('Loading posts...'),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadPosts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.storage_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No posts available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tap + button to create your first post',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPosts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          final post = _posts[index];
                          return PostCard(
                            post: post,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PostDetailScreen(post: post),
                                ),
                              );
                              if (result == true) {
                                _loadPosts();
                              }
                            },
                            onEdit: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEditPostScreen(
                                    post: post,
                                    isEditing: true,
                                    userId: widget.user.id!,
                                  ),
                                ),
                              );
                              if (result == true) {
                                _loadPosts();
                              }
                            },
                            onDelete: () => _deletePost(post),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditPostScreen(
                isEditing: false,
                userId: widget.user.id!,
              ),
            ),
          );
          if (result == true) {
            _loadPosts();
            Fluttertoast.showToast(
              msg: 'New post added!',
              backgroundColor: Colors.green,
              textColor: Colors.white,
            );
          }
        },
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
      ),
    );
  }

  Future<void> _showClearAllDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text('Clear All Posts'),
        content: const Text(
          'Are you sure you want to delete ALL your posts?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final result = await _dbHelper.deleteAllPosts(widget.user.id!);
                if (result > 0) {
                  _loadPosts();
                  Fluttertoast.showToast(
                    msg: 'All posts cleared',
                    backgroundColor: Colors.orange,
                    textColor: Colors.white,
                  );
                }
              } catch (e) {
                Fluttertoast.showToast(
                  msg: 'Failed to clear posts',
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text('Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('User', widget.user.name),
            _buildStatRow('Email', widget.user.email),
            const Divider(),
            _buildStatRow('Total Posts', _postCount.toString()),
            _buildStatRow('Database', 'SQLite'),
            _buildStatRow('Storage', 'Local Device'),
            _buildStatRow('Member Since', _formatDate(widget.user.createdAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(
                  color: Colors.teal, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
