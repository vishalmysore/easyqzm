import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String? _selectedOption;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _queryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Function to open GitHub link
  void _launchGitHub() async {
    const url = 'https://github.com/vishalmysore/easyqz'; // Replace with your actual repo link
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Function to handle submit action
  void _submitQuery() {
    if (_formKey.currentState!.validate() && _selectedOption != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Your query has been submitted!")),
      );
      _emailController.clear();
      _queryController.clear();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields correctly")),
      );
    }
  }

  // Email validation function
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Enter your email";
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) return "Enter a valid email";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Contact Us", style: TextStyle(fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // GitHub Link
            GestureDetector(
              onTap: _launchGitHub,
              child: Text(
                "What is EasyQZ?",
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            SizedBox(height: 10),

            // Email Input Field
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              validator: _validateEmail,
            ),
            SizedBox(height: 10),

            // Dropdown for selecting issue type
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: "Select an option"),
              value: _selectedOption,
              items: ["Issues", "Contribute", "Report"]
                  .map((label) => DropdownMenuItem(
                child: Text(label),
                value: label,
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedOption = value;
                });
              },
            ),
            SizedBox(height: 10),

            // Text area for user queries
            TextFormField(
              controller: _queryController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter your query...",
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return "Enter your query";
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _submitQuery,
          child: Text("Submit"),
        ),
      ],
    );
  }
}

// FloatingActionButton to open help dialog

