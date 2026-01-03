import 'package:flutter/material.dart';
import 'mission_store.dart';

class AddMissionDialog {
  static const Color green = Color(0xFF76B947);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  static Future<void> open(
    BuildContext context, {
    Mission? initial,
    int? editIndex,
  }) async {
    final store = MissionStore.instance;

    final titleC = TextEditingController(text: initial?.title ?? '');
    final notesC = TextEditingController(text: initial?.notes ?? '');

    String? field = initial?.fieldLocation;
    String? type = initial?.missionType;

    DateTime date = initial?.date ?? DateTime.now();
    TimeOfDay time = initial?.time ?? const TimeOfDay(hour: 10, minute: 30);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AnimatedBuilder(
              animation: store,
              builder: (context, __) {
                final effectiveField = (field != null && store.fieldLocations.contains(field))
                    ? field
                    : (store.fieldLocations.isNotEmpty ? store.fieldLocations.first : null);

                final effectiveType = (type != null && store.missionTypes.contains(type))
                    ? type
                    : (store.missionTypes.isNotEmpty ? store.missionTypes.first : null);

                return Dialog(
                  insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          const Text(
                            'Add New Mission',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 18),

                          _UnderlineTextField(
                            label: 'Mission Title',
                            controller: titleC,
                          ),
                          const SizedBox(height: 14),

                          _UnderlineDropdown(
                            label: 'Field Location',
                            value: effectiveField,
                            items: store.fieldLocations,
                            onChanged: (v) async {
                              if (v == null) return;

                              if (v == '__add__') {
                                final res = await _askNewValue(context, 'New field location');
                                final value = (res ?? '').trim();
                                if (value.isEmpty) return;

                                await store.addFieldLocation(value);
                                setState(() => field = value);
                                return;
                              }

                              setState(() => field = v);
                            },
                          ),
                          const SizedBox(height: 14),

                          _PickerRow(
                            label: 'Date',
                            valueText: MissionStore.formatDateShort(date),
                            leadingIcon: Icons.calendar_today_outlined,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: date,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setState(() => date = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 14),

                          _PickerRow(
                            label: 'Time',
                            valueText: MissionStore.formatTime(time),
                            leadingIcon: Icons.access_time,
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: time,
                              );
                              if (picked != null) {
                                setState(() => time = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 14),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Mission Type',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textSecondary.withOpacity(0.9),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          _UnderlineDropdown(
                            label: '',
                            value: effectiveType,
                            items: store.missionTypes,
                            onChanged: (v) async {
                              if (v == null) return;

                              if (v == '__add__') {
                                final res = await _askNewValue(context, 'New mission type');
                                final value = (res ?? '').trim();
                                if (value.isEmpty) return;

                                await store.addMissionType(value);
                                setState(() => type = value);
                                return;
                              }

                              setState(() => type = v);
                            },
                          ),
                          const SizedBox(height: 14),

                          _UnderlineTextField(
                            label: 'Notes',
                            controller: notesC,
                          ),
                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5BB870),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                final t = titleC.text.trim();

                                final f = ((field != null && store.fieldLocations.contains(field))
                                        ? field
                                        : (store.fieldLocations.isNotEmpty ? store.fieldLocations.first : null)) ??
                                    '';

                                final mt = ((type != null && store.missionTypes.contains(type))
                                        ? type
                                        : (store.missionTypes.isNotEmpty ? store.missionTypes.first : null)) ??
                                    '';

                                if (t.isEmpty || f.trim().isEmpty || mt.trim().isEmpty) return;

                                final m = Mission(
                                  id: initial?.id,
                                  title: t,
                                  fieldLocation: f.trim(),
                                  missionType: mt.trim(),
                                  date: date,
                                  time: time,
                                  notes: notesC.text.trim(),
                                );

                                if (editIndex != null) {
                                  await store.updateMissionByIndex(editIndex, m);
                                } else {
                                  await store.addMission(m);
                                }

                                if (context.mounted) Navigator.pop(context);
                              },
                              child: const Text(
                                'Save Mission',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE2E2E2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  static Future<String?> _askNewValue(BuildContext context, String title) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          content: TextField(
            controller: c,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Type here'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('Add')),
          ],
        );
      },
    );
  }
}

class _UnderlineTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _UnderlineTextField({
    required this.label,
    required this.controller,
  });

  static const Color textSecondary = AddMissionDialog.textSecondary;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD5D7DA))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFBFC3C8))),
      ),
    );
  }
}

class _UnderlineDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final Future<void> Function(String? v) onChanged;

  const _UnderlineDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  static const Color textSecondary = AddMissionDialog.textSecondary;

  @override
  Widget build(BuildContext context) {
    final allItems = [...items];

    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: (value != null && allItems.contains(value)) ? value : (allItems.isNotEmpty ? allItems.first : null),
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      onChanged: (v) {
        onChanged(v);
      },
      decoration: InputDecoration(
        labelText: label.isEmpty ? null : label,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD5D7DA))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFBFC3C8))),
      ),
      items: [
        ...allItems.map((e) => DropdownMenuItem(value: e, child: Text(e))),
        const DropdownMenuItem(value: '__add__', child: Text('Add new...')),
      ],
    );
  }
}

class _PickerRow extends StatelessWidget {
  final String label;
  final String valueText;
  final IconData leadingIcon;
  final VoidCallback onTap;

  const _PickerRow({
    required this.label,
    required this.valueText,
    required this.leadingIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AddMissionDialog.textSecondary,
          ),
          prefixIcon: Icon(leadingIcon, size: 18, color: AddMissionDialog.textSecondary),
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD5D7DA))),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFBFC3C8))),
        ),
        child: Text(
          valueText,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AddMissionDialog.textPrimary),
        ),
      ),
    );
  }
}
