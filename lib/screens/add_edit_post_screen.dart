import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../database/database_helper.dart';
import '../models/post.dart';

class AddEditPostScreen extends StatefulWidget {
  final Post? post;
  final bool isEditing;
  final int userId;

  const AddEditPostScreen({
    super.key,
    this.post,
    required this.isEditing,
    required this.userId,
  });

  @override
  State<AddEditPostScreen> createState() => _AddEditPostScreenState();
}

class _AddEditPostScreenState extends State<AddEditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.post != null) {
      _titleController.text = widget.post!.title;
      _contentController.text = widget.post!.content;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();

      if (widget.isEditing) {
        // Update existing post
        final updatedPost = Post(
          id: widget.post!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          createdAt: widget.post!.createdAt,
          updatedAt: now,
        );

        final result = await _dbHelper.updatePost(updatedPost, widget.userId);

        if (result > 0 && mounted) {
          Fluttertoast.showToast(
            msg: 'Post updated successfully!',
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
          Navigator.pop(context, true);
        }
      } else {
        // Create new post
        final newPost = Post(
          id: null,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          createdAt: now,
          updatedAt: now,
        );

        final result = await _dbHelper.insertPost(newPost, widget.userId);

        if (result > 0 && mounted) {
          Fluttertoast.showToast(
            msg: 'Post created successfully!',
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error: ${e.toString()}',
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Post' : 'Create New Post',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Title *',
                          hintText: 'Enter post title',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          if (value.trim().length < 3) {
                            return 'Title must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _contentController,
                        maxLines: 10,
                        decoration: InputDecoration(
                          labelText: 'Content *',
                          hintText: 'Write your post content here...',
                          prefixIcon: const Icon(Icons.article),
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter content';
                          }
                          if (value.trim().length < 5) {
                            return 'Content must be at least 5 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Live Preview
              if (_titleController.text.isNotEmpty ||
                  _contentController.text.isNotEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preview',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _titleController.text.isEmpty
                              ? 'No title'
                              : _titleController.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _contentController.text.isEmpty
                              ? 'No content'
                              : _contentController.text,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.isEditing ? 'Update Post' : 'Create Post',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              if (widget.isEditing) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
