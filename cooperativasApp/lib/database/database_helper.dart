import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../cooperative_service.dart';
import '../auth_service.dart';

class DatabaseHelper {
  // Singleton para una única instancia
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  factory DatabaseHelper() => _instance;

  // Getter para la base de datos (inicializa si es necesario)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicialización de la base de datos
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'cooperativas.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<Cooperative?> getCooperativeById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cooperativas',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? Cooperative.fromMap(maps.first) : null;
  }

  Future<List<User>> getUsuarios() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('usuarios');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<void> deleteMiembro(String cooperativeId, String userId) async {
    final db = await database;
    await db.delete(
      'miembros',
      where: 'cooperativeId = ? AND userId = ?',
      whereArgs: [cooperativeId, userId],
    );
  }

  Future<User?> getUserById(String userId) async {
    final db = await database;
    print('Buscando usuario con ID: $userId');
    final List<Map<String, dynamic>> maps = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [userId],
    );
    print('Resultados encontrados: ${maps.length}');
    if (maps.isNotEmpty) {
      print('Usuario encontrado: ${maps.first}');
      return User.fromMap(maps.first);
    }
    print('Usuario no encontrado');
    return null;
  }

  Future<List<Member>> getAllMiembros() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('miembros');
    return List.generate(maps.length, (i) {
      return Member(
        userId: maps[i]['userId'],
        balance: maps[i]['balance'],
      );
    });
  }

  // Creación de tablas
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cooperativas(
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE miembros(
        userId TEXT,
        cooperativeId TEXT,
        balance REAL,
        PRIMARY KEY (userId, cooperativeId)
      )
    ''');

    await db.execute('''
      CREATE TABLE usuarios(
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE,
        name TEXT
      )
    ''');
  }

  Future<void> checkDatabaseIntegrity() async {
    final db = await database;
    print('Verificando integridad de la base de datos...');
    final tables = await db.query('sqlite_master', columns: ['name']);
    print(
        'Tablas en la base de datos: ${tables.map((t) => t['name']).toList()}');
    final userCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM usuarios'));
    print('Número de usuarios en la base de datos: $userCount');
  }


  Future<int> insertCooperative(Cooperative cooperative) async {
    final db = await database;
    return await db.insert(
      'cooperativas',
      cooperative.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Cooperative>> getCooperativas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cooperativas');
    return List.generate(maps.length, (i) => Cooperative.fromMap(maps[i]));
  }

  Future<int> deleteCooperative(String id) async {
    final db = await database;
    return await db.delete(
      'cooperativas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  Future<void> insertMiembro(Member member, String cooperativeId) async {
    final db = await database;
    await db.insert(
      'miembros',
      {
        'userId': member.userId,
        'cooperativeId': cooperativeId,
        'balance': member.balance
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Member>> getMiembros(String cooperativeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'miembros',
      where: 'cooperativeId = ?',
      whereArgs: [cooperativeId],
    );
    return List.generate(
        maps.length,
        (i) => Member(
              userId: maps[i]['userId'],
              balance: maps[i]['balance'],
            ));
  }

 
  Future<int> insertUsuario(User user) async {
    final db = await database;
    return await db.insert(
      'usuarios',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getUsuarioById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  Future<User?> getUsuarioByEmail(String email) async {
    final db = await database;
    print('Buscando usuario con email: $email');
    final List<Map<String, dynamic>> maps = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [email],
    );
    print('Resultados encontrados: ${maps.length}');
    if (maps.isNotEmpty) {
      print('Usuario encontrado: ${maps.first}');
      return User.fromMap(maps.first);
    }
    print('Usuario no encontrado');
    return null;
  }


  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
