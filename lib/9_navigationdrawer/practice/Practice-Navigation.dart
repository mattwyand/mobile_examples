import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

// Root widget
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FirstPage(),
    );
  }
}

// First screen (home page)
class FirstPage extends StatefulWidget {
  @override
  _FirstPageState createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  String? returnedMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('First Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              returnedMessage ?? 'No message yet',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Navigate to SecondPage and wait for data back
                // ... //[HERE] .........................
                final result = await Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SecondPage()
                ));

                // Update the UI if data is returned
                if (result != null) {
                  setState(() {
                    returnedMessage = result;
                  });
                }
              },
              child: Text('Go to Second Page'),
            ),
          ],
        ),
      ),
    );
  }
}

// Second screen
class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Second Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Send data back to the first page - the data is string "Hello from Second Page!"
            // ... //[HERE] ..............................
            // final test = "Hello from second page";
            // return test;
            Navigator.pop((context),
              "Hello from second page"
            );
          },
          child: Text('Send Message Back'),
        ),
      ),
    );
  }
}
