import 'package:agronome/add_mission_page.dart';
import 'package:agronome/all_mission_page.dart';
import 'package:agronome/survey_api.dart';
import 'package:flutter/material.dart';
import 'mission_store.dart';

class AgronomeHomePage extends StatelessWidget {
  const AgronomeHomePage({super.key});

  static const Color bg = Color(0xFFF6F7F8);
  static const Color green = Color(0xFF76B947);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  BoxDecoration cardDeco({double r = 24}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = MissionStore.instance;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    'Agronome',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                ),
                const SizedBox(height: 14),

                // Card 1
                Container(
                  decoration: cardDeco(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        child: SizedBox(
                          height: 175,
                          width: double.infinity,
                          child: Image.network(
                            'https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?auto=format&fit=crop&w=1600&q=70',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(18, 16, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Crop Health Overview',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Monitor your field conditions and get real-time\ninsights from our latest aerial surveys.',
                              style: TextStyle(fontSize: 14, height: 1.45, color: textSecondary, fontWeight: FontWeight.w400),
                            ),
                            SizedBox(height: 14),
                            Text(
                              'Go to Next Page',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: green),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Card 2 (fetch 2nd latest, fallback to latest)
                Container(
                  decoration: cardDeco(),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: FutureBuilder<SurveyRecommendation?>(
                    future: SurveyApi.fetchSecondLatestOrLatest(),
                    builder: (context, snap) {
                      final reco = snap.data;

                      final message = () {
                        if (snap.connectionState == ConnectionState.waiting) return 'Loading recommendation...';
                        if (snap.hasError) return 'Failed to load recommendation.';
                        if (reco == null) return 'No recommendations yet.';
                        return reco.message;
                      }();

                      final priority = (reco == null) ? '' : SurveyApi.priorityText(reco.priorityLevel);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.spa_outlined, size: 22, color: textPrimary),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Recommendation from past surveys',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            message,
                            style: const TextStyle(fontSize: 14, height: 1.45, color: textSecondary),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (reco != null)
                                Text(
                                  priority,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: green,
                                    letterSpacing: 0.2,
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                              InkWell(
                                onTap: reco == null
                                    ? null
                                    : () {
                                        showModalBottomSheet(
                                          context: context,
                                          backgroundColor: Colors.white,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                          ),
                                          builder: (_) => Padding(
                                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  SurveyApi.priorityText(reco.priorityLevel),
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: green),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  reco.message,
                                                  style: const TextStyle(fontSize: 14, height: 1.45, color: textSecondary),
                                                ),
                                                const SizedBox(height: 10),
                                                if ((reco.imageUrl ?? '').isNotEmpty)
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(14),
                                                    child: Image.network(
                                                      reco.imageUrl!,
                                                      height: 160,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                child: const Text(
                                  'View Details',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),


                const SizedBox(height: 18),

                // Card 3
                Container(
                  decoration: cardDeco(),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  child: AnimatedBuilder(
                    animation: store,
                    builder: (context, _) {
                      final list = store.sortedMissions();
                      final next = list.isNotEmpty ? list.first : null;
                      final row1 = list.length > 1 ? list[1] : null;
                      final row2 = list.length > 2 ? list[2] : null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.assignment_outlined, size: 22, color: textPrimary),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Upcoming flight paths and reminders',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          if (next != null)
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBFBFB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFEDEEEF), width: 1),
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      _Dot(),
                                      SizedBox(width: 8),
                                      Text(
                                        'NEXT MISSION',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: green, letterSpacing: 0.2),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${MissionStore.formatTime(next.time)} - ${next.fieldLocation}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Scheduled mission for ${next.missionType}',
                                    style: const TextStyle(fontSize: 14, height: 1.45, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 10),

                          if (row1 != null) _HomeMissionRow(m: row1),
                          if (row1 != null) const Divider(height: 18, thickness: 1, color: Color(0xFFF0F1F2)),
                          if (row2 != null) _HomeMissionRow(m: row2),
                          if (row2 != null) const Divider(height: 18, thickness: 1, color: Color(0xFFF0F1F2)),
                          const SizedBox(height: 6),

                          InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AllMissionsPage()));
                            },
                            child: const Text(
                              'View All Missions',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: green),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AgronomeHomePage.green,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _HomeMissionRow extends StatelessWidget {
  final Mission m;
  const _HomeMissionRow({required this.m});

  @override
  Widget build(BuildContext context) {
    final store = MissionStore.instance;
    final idx = store.missions.indexOf(m);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${MissionStore.formatTime(m.time)} - ${m.fieldLocation}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AgronomeHomePage.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  m.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AgronomeHomePage.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => AddMissionDialog.open(context, initial: m, editIndex: idx),
            child: const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                'Edit',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AgronomeHomePage.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
