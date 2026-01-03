import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_config.dart';
import 'planner_api.dart';

class Mission {
  final int? id;
  final String title;
  final String fieldLocation;
  final String missionType;
  final DateTime date;
  final TimeOfDay time;
  final String notes;

  const Mission({
    this.id,
    required this.title,
    required this.fieldLocation,
    required this.missionType,
    required this.date,
    required this.time,
    this.notes = '',
  });

  Mission copyWith({
    int? id,
    String? title,
    String? fieldLocation,
    String? missionType,
    DateTime? date,
    TimeOfDay? time,
    String? notes,
  }) {
    return Mission(
      id: id ?? this.id,
      title: title ?? this.title,
      fieldLocation: fieldLocation ?? this.fieldLocation,
      missionType: missionType ?? this.missionType,
      date: date ?? this.date,
      time: time ?? this.time,
      notes: notes ?? this.notes,
    );
  }
}

class MissionStore extends ChangeNotifier {
  MissionStore._();
  static final MissionStore instance = MissionStore._();

  final PlannerApi api = PlannerApi();

  final List<String> fieldLocations = [];
  final List<String> missionTypes = [];
  final List<Mission> missions = [];

  bool _lookupsLoaded = false;

  Future<void> ensureLookupsLoaded() async {
    if (_lookupsLoaded) return;
    await Future.wait([reloadFieldLocations(), reloadMissionTypes()]);
    _lookupsLoaded = true;
  }

  Future<void> reloadFieldLocations() async {
    final list = await api.getFieldLocations();
    fieldLocations
      ..clear()
      ..addAll(list);
    notifyListeners();
  }

  Future<void> reloadMissionTypes() async {
    final list = await api.getMissionTypes();
    missionTypes
      ..clear()
      ..addAll(list);
    notifyListeners();
  }

  Future<void> reloadMissions() async {
    final rows = await api.getMissions();
    missions
      ..clear()
      ..addAll(rows.map(_fromRow));
    notifyListeners();
  }

  Future<void> addFieldLocation(String v) async {
    final name = v.trim();
    if (name.isEmpty) return;
    await api.addFieldLocation(name);
    await reloadFieldLocations();
  }

  Future<void> addMissionType(String v) async {
    final name = v.trim();
    if (name.isEmpty) return;
    await api.addMissionType(name);
    await reloadMissionTypes();
  }

  Future<void> addMission(Mission m) async {
    final newId = await api.createMission(_toPayload(m));
    missions.add(m.copyWith(id: newId));
    notifyListeners();

    await Future.wait([reloadFieldLocations(), reloadMissionTypes()]);
  }

  Future<void> updateMissionByIndex(int index, Mission m) async {
    if (index < 0 || index >= missions.length) return;
    final id = m.id;
    if (id == null) return;

    await api.updateMission(id, _toPayload(m));
    missions[index] = m;
    notifyListeners();

    await Future.wait([reloadFieldLocations(), reloadMissionTypes()]);
  }

  Future<void> deleteMissionByIndex(int index) async {
    if (index < 0 || index >= missions.length) return;
    final id = missions[index].id;
    if (id != null) {
      await api.deleteMission(id);
    }
    missions.removeAt(index);
    notifyListeners();
  }

  List<Mission> sortedMissions() {
    final now = DateTime.now();
    final list = missions.where((m) => !_dt(m).isBefore(now)).toList();
    list.sort((a, b) => _dt(a).compareTo(_dt(b)));
    return list;
  }

  static DateTime _dt(Mission m) {
    return DateTime(m.date.year, m.date.month, m.date.day, m.time.hour, m.time.minute);
  }

  static Map<String, dynamic> _toPayload(Mission m) {
    final y = m.date.year.toString().padLeft(4, '0');
    final mo = m.date.month.toString().padLeft(2, '0');
    final d = m.date.day.toString().padLeft(2, '0');
    final hh = m.time.hour.toString().padLeft(2, '0');
    final mm = m.time.minute.toString().padLeft(2, '0');

    return {
      'title': m.title,
      'fieldLocation': m.fieldLocation,
      'missionType': m.missionType,
      'date': '$y-$mo-$d',
      'time': '$hh:$mm',
      'notes': m.notes,
    };
  }

  static Mission _fromRow(Map<String, dynamic> r) {
    final id = (r['id'] as num).toInt();

    final dateStr = (r['date'] ?? '').toString();
    final partsD = dateStr.split('-');
    final date = DateTime(int.parse(partsD[0]), int.parse(partsD[1]), int.parse(partsD[2]));

    final timeStr = (r['time'] ?? '00:00').toString();
    final partsT = timeStr.split(':');
    final time = TimeOfDay(hour: int.parse(partsT[0]), minute: int.parse(partsT[1]));

    final notes = (r['notes'] == null) ? '' : r['notes'].toString();

    return Mission(
      id: id,
      title: r['title'].toString(),
      fieldLocation: r['fieldLocation'].toString(),
      missionType: r['missionType'].toString(),
      date: date,
      time: time,
      notes: notes,
    );
  }

  static String formatTime(TimeOfDay t) {
    final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final hh = hour12.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final ap = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hh:$mm $ap';
  }

  static String formatDateShort(DateTime d) {
    const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final wd = w[(d.weekday - 1).clamp(0, 6)];
    final dd = d.day.toString().padLeft(2, '0');
    final mo = d.month.toString().padLeft(2, '0');
    final yy = (d.year % 100).toString().padLeft(2, '0');
    return '$wd,$dd-$mo-$yy';
  }
}
