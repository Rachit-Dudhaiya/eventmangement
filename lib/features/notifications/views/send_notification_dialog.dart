import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/notification_repository.dart';

class SendNotificationDialog extends ConsumerStatefulWidget {
  const SendNotificationDialog({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  final int eventId;
  final String eventTitle;

  @override
  ConsumerState<SendNotificationDialog> createState() =>
      _SendNotificationDialogState();
}

class _SendNotificationDialogState
    extends ConsumerState<SendNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  final _bodyController = TextEditingController();
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.eventTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final response =
          await ref.read(notificationRepositoryProvider).sendEventNotification(
                eventId: widget.eventId,
                title: _titleController.text.trim(),
                body: _bodyController.text.trim(),
              );
      if (mounted) Navigator.of(context).pop(response);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notify registrants'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                maxLength: 180,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a notification title'
                    : null,
              ),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                ),
                minLines: 2,
                maxLines: 4,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a notification message'
                    : null,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSending ? null : _send,
          child: _isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send'),
        ),
      ],
    );
  }
}
