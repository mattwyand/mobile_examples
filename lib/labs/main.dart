import 'package:flutter/material.dart';
import 'grades_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(GradeApp());
}

class Grade {
  final int? id;
  final String sid;
  final String grade;

  Grade({this.id, required this.sid, required this.grade});

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{
      'sid': sid,
      'grade': grade,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Grade.fromMap(Map<String, dynamic> map) {
    return Grade(
      id: map['id'] as int?,
      sid: map['sid'] as String,
      grade: map['grade'] as String,
    );
  }
}

class GradeApp extends StatelessWidget {
  const GradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grade Entry System',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ListGrades(),
    );
  }
}

class ListGrades extends StatefulWidget {
  const ListGrades({super.key});

  @override
  State<ListGrades> createState() => _ListGradesState();
}

class _ListGradesState extends State<ListGrades> {
  final GradesModel _gradesModel = GradesModel();
  List<Grade> _grades = [];
  int? _selectedIndex;
  TapDownDetails? _tapDownDetails;
  int _sortMode = 0;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    final grades = await _gradesModel.getAllGrades();
    setState(() {
      _grades = grades;
      _sortGrades();
    });
  }

  Future<void> _addGrade() async {
    final newGrade = await Navigator.push<Grade>(
      context,
      MaterialPageRoute(builder: (ctx) => const GradeForm()),
    );
    if (newGrade != null) {
      await _gradesModel.insertGrade(newGrade);
      _loadGrades();
    }
  }

  Future<void> _editGrade() async {
    if (_selectedIndex == null) return;
    final grade = _grades[_selectedIndex!];
    final updatedGrade = await Navigator.push<Grade>(
      context,
      MaterialPageRoute(builder: (ctx) => GradeForm(existingGrade: grade)),
    );
    if (updatedGrade != null) {
      await _gradesModel.updateGrade(updatedGrade);
      _loadGrades();
    }
  }

  Future<void> _deleteGrade() async {
    if (_selectedIndex == null) return;
    final grade = _grades[_selectedIndex!];
    if (grade.id != null) {
      await _gradesModel.deleteGradeById(grade.id!);
      _loadGrades();
    }
  }

  void _showEditMenu(
    BuildContext context,
    Grade grade,
    TapDownDetails details,
  ) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: const [
        PopupMenuItem<String>(value: 'edit', child: Text('Edit Grade')),
      ],
    );

    if (result == 'edit') {
      final updatedGrade = await Navigator.push<Grade>(
        context,
        MaterialPageRoute(
          builder: (ctx) => GradeForm(
            existingGrade: grade,
            existingSids: _grades.map((g) => g.sid).toList(),
          ),
        ),
      );

      if (updatedGrade != null) {
        await _gradesModel.updateGrade(updatedGrade);
        _loadGrades();
      }
    }
  }

  void _cycleSortMode() {
    setState(() {
      _sortMode = (_sortMode + 1) % 4;
      _sortGrades();
    });

    final labels = [
      'SID Ascending',
      'SID Descending',
      'Grade Ascending',
      'Grade Descending',
    ];
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Sorted by ${labels[_sortMode]}')));
  }

  void _sortGrades() {
    _grades.sort((a, b) {
      switch (_sortMode) {
        case 0:
          return a.sid.compareTo(b.sid);
        case 1:
          return b.sid.compareTo(a.sid);
        case 2:
          return _gradeOrder(a.grade).compareTo(_gradeOrder(b.grade));
        case 3:
          return _gradeOrder(b.grade).compareTo(_gradeOrder(a.grade));
        default:
          return 0;
      }
    });
  }

  void _openChartPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => GradesChartPage(grades: _grades)),
    );
  }

  int _gradeOrder(String grade) {
    final RegExp exp = RegExp(r'([A-F])([+-]?)');
    final match = exp.firstMatch(grade.trim().toUpperCase());
    if (match == null) return 999;

    final letter = match.group(1)!;
    final modifier = match.group(2) ?? '';

    final baseValue = 'ABCDEF'.indexOf(letter);

    int modifierValue;
    switch (modifier) {
      case '+':
        modifierValue = 0;
        break;
      case '':
        modifierValue = 1;
        break;
      case '-':
        modifierValue = 2;
        break;
      default:
        modifierValue = 3;
    }

    return baseValue * 10 + modifierValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text('Grades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _cycleSortMode,
            tooltip: 'Sort',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _openChartPage,
            tooltip: 'Show Chart',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGrade,
        child: Icon(Icons.add),
      ),
      body: _grades.isEmpty
          ? const Center(child: Text('No grades yet. Use + to add.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _grades.length,
              itemBuilder: (context, index) {
                final g = _grades[index];
                final isSelected = _selectedIndex == index;

                return Dismissible(
                  key: Key(g.id?.toString() ?? g.sid),
                  // unique key
                  direction: DismissDirection.endToStart,
                  // swipe left to delete
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.red[400],
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Grade'),
                        content: Text('Delete ${g.sid} - ${g.grade}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    if (g.id != null) {
                      await _gradesModel.deleteGradeById(g.id!);
                      setState(() {
                        _grades.removeAt(index);
                        _selectedIndex = null;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${g.sid} deleted')),
                      );
                    }
                  },
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedIndex = index);
                    },
                    onTapDown: (details) {
                      _tapDownDetails = details;
                    },
                    onLongPress: () {
                      if (_tapDownDetails != null) {
                        _showEditMenu(context, g, _tapDownDetails!);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withOpacity(0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.4),
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        title: Text(
                          g.sid,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(g.grade),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class GradeForm extends StatefulWidget {
  final Grade? existingGrade;
  final List<String> existingSids;

  const GradeForm({
    super.key,
    this.existingGrade,
    this.existingSids = const <String>[],
  });

  @override
  State<GradeForm> createState() => _GradeFormState();
}

class _GradeFormState extends State<GradeForm> {
  final _formKey = GlobalKey<FormState>();
  final _sidController = TextEditingController();
  final _gradeController = TextEditingController();

  // Allowed grades
  final Set<String> validGrades = {
    'A+',
    'A',
    'A-',
    'B+',
    'B',
    'B-',
    'C+',
    'C',
    'C-',
    'D+',
    'D',
    'D-',
    'F',
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingGrade != null) {
      _sidController.text = widget.existingGrade!.sid;
      _gradeController.text = widget.existingGrade!.grade;
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final newGrade = Grade(
        id: widget.existingGrade?.id,
        sid: _sidController.text.trim(),
        grade: _gradeController.text.trim().toUpperCase(),
      );
      Navigator.pop(context, newGrade);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Grade'),
        backgroundColor: Colors.blue.shade300,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _sidController,
                decoration: InputDecoration(labelText: 'Student ID'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.length != 9) {
                    return 'Enter a 9-digit student ID';
                  }
                  // Allow same SID only when editing the same record
                  bool isDuplicate =
                      widget.existingSids.contains(value) &&
                      value != widget.existingGrade?.sid;
                  if (isDuplicate) {
                    return 'This Student ID already exists';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _gradeController,
                decoration: InputDecoration(labelText: 'Grade (A+ to F)'),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter a grade';
                  }
                  final grade = value.toUpperCase();
                  if (!validGrades.contains(grade)) {
                    return 'Invalid grade. Use A+, A, A-, …, F';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              FloatingActionButton.extended(
                onPressed: _saveForm,
                icon: Icon(Icons.save),
                label: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GradesChartPage extends StatelessWidget {
  final List<Grade> grades;

  const GradesChartPage({super.key, required this.grades});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> freq = {};
    for (var g in grades) {
      freq[g.grade] = (freq[g.grade] ?? 0) + 1;
    }

    final sortedKeys = freq.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Grade Distribution')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Grade Frequencies',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            DataTable(
              columns: const [
                DataColumn(label: Text('Grade')),
                DataColumn(label: Text('Frequency')),
              ],
              rows: [
                for (var grade in sortedKeys)
                  DataRow(
                    cells: [
                      DataCell(Text(grade)),
                      DataCell(Text(freq[grade].toString())),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 300,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxFreq = freq.values.isEmpty
                      ? 1
                      : freq.values.reduce((a, b) => a > b ? a : b);
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var grade in sortedKeys)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: (250 * (freq[grade]! / maxFreq))
                                      .clamp(0, 250),
                                  width: 24,
                                  color: Colors.blueAccent,
                                ),
                                const SizedBox(height: 4),
                                Text(grade),
                              ],
                            ),
                          ),
                      ],
                    ),
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
