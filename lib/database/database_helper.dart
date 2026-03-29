import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/post.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = join(directory.path, 'offline_posts.db');

      print('📁 Database path: $path');

      return await openDatabase(
        path,
        version: 2, // Incremented version for new table
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      print('❌ Database initialization error: $e');
      rethrow;
    }
  }

  // Create tables when database is first created
  Future<void> _onCreate(Database db, int version) async {
    try {
      print('🛠️ Creating database tables...');

      // Create users table
      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          created_at TEXT NOT NULL,
          last_login TEXT NOT NULL
        )
      ''');

      // Create posts table
      await db.execute('''
        CREATE TABLE posts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      print('✅ Tables created successfully');

      // Insert default admin user
      await _insertDefaultUser(db);

      // Insert sample posts for default user
      await _insertSamplePosts(db, 1);
    } catch (e) {
      print('❌ Error creating table: $e');
      throw Exception('Failed to create database table');
    }
  }

  // Handle database upgrade
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Add users table
      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          created_at TEXT NOT NULL,
          last_login TEXT NOT NULL
        )
      ''');

      // Add user_id column to posts table
      await db
          .execute('ALTER TABLE posts ADD COLUMN user_id INTEGER DEFAULT 1');

      // Add foreign key constraint
      await db.execute('''
        CREATE TABLE posts_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      // Copy data
      await db.execute('''
        INSERT INTO posts_new (id, user_id, title, content, created_at, updated_at)
        SELECT id, 1, title, content, created_at, updated_at FROM posts
      ''');

      await db.execute('DROP TABLE posts');
      await db.execute('ALTER TABLE posts_new RENAME TO posts');

      // Insert default user
      await _insertDefaultUser(db);
    }
  }

  // Insert default admin user
  Future<void> _insertDefaultUser(Database db) async {
    try {
      final now = DateTime.now().toIso8601String();

      // Check if user already exists
      final existing = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: ['admin@offlineposts.com'],
      );

      if (existing.isEmpty) {
        await db.insert('users', {
          'name': 'Admin User',
          'email': 'admin@offlineposts.com',
          'password': 'admin123', // In production, hash this!
          'created_at': now,
          'last_login': now,
        });
        print('✅ Default admin user created');
      }
    } catch (e) {
      print('⚠️ Error inserting default user: $e');
    }
  }

  // Insert sample posts for a user
  Future<void> _insertSamplePosts(Database db, int userId) async {
    try {
      final now = DateTime.now().toIso8601String();

      // Check if posts already exist
      final existing = await db.query(
        'posts',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (existing.isEmpty) {
        List<Map<String, dynamic>> samplePosts = [
          {
            'user_id': userId,
            'title': 'Welcome to Offline Posts Manager',
            'content':
                'This app works completely offline! All your posts are stored locally using SQLite database. You can create, read, update, and delete posts without internet connection.',
            'created_at': now,
            'updated_at': now,
          },
          {
            'user_id': userId,
            'title': 'How to Create a New Post',
            'content':
                'Tap the + button at the bottom right corner. Fill in the title and content, then save. Your post will be stored locally in the database.',
            'created_at': now,
            'updated_at': now,
          },
          {
            'user_id': userId,
            'title': 'Editing and Deleting Posts',
            'content':
                'Tap the three dots menu on any post card to edit or delete. You can also tap on a post to view its full content.',
            'created_at': now,
            'updated_at': now,
          },
          {
            'user_id': userId,
            'title': 'Your Data is Private',
            'content':
                'All your posts are stored locally on your device. No internet connection required. Your data stays private and secure.',
            'created_at': now,
            'updated_at': now,
          },
        ];

        for (var post in samplePosts) {
          await db.insert('posts', post);
        }

        print('✅ Sample posts inserted: ${samplePosts.length}');
      }
    } catch (e) {
      print('⚠️ Error inserting sample posts: $e');
    }
  }

  // ============ USER CRUD OPERATIONS ============

  // CREATE: Register new user
  Future<User?> registerUser(String name, String email, String password) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      // Check if email already exists
      final existing = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (existing.isNotEmpty) {
        throw Exception('Email already registered');
      }

      final user = {
        'name': name,
        'email': email,
        'password': password, // In production, hash this!
        'created_at': now,
        'last_login': now,
      };

      final id = await db.insert('users', user);
      print('✅ User registered with ID: $id');

      return User(
        id: id,
        name: name,
        email: email,
        password: password,
        createdAt: DateTime.parse(now),
        lastLogin: DateTime.parse(now),
      );
    } catch (e) {
      print('❌ Error registering user: $e');
      throw Exception('Registration failed: $e');
    }
  }

  // READ: Login user
  Future<User?> loginUser(String email, String password) async {
    try {
      final db = await database;

      final result = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, password],
      );

      if (result.isNotEmpty) {
        final user = User.fromMap(result.first);

        // Update last login time
        await db.update(
          'users',
          {'last_login': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [user.id],
        );

        print('✅ User logged in: ${user.email}');
        return user;
      }

      return null;
    } catch (e) {
      print('❌ Error logging in: $e');
      throw Exception('Login failed: $e');
    }
  }

  // READ: Get user by ID
  Future<User?> getUserById(int id) async {
    try {
      final db = await database;

      final result = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isNotEmpty) {
        return User.fromMap(result.first);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user: $e');
      return null;
    }
  }

  // UPDATE: Update user profile
  Future<int> updateUser(User user) async {
    try {
      final db = await database;
      final result = await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );

      print('✅ User ${user.id} updated');
      return result;
    } catch (e) {
      print('❌ Error updating user: $e');
      throw Exception('Failed to update user');
    }
  }

  // DELETE: Delete user account and all their posts
  Future<int> deleteUser(int userId) async {
    try {
      final db = await database;

      // Posts will be deleted automatically due to CASCADE
      final result = await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      print('🗑️ User $userId deleted');
      return result;
    } catch (e) {
      print('❌ Error deleting user: $e');
      throw Exception('Failed to delete user');
    }
  }

  // ============ POST CRUD OPERATIONS (Updated with user_id) ============

  // CREATE: Insert a new post for a user
  Future<int> insertPost(Post post, int userId) async {
    try {
      final db = await database;
      final result = await db.insert('posts', {
        'user_id': userId,
        'title': post.title,
        'content': post.content,
        'created_at': post.createdAt.toIso8601String(),
        'updated_at': post.updatedAt.toIso8601String(),
      });

      print('✅ Post inserted with ID: $result for user $userId');
      return result;
    } catch (e) {
      print('❌ Error inserting post: $e');
      throw Exception('Failed to insert post: $e');
    }
  }

  // READ: Get all posts for a specific user
  Future<List<Post>> getAllPosts(int userId) async {
    try {
      final db = await database;
      final result = await db.query(
        'posts',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'id DESC',
      );

      print('📊 Retrieved ${result.length} posts for user $userId');
      return result.map((map) => Post.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting posts: $e');
      throw Exception('Failed to load posts: $e');
    }
  }

  // READ: Get single post by ID
  Future<Post?> getPostById(int id, int userId) async {
    try {
      final db = await database;
      final result = await db.query(
        'posts',
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );

      if (result.isNotEmpty) {
        return Post.fromMap(result.first);
      }
      return null;
    } catch (e) {
      print('❌ Error getting post $id: $e');
      throw Exception('Failed to load post: $e');
    }
  }

  // UPDATE: Update an existing post
  Future<int> updatePost(Post post, int userId) async {
    try {
      final db = await database;
      final result = await db.update(
        'posts',
        {
          'title': post.title,
          'content': post.content,
          'updated_at': post.updatedAt.toIso8601String(),
        },
        where: 'id = ? AND user_id = ?',
        whereArgs: [post.id, userId],
      );

      print('✅ Post ${post.id} updated. Rows affected: $result');
      return result;
    } catch (e) {
      print('❌ Error updating post ${post.id}: $e');
      throw Exception('Failed to update post: $e');
    }
  }

  // DELETE: Delete a post
  Future<int> deletePost(int id, int userId) async {
    try {
      final db = await database;
      final result = await db.delete(
        'posts',
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );

      print('🗑️ Post $id deleted. Rows affected: $result');
      return result;
    } catch (e) {
      print('❌ Error deleting post $id: $e');
      throw Exception('Failed to delete post: $e');
    }
  }

  // DELETE: Delete all posts for a user
  Future<int> deleteAllPosts(int userId) async {
    try {
      final db = await database;
      final result = await db.delete(
        'posts',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      print('🗑️ All posts for user $userId deleted: $result');
      return result;
    } catch (e) {
      print('❌ Error deleting all posts: $e');
      throw Exception('Failed to clear posts: $e');
    }
  }

  // Count total posts for a user
  Future<int> getPostCount(int userId) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM posts WHERE user_id = ?',
        [userId],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('❌ Error counting posts: $e');
      return 0;
    }
  }

  // Search posts by title for a user
  Future<List<Post>> searchPosts(int userId, String query) async {
    try {
      final db = await database;
      final result = await db.query(
        'posts',
        where: 'user_id = ? AND title LIKE ?',
        whereArgs: [userId, '%$query%'],
        orderBy: 'id DESC',
      );
      return result.map((map) => Post.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error searching posts: $e');
      throw Exception('Failed to search posts: $e');
    }
  }
}
