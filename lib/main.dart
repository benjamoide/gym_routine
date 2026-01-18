import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Training',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          isDense: true,
          hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// --- MODELOS ---
class Exercise {
  final String muscle;
  final String name;
  final String videoUrl;
  final String notes;
  final String targetSets;
  final String targetReps;
  final String targetRir;
  final String restTime;
  final String keyPoints;

  Exercise({
    required this.muscle,
    required this.name,
    required this.videoUrl,
    required this.notes,
    required this.targetSets,
    required this.targetReps,
    required this.targetRir,
    required this.restTime,
    required this.keyPoints,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      muscle: json['muscle'] ?? '',
      name: json['name'] ?? 'Ejercicio',
      videoUrl: json['video_url'] ?? '',
      notes: json['notes'] ?? '',
      targetSets: json['target_sets'] ?? '3',
      targetReps: json['target_reps'] ?? '-',
      targetRir: json['target_rir'] ?? '-',
      restTime: json['rest_time'] ?? '-',
      keyPoints: json['key_points'] ?? '',
    );
  }
}

class Session {
  final String sessionName;
  final List<Exercise> exercises;

  Session({required this.sessionName, required this.exercises});

  factory Session.fromJson(Map<String, dynamic> json) {
    var list = json['exercises'] as List? ?? [];
    List<Exercise> exercisesList = list.map((i) => Exercise.fromJson(i)).toList();
    return Session(sessionName: json['session_name'] ?? 'Sin nombre', exercises: exercisesList);
  }
}

class Week {
  final int weekNumber;
  final List<Session> sessions;

  Week({required this.weekNumber, required this.sessions});

  factory Week.fromJson(Map<String, dynamic> json) {
    var list = json['sessions'] as List? ?? [];
    List<Session> sessionsList = list.map((i) => Session.fromJson(i)).toList();
    return Week(weekNumber: json['week_number'], sessions: sessionsList);
  }
}

// --- PANTALLAS ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Week>> futureWeeks;

  @override
  void initState() {
    super.initState();
    futureWeeks = loadRoutineData();
  }

  Future<List<Week>> loadRoutineData() async {
    final String response = await rootBundle.loadString('assets/rutina_app.json');
    final data = json.decode(response) as List;
    return data.map((e) => Week.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BAZMAN TRAINING', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: FutureBuilder<List<Week>>(
        future: futureWeeks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay datos"));
          }

          final weeks = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: weeks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final week = weeks[index];
              return Card(
                elevation: 0,
                color: const Color(0xFF2C2C2C),
                child: ExpansionTile(
                  iconColor: Colors.amber,
                  collapsedIconColor: Colors.white70,
                  title: Text(
                    "SEMANA ${week.weekNumber}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                  children: week.sessions.map((session) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      title: Text(session.sessionName, style: const TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SessionDetailScreen(session: session),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SessionDetailScreen extends StatelessWidget {
  final Session session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(session.sessionName, style: const TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: session.exercises.length,
        itemBuilder: (context, index) {
          return ExerciseCard(exercise: session.exercises[index]);
        },
      ),
    );
  }
}

// --- TARJETA ---

class ExerciseCard extends StatefulWidget {
  final Exercise exercise;

  const ExerciseCard({super.key, required this.exercise});

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int setCount = 3;

  @override
  void initState() {
    super.initState();
    try {
      final firstNumber = RegExp(r'\d+').firstMatch(widget.exercise.targetSets);
      if (firstNumber != null) {
        setCount = int.parse(firstNumber.group(0)!);
      }
    } catch (e) {
      setCount = 3;
    }
  }

  Future<void> _launchVideo() async {
    if (widget.exercise.videoUrl.isEmpty) return;
    
    final url = Uri.parse(widget.exercise.videoUrl);
    bool couldLaunch = await launchUrl(url, mode: LaunchMode.externalApplication);
    
    if (!mounted) return;

    if (!couldLaunch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el video')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    bool hasVideo = widget.exercise.videoUrl.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. CABECERA
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    widget.exercise.muscle.toUpperCase(),
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.exercise.name,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasVideo)
                  IconButton(
                    onPressed: _launchVideo,
                    icon: const Icon(Icons.play_circle_fill, color: Colors.black, size: 28),
                    tooltip: "Ver Video",
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
              ],
            ),
          ),

          // 2. OBJETIVOS
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TargetBadge("OBJETIVO", "${widget.exercise.targetSets} x ${widget.exercise.targetReps}"),
                    _TargetBadge("RIR", widget.exercise.targetRir),
                    _TargetBadge("DESC", widget.exercise.restTime),
                  ],
                ),
                if (widget.exercise.notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                    child: Text("📝 ${widget.exercise.notes}", style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ),
                ]
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white10),

          // 3. INPUTS Y BOTONES
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                const Row(
                  children: [
                    SizedBox(width: 30, child: Text("#", style: TextStyle(color: Colors.grey, fontSize: 12))),
                    Expanded(child: Center(child: Text("KG", style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)))),
                    SizedBox(width: 10),
                    Expanded(child: Center(child: Text("REPS", style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)))),
                    SizedBox(width: 10),
                    Expanded(child: Center(child: Text("RIR", style: TextStyle(color: Colors.grey, fontSize: 12)))),
                  ],
                ),
                const SizedBox(height: 8),
                
                ...List.generate(setCount, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(width: 30, child: Text("${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white54))),
                        const Expanded(child: _InputBox(hint: "kg")),
                        const SizedBox(width: 10),
                        const Expanded(child: _InputBox(hint: "reps")),
                        const SizedBox(width: 10),
                        const Expanded(child: _InputBox(hint: "rir")),
                      ],
                    ),
                  );
                }),

                // BOTONES DE ACCIÓN (AÑADIR / QUITAR)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botones de control de series
                    Row(
                      children: [
                        // BOTÓN QUITAR
                        TextButton.icon(
                          onPressed: () {
                            if (setCount > 0) {
                              setState(() => setCount--);
                            }
                          },
                          icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.redAccent),
                          label: const Text("Quitar", style: TextStyle(color: Colors.redAccent)),
                        ),
                        
                        // BOTÓN AÑADIR
                        TextButton.icon(
                          onPressed: () => setState(() => setCount++),
                          icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.grey),
                          label: const Text("Añadir", style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),

                    // BOTÓN LISTO
                    ElevatedButton.icon(
                      onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Datos guardados!")));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        minimumSize: const Size(0, 32)
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text("Listo"),
                    )
                  ],
                )
              ],
            ),
          ),

          if (widget.exercise.keyPoints.isNotEmpty)
            ExpansionTile(
              title: const Text("💡 Claves Técnicas", style: TextStyle(fontSize: 13, color: Colors.amber)),
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(widget.exercise.keyPoints, style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4)),
              ],
            ),
        ],
      ),
    );
  }
}

class _TargetBadge extends StatelessWidget {
  final String label;
  final String value;
  const _TargetBadge(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}

class _InputBox extends StatelessWidget {
  final String hint;
  const _InputBox({required this.hint});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: TextField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hint,
          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.amber), borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}