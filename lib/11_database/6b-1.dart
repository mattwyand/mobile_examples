import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';  // Import SQFlite for local database operations
import 'package:path/path.dart';        // Import Path to manage file system paths

// Entry point of the Flutter app
void main() {
  runApp(MyApp());
}

// Root widget of the application
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQFlite Example', // App title
      home: DatabaseDemo(),     // Home screen widget
    );
  }
}

// StatefulWidget because we need to manage database state and UI updates
class DatabaseDemo extends StatefulWidget {
  @override
  _DatabaseDemoState createState() => _DatabaseDemoState();
}

class _DatabaseDemoState extends State<DatabaseDemo> {
  //[1]
  late Database database; // Variable to hold reference to the SQLite database

  // [2] Called once when the widget is created — good place for setup tasks
  @override
  void initState() {
    super.initState(); // Ensure parent initialization
    _initDatabase(); // Initialize the local database as soon as the widget is created
  }

  // [3] Function to initialize and create (or open) the database
  Future<void> _initDatabase() async {
    // Get the default path where databases can be stored
    //safe, app-private folder (accessible only to your app)
    // where you can read/write SQLite databases without needing any permissions.
    var dbPath = await getDatabasesPath();

    // Combine the path and database file name
    String path = join(dbPath, 'mydatabase.db');

    // Open the database (create if not exists)
    database = await openDatabase(
      path,
      version: 1, // Database version number (used for upgrades)
      onCreate: (db, version) async {

        //execute() method is designed for commands that modify the database
        // Create a table named 'people' with columns 'id' and 'name'
        await db.execute(
            "CREATE TABLE people(id INTEGER PRIMARY KEY, name TEXT)"
        );
      },
    );
  }

  // [4] Function to insert a new record (person) into the 'people' table
  Future<void> _insertPerson(String name) async {
    await database.insert(
      'people',         // Table name
      {'name': name},   // Data to insert as key-value map
    );

    // Update the UI after insertion
    setState(() {});
  }

  // Function to fetch all records from the 'people' table
  Future<List<Map<String, dynamic>>> _getPeople() async {
    return await database.query('people'); // SELECT * FROM people
    //return await database.rawQuery('SELECT * FROM people');
  }

  //output:
  //[
  //   {'id': 10, 'name': 'x'},
  //   {'id': 9,  'name': 'y'},
  //   {'id': 8,  'name': 'z'},
  //   {'id': 7,  'name': 't'},
  //   {'id': 6,  'name': 'k'}
  // ]


  // (Optional advanced query example)
  // Example of querying with conditions, ordering, and limits
  Future<List<Map<String, dynamic>>> _getPeopleV2() async {
    return await database.query(
      'people',                      // Table name
      columns: ['id', 'name'],       // Columns to retrieve
      where: 'name LIKE ?',          // WHERE clause (SQL condition)
      whereArgs: ['Person%'],        // Arguments for WHERE clause
      orderBy: 'id DESC',            // Sort results by 'id' descending
      limit: 5                       // Limit results to 5 rows
    );
  }

  // Future<List<Map<String, dynamic>>> _getPeopleV2_2() async {
  //   return await database.rawQuery(
  //     '''
  //   SELECT id, name
  //   FROM people
  //   WHERE name LIKE ?
  //   ORDER BY id DESC
  //   LIMIT 5
  //   ''',
  //     ['Person%'], // This replaces whereArgs
  //   );
  // }


  // Function to delete a record from the 'people' table using ID
  Future<void> _deletePerson(int id) async {
    await database.delete(
      'people',           // Table name
      where: 'id = ?',    // WHERE condition
      whereArgs: [id],    // Value for the placeholder
    );

    // Refresh the UI after deletion
    setState(() {});
  }

  //output:
  //[
  //   {'id': 10, 'name': 'x'},
  //   {'id': 9,  'name': 'y'},
  //   {'id': 8,  'name': 'z'},
  //   {'id': 7,  'name': 't'},
  //   {'id': 6,  'name': 'k'}
  // ]

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SQFlite Example')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getPeople(), // Fetching people from the database
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator(); // Show loading indicator while fetching data
          }

          // Display the list of people in the UI
          return ListView.builder(
            itemCount: snapshot.data?.length,
            itemBuilder: (context, index) {
              var person = snapshot.data![index]; // Getting the current person from the list
              return ListTile(
                title: Text(person['name']), // Displaying the name
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _deletePerson(person['id']); // Deleting the person when delete icon is pressed
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _insertPerson('Person ${DateTime.now()}'); // Insert a new person with a timestamp as the name
        },
        child: Icon(Icons.add),
      ),
    );
  }
}