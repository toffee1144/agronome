import 'package:agronome/add_mission_page.dart';
import 'package:flutter/material.dart';
import 'mission_store.dart';

class AllMissionsPage extends StatefulWidget {
  const AllMissionsPage({super.key});

  @override
  State<AllMissionsPage> createState() => _AllMissionsPageState();
}

class _AllMissionsPageState extends State<AllMissionsPage> {
  static const Color bg = Color(0xFFF6F7F8);
  static const Color green = Color(0xFF76B947);
  static const Color textPrimary = Color(0xFF111827);

  final store = MissionStore.instance;

  @override
  void initState() {
    super.initState();
    store.ensureLookupsLoaded();
    store.reloadMissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: green,
        elevation: 0,
        onPressed: () => AddMissionDialog.open(context),
        child: const Icon(Icons.add, size: 34),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0F1F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_left_rounded, size: 28, color: textPrimary),
                      ),
                    ),
                  ),
                  const Text(
                    'All Missions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: AnimatedBuilder(
                animation: store,
                builder: (context, _) {
                  final list = store.sortedMissions();
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final m = list[i];
                      final time = MissionStore.formatTime(m.time);
                      final date = MissionStore.formatDateShort(m.date);

                      return _MissionCard(
                        time: time,
                        title: '${m.fieldLocation} - ${m.title}',
                        typeLine: 'Type: ${m.missionType}',
                        dateLine: date,
                        onEdit: () {
                          final idx = store.missions.indexOf(m);
                          AddMissionDialog.open(context, initial: m, editIndex: idx);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final String time;
  final String title;
  final String typeLine;
  final String dateLine;
  final VoidCallback onEdit;

  const _MissionCard({
    required this.time,
    required this.title,
    required this.typeLine,
    required this.dateLine,
    required this.onEdit,
  });

  static const Color textPrimary = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    typeLine,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLine,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 32,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5BB870),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: const StadiumBorder(),
              ),
              onPressed: onEdit,
              child: const Text(
                'Edit',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
