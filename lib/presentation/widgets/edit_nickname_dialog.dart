import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../states/providers.dart';

class EditNicknameDialog extends ConsumerStatefulWidget {
  final String currentNickname;

  const EditNicknameDialog({super.key, required this.currentNickname});

  @override
  ConsumerState<EditNicknameDialog> createState() => _EditNicknameDialogState();
}

class _EditNicknameDialogState extends ConsumerState<EditNicknameDialog> {
  late final TextEditingController _nicknameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.currentNickname);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('昵称不能为空')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(userProfileServiceProvider)
          .updateProfile(nickname: _nicknameController.text.trim());

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
      title: const Text('编辑昵称'),
      content: TextField(
        controller: _nicknameController,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(left: 12, top: 8),
        ),
        cursorColor: Colors.grey.withOpacity(0.7),
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
          TextButton(onPressed: _saveNickname, child: const Text('保存')),
      ],
    );
  }
}
