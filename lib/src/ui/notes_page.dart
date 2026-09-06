/// 笔记页：按天翻页浏览、一天多篇、编辑/删除、全文关键词搜索（命中跳转当天）。
library;

import 'package:flutter/material.dart';
import 'package:babydaily/src/data/database.dart';
import 'package:babydaily/src/domain/game_service.dart';
import 'package:babydaily/src/ui/app_controller.dart';
import 'package:babydaily/src/ui/feedback.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  DateTime _day = DateTime.now();
  List<Note> _notes = [];
  bool _searching = false;
  String _query = '';
  List<Note> _results = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final service = AppScope.of(context).service;
    final notes = await service.notesForDay(_day);
    if (mounted) {
      setState(() => _notes = notes);
    }
  }

  Future<void> _search() async {
    final service = AppScope.of(context).service;
    final results = await service.searchNotes(_query);
    if (mounted) setState(() => _results = results);
  }

  Future<void> _write({Note? existing}) async {
    final controller =
        TextEditingController(text: existing?.content ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? '写笔记' : '编辑笔记'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: existing == null,
              maxLines: 8,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: '今天想记录点什么？',
                border: OutlineInputBorder(),
              ),
            ),
            Text(
              '写满 20 字当天 +10 经验，连续写还有加成（每天最多 15）',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).hintColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (saved != true) {
      controller.dispose();
      return;
    }
    final content = controller.text;
    controller.dispose();
    if (content.trim().isEmpty) return;

    final service = AppScope.of(context).service;
    NoteResult result;
    if (existing == null) {
      result = await service.addNote(content, now: DateTime.now());
    } else {
      result = await service.updateNote(existing.id, content);
    }
    if (mounted && result.xpGained > 0) {
      showCelebration(context, '记录 +${result.xpGained} 经验 ✍️');
    }
    await AppScope.of(context).refresh();
    await _load();
  }

  Future<void> _delete(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除笔记'),
        content: const Text('删除后无法恢复，确定吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await AppScope.of(context).service.deleteNote(note.id);
      await _load();
    }
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _day = picked;
        _searching = false;
      });
      await _load();
    }
  }

  void _jumpTo(DateTime day) {
    setState(() {
      _day = day;
      _searching = false;
      _query = '';
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searching ? _searchField() : const Text('笔记'),
        actions: [
          if (_searching)
            IconButton(
              onPressed: () {
                setState(() {
                  _searching = false;
                  _query = '';
                });
              },
              icon: const Icon(Icons.close),
            )
          else
            IconButton(
              onPressed: () => setState(() => _searching = true),
              icon: const Icon(Icons.search),
            ),
        ],
      ),
      body: _searching ? _buildSearchResults() : _buildDayView(),
      floatingActionButton: _searching
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _write(),
              icon: const Icon(Icons.edit),
              label: const Text('写笔记'),
            ),
    );
  }

  Widget _searchField() {
    return TextField(
      autofocus: true,
      decoration: const InputDecoration(
        hintText: '搜索笔记内容…',
        border: InputBorder.none,
      ),
      onChanged: (value) {
        setState(() => _query = value);
        _search();
      },
    );
  }

  Widget _buildSearchResults() {
    if (_query.trim().isEmpty) {
      return Center(
        child: Text('输入关键词搜索全部笔记',
            style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Text('没有找到「$_query」',
            style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final note = _results[index];
        final day = DateTime(
            note.createdAt.year, note.createdAt.month, note.createdAt.day);
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _jumpTo(day),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${day.year}/${day.month}/${day.day}',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayView() {
    final today = DateTime.now();
    final isToday = _day.year == today.year &&
        _day.month == today.month &&
        _day.day == today.day;
    return Column(
      children: [
        // 日期导航
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      setState(() =>
                          _day = _day.subtract(const Duration(days: 1)));
                      await _load();
                    },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _pickDay,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            Text(
                              '${_day.year} 年 ${_day.month} 月 ${_day.day} 日',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              isToday ? '今天' : '周${_weekdayLabel(_day.weekday)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Theme.of(context).hintColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: isToday
                        ? null
                        : () async {
                            setState(() =>
                                _day = _day.add(const Duration(days: 1)));
                            await _load();
                          },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 当天笔记列表
        Expanded(
          child: _notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📖',
                          style:
                              Theme.of(context).textTheme.headlineLarge),
                      const SizedBox(height: 8),
                      Text('这一天还没有笔记',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _write(existing: note),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${note.createdAt.hour.toString().padLeft(2, '0')}:'
                                        '${note.createdAt.minute.toString().padLeft(2, '0')}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                                color: Theme.of(context)
                                                    .hintColor),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(note.content),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _delete(note),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _weekdayLabel(int weekday) => switch (weekday) {
        1 => '一',
        2 => '二',
        3 => '三',
        4 => '四',
        5 => '五',
        6 => '六',
        _ => '日',
      };
}

