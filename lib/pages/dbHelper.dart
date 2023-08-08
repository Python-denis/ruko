// import 'dart:io';
//
// import 'package:path_provider/path_provider.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
//
// class DBHelper {
//   DBHelper._();
//   static final DBHelper dbinstance = DBHelper._();
//
//   static Database? _database;
//   static const users = "users";
//
//   Future<Database?> get database async {
//     if (_database != null) {
//       return _database!;
//     }
//     _database = await initDatabase();
//     return null;
//   }
//
//   initDatabase() async {
//     Directory directory = await getApplicationDocumentsDirectory();
//     String path = join(directory.path, 'MilkDuvet');
//     var database = await openDatabase(path, version: 1, onCreate: _onCreate);
//     return database;
//   }
//
//   // creating database table
//   _onCreate(Database db, int version) async {
//     await db.execute(
//         "CREATE TABLE $users(id INTEGER PRIMARY KEY, userId INTEGER, username TEXT, fullname TEXT,email TEXT, coolerName TEXT, role TEXT, token TEXT)");
//   }
//
// // fetchUser() {}
//
//
// }
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper{
  //Create a private constructor
  DBHelper._();
  static const databaseName = 'MilkDuvet.db';
  static const users = 'users';

  static final DBHelper instance = DBHelper._();
  static Database? _database;

  Future<Database> get database async =>
      _database ??= await initializeDatabase();

  initializeDatabase() async {
    return await openDatabase(join(await getDatabasesPath(), databaseName),
        version: 1, onCreate: (Database db, int version) async {

          await db.execute(
              "CREATE TABLE $users(id INTEGER PRIMARY KEY, userId INTEGER, username TEXT, fullname TEXT,email TEXT, coolerName TEXT, role TEXT, token TEXT, coolerId INTEGER, contact TEXT)");

        });
  }




}