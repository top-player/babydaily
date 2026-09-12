/// 笔记编辑器页：写一条新笔记 / 改一条已有笔记（从 FAB 或笔记卡容器变换进来）。
///
/// 只管收字：保存时把文本 `pop` 回调用方，落库与刷新仍由笔记页负责
/// （所以笔记「不发经验」的规则只有一处实现，见 ADR-0006）。
library;

import 'package:flutter/material.dart';
import 'package:babydaily/src/ui/editor_page.dart';

/// 写/改笔记的整页表单。
///
/// 保存时 `pop(<正文>)`；取消/返回 `pop(null)`，由调用方判定要不要落库。
class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({
    super.key,
    this.initialText = '',
    this.editing = false,
  });

  /// 已有笔记的正文（新建时为空串）。
  final String initialText;

  /// 编辑已有笔记（决定标题与提示文案）。
  final bool editing;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController _content = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EditorPage(
      title: widget.editing ? '编辑笔记' : '写笔记',
      subtitle: '笔记只存在本机，随时可以编辑或删除；不发放经验。',
      onSave: () => Navigator.of(context).pop(_content.text),
      children: [
        TextField(
          controller: _content,
          autofocus: !widget.editing,
          maxLines: 12,
          minLines: 8,
          maxLength: 2000,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            hintText: '今天想记录点什么？',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
