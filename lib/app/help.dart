import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../service/api_service.dart';

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
  void _submitQuery() async {
    if (_formKey.currentState!.validate() && _selectedOption != null) {
      // Prepare data to send
      final contactUsData = {
        "type": _selectedOption,
        "gitUrl": 'https://github.com/vishalmysore/easyqz',
        "email": _emailController.text,
        "message": _queryController.text,
      };

      // Call the separate method to send the data
      try {
        final response = await ApiService().sendContactUsData(contactUsData);

        if (response?.statusCode == 200) {
          // Success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Your query has been submitted!")),
          );
          _emailController.clear();
          _queryController.clear();
          Navigator.pop(context); // Close the dialog after successful submission
        } else {
          // Error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to submit your query")),
          );
        }
      } catch (e) {
        print('Error sending data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred. Please try again later.")),
        );
      }
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
      title: Text(
        "Contact Us",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
          fontSize: 24,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "What is EasyQZ?" section with an eye-catching description
              GestureDetector(
                onTap: _launchGitHub,
                child: Text(
                  "What is EasyQZ?",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                "EasyQZ is a hyper-personalized deep research-based learning agent. "
                    "It helps you test your knowledge with custom quizzes, tracks your progress, "
                    "and provides insightful analytics. An open-source project with support based "
                    "on time availability. Everyone is welcome to contribute and join the community!",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),

              // Email Input Field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                validator: _validateEmail,
              ),
              SizedBox(height: 12),

              // Dropdown for selecting issue type
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Select an option",
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
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
              SizedBox(height: 12),

              // Text area for user queries
              TextFormField(
                controller: _queryController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Enter your query...",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return "Enter your query";
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Cancel",
            style: TextStyle(color: Colors.red),
          ),
        ),
        ElevatedButton(
          onPressed: _submitQuery,
          child: Text("Submit"),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    );
  }
}


// FloatingActionButton to open help dialog

