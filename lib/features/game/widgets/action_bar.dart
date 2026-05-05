import 'package:flutter/material.dart';

class ActionBar extends StatelessWidget {
  const ActionBar({
    super.key,
    required this.notesMode,
    required this.onToggleNotes,
    required this.onUndo,
    required this.onErase,
    required this.onHint,
    required this.hintsLeft,
    this.allowNotes = true,
  });

  final bool notesMode;
  final VoidCallback onToggleNotes;
  final VoidCallback onUndo;
  final VoidCallback onErase;
  final VoidCallback onHint;
  final int hintsLeft;
  final bool allowNotes;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Btn(icon: Icons.undo, label: '撤销', onTap: onUndo),
        _Btn(
            icon: Icons.cleaning_services_outlined,
            label: '擦除',
            onTap: onErase),
        if (allowNotes)
          _Btn(
            icon: notesMode ? Icons.edit_note : Icons.edit_outlined,
            label: notesMode ? '笔记中' : '笔记',
            onTap: onToggleNotes,
            highlight: notesMode,
          ),
        _Btn(
          icon: Icons.lightbulb_outline,
          label: '提示($hintsLeft)',
          onTap: hintsLeft > 0 ? onHint : null,
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.highlight = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon,
                color: onTap == null
                    ? Theme.of(context).disabledColor
                    : (highlight ? scheme.primary : scheme.onSurface)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: onTap == null
                        ? Theme.of(context).disabledColor
                        : (highlight ? scheme.primary : scheme.onSurface))),
          ],
        ),
      ),
    );
  }
}
