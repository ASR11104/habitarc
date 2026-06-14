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
  Icons.cleaning_services,
  Icons.school,
  Icons.work,
  Icons.computer,
  Icons.brush,
  Icons.home,
  Icons.local_laundry_service,
  Icons.shopping_cart,
  Icons.pets,
  Icons.local_florist,
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
  bool _isWeeklyPillar = false;
  final Set<int> _selectedDays = {};

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
    
    _isWeeklyPillar = widget.habit?.isWeeklyPillar ?? false;
    if (widget.habit?.weeklyDays != null && widget.habit!.weeklyDays!.isNotEmpty) {
      _selectedDays.addAll(
        widget.habit!.weeklyDays!
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>(),
      );
    } else {
      _selectedDays.addAll({1, 3, 5}); // Default to Mon, Wed, Fri
    }
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

    final weeklyDaysStr = _isWeeklyPillar
        ? (_selectedDays.toList()..sort()).join(',')
        : null;

    if (widget.habit == null) {
      await repo.addHabit(
        _nameCtrl.text.trim(),
        _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        _selectedColor.toARGB32(),
        _selectedIcon.codePoint,
        isWeeklyPillar: _isWeeklyPillar,
        weeklyDays: weeklyDaysStr,
      );
    } else {
      final updated = widget.habit!.copyWith(
        name: _nameCtrl.text.trim(),
        description: Value(_descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim()),
        colorValue: _selectedColor.toARGB32(),
        iconCodePoint: _selectedIcon.codePoint,
        isWeeklyPillar: _isWeeklyPillar,
        weeklyDays: Value(weeklyDaysStr),
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
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Weekly Pillar'),
              subtitle: const Text('Track this habit on specific recurring days'),
              value: _isWeeklyPillar,
              onChanged: (val) {
                setState(() => _isWeeklyPillar = val);
              },
            ),
            if (_isWeeklyPillar) ...[
              const SizedBox(height: 16),
              Text('Days of the Week',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final weekday = index + 1; // 1 = Monday, 7 = Sunday
                  final isSelected = _selectedDays.contains(weekday);
                  final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  final dayLabel = labels[index];
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          if (_selectedDays.length > 1) {
                            _selectedDays.remove(weekday);
                          }
                        } else {
                          _selectedDays.add(weekday);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? _selectedColor
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        border: isSelected
                            ? null
                            : Border.all(
                                color: Theme.of(context).colorScheme.outlineVariant,
                                width: 1,
                              ),
                      ),
                      child: Center(
                        child: Text(
                          dayLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
