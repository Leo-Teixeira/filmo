import 'package:flutter/material.dart';

import '../../../../core/network/api_failure.dart';

/// Pops with true once [onSubmit] succeeds; a failure stays in the dialog.
class SingleFieldDialog extends StatefulWidget {
  const SingleFieldDialog({
    super.key,
    required this.title,
    required this.label,
    required this.submitLabel,
    required this.validator,
    required this.onSubmit,
    this.errorMessage = userMessage,
  });

  final String title;
  final String label;
  final String submitLabel;
  final FormFieldValidator<String> validator;
  final Future<void> Function(String value) onSubmit;
  final String Function(Object error) errorMessage;

  @override
  State<SingleFieldDialog> createState() => _SingleFieldDialogState();
}

class _SingleFieldDialogState extends State<SingleFieldDialog> {
  final _formKey = GlobalKey<FormState>();
  final _field = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_field.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = widget.errorMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _field,
          autofocus: true,
          decoration: InputDecoration(
            labelText: widget.label,
            errorText: _error,
            border: const OutlineInputBorder(),
          ),
          validator: widget.validator,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}
