import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../providers/habits_provider.dart';

const _colors = [
  Color(0xFF6750A4),
  Color(0xFF0061A4),
  Color(0xFF006E1C),
  Color(0xFFBA1A1A),
  Color(0xFFE65100),
  Color(0xFF795548),
];

const _icons = [
  Icons.star,
  Icons.fitness_center,
  Icons.book,
  Icons.water_drop,
  Icons.bedtime,
  Icons.directions_run,
  Icons.self_improvement,
  Icons.restaurant,
  Icons.code,
  Icons.music_note,
];

class AddHabitScreen extends ConsumerStatefulWidget {
  final Habit? habit;
  const AddHabitScreen({super.key, this.habit});

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late Color _selectedColor;
  late IconData _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.habit?.name ?? '');
    _descCtrl =
        TextEditingController(text: widget.habit?.description ?? '');
    _selectedColor = widget.habit != null
        ? Color(widget.habit!.colorValue)
        : _colors.first;
    _selectedIcon = widget.habit != null
        ? IconData(widget.habit!.iconCodePoint, fontFamily: 'MaterialIcons')
        : _icons.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(habitsRepositoryProvider);

    if (widget.habit == null) {
      await repo.addHabit(
        _nameCtrl.text.trim(),
        _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        _selectedColor.toARGB32(),
        _selectedIcon.codePoint,
      );
    } else {
      final updated = widget.habit!.copyWith(
        name: _nameCtrl.text.trim(),
        description: Value(_descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim()),
        colorValue: _selectedColor.toARGB32(),
        iconCodePoint: _selectedIcon.codePoint,
      );
      await repo.updateHabit(updated);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.habit != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Habit' : 'New Habit'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Habit name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Text('Color', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: _colors.map((c) {
                final selected = c == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Icon', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _icons.map((icon) {
                final selected = icon == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected ? _selectedColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? _selectedColor
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: selected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
