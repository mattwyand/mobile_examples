import 'package:flutter/material.dart';

void main() => runApp(const ContactListApp());

class ContactListApp extends StatelessWidget {
  const ContactListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contact List Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('My Contacts')),
        body: const ContactList(),
      ),
    );
  }
}

class ContactList extends StatelessWidget {
  const ContactList({super.key});

  @override
  Widget build(BuildContext context) {
    // Simple list of contacts (name + phone number)
    final contacts = [
      {'name': 'Alice Johnson', 'phone': '123-456-7890'},
      {'name': 'Bob Smith', 'phone': '234-567-8901'},
      {'name': 'Charlie Davis', 'phone': '345-678-9012'},
    ];

    return ListView.builder(
      // your code
      //'assets/images/green.png' or use any other image
      padding: const EdgeInsets.all(8),
      itemCount: contacts.length,
      itemBuilder: (BuildContext context, int index) {
        return Container(
          child: ListTile(
            leading: Image.network(
              'https://static.wikia.nocookie.net/muppet/images/b/b5/Fozzie2.jpg/revision/latest/scale-to-width-down/280?cb=20120410231906',
              width: 64,
              height: 64,
            ),
            title: Text(contacts[index]['name']!),
            subtitle: Text("Phone: ${contacts[index]['phone']}"),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Calling ${contacts[index]['name']}..."),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

//5-ListView3 -> listview
//6a-1 -> snackbar
