import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../states/providers.dart';

class EditSloganDialog extends ConsumerStatefulWidget {
  final String currentSlogan;

  const EditSloganDialog({super.key, required this.currentSlogan});

  @override
  ConsumerState<EditSloganDialog> createState() => _EditSloganDialogState();
}

class _EditSloganDialogState extends ConsumerState<EditSloganDialog> {
  late final TextEditingController _sloganController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sloganController = TextEditingController(text: widget.currentSlogan);
  }

  @override
  void dispose() {
    _sloganController.dispose();
    super.dispose();
  }

  Future<void> _saveSlogan() async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(userProfileServiceProvider)
          .updateProfile(slogan: _sloganController.text.trim());

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑口号'),
      content: TextField(
        controller: _sloganController,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        if (_isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          TextButton(onPressed: _saveSlogan, child: const Text('保存')),
      ],
    );
  }
}
