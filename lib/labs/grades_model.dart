import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'main.dart';

class GradesModel {
  static final GradesModel _instance = GradesModel._internal();
  factory GradesModel() => _instance;
  GradesModel._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('grades.db');
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
    final dir = Directory.current.path;
    final path = join(dir, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
        CREATE TABLE grades (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sid TEXT NOT NULL,
          grade TEXT NOT NULL
        )
      ''');
      },
    );
  }


  Future<List<Grade>> getAllGrades() async {
    final db = await database;
    final data = await db.query('grades', orderBy: 'sid ASC');
    return data.map((row) => Grade.fromMap(row)).toList();
  }

  Future<int> insertGrade(Grade grade) async {
    final db = await database;
    return await db.insert('grades', grade.toMap());
  }

  Future<int> updateGrade(Grade grade) async {
    final db = await database;
    if (grade.id == null) {
      return 0;
    }

    final values = grade.toMap();
    values.remove('id');

    return await db.update(
      'grades',
      values,
      where: 'id = ?',
      whereArgs: [grade.id],
    );
  }

  Future<int> deleteGradeById(int id) async {
    final db = await database;
    return await db.delete('grades', where: 'id = ?', whereArgs: [id]);
  }
}
