import 'package:filmo/features/household/data/household_repository.dart';
import 'package:filmo/features/household/presentation/providers/household_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HouseholdCreateScreen extends ConsumerWidget {
  const HouseholdCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    String _name = "";

    void _submitForm() async {
      // Check if the form is valid
      if (_formKey.currentState!.validate()) {
        // Save the form data
        _formKey.currentState!.save();
        await ref.read(householdRepositoryProvider).createHousehold(_name);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              // Title of the dialog
              title: Text('Form Submitted'),

              content: Text('Name: $_name'),

              // Display the entered name and email
              actions: <Widget>[
                TextButton(
                  child: Text('OK', style: TextStyle(color: Colors.green)),

                  // Button to close the dialog
                  onPressed: () {
                    ref.invalidate(householdCollectionsProvider);
                    // Close the dialog
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }

    return Scaffold(
      appBar: AppBar(),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              decoration: InputDecoration(
                // Label for the name field
                labelText: 'Name',

                // Border style for the text field
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.green,
                    width: 2.0,
                  ), // Border color when focused
                ),
              ),
              validator: (value) {
                // Validation function for the name field
                if (value!.isEmpty) {
                  // Return an error message if the name is empty
                  return 'Please enter your name.';
                }

                // Return null if the name is valid
                return null;
              },
              onSaved: (value) {
                // Save the entered name
                _name = value!;
              },
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                // Button background color
                backgroundColor: Colors.green,

                // Button text color
                foregroundColor: Colors.white,
              ),

              // Call the _submitForm function when the button is pressed
              onPressed: _submitForm,

              // Text on the button
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
