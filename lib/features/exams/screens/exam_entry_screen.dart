import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dstek/shared/widgets/app_drawer.dart';

enum ExamMode { test, deneme }

enum ExamEntryType { manuel, optikli }

class ExamEntryScreen extends StatefulWidget {
  final ExamMode mode;

  const ExamEntryScreen({super.key, this.mode = ExamMode.test});

  @override
  State<ExamEntryScreen> createState() => _ExamEntryScreenState();
}

class _ExamEntryScreenState extends State<ExamEntryScreen> {
  ExamEntryType _entryType = ExamEntryType.manuel;

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == ExamMode.test
        ? 'Test Girişleri'
        : 'Deneme Girişleri';

    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildEntryTypeSelector(context),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildBodyForMode(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTypeSelector(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Giriş türünü seç. Örnek: Manuel / Optikli',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            SegmentedButton<ExamEntryType>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment<ExamEntryType>(
                  value: ExamEntryType.manuel,
                  icon: Icon(Icons.edit_note_outlined),
                  label: Text('Manuel Giriş'),
                ),
                ButtonSegment<ExamEntryType>(
                  value: ExamEntryType.optikli,
                  icon: Icon(Icons.qr_code_scanner),
                  label: Text('Optikli Giriş'),
                ),
              ],
              selected: {_entryType},
              onSelectionChanged: (selection) {
                setState(() => _entryType = selection.first);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyForMode() {
    if (widget.mode == ExamMode.test) {
      if (_entryType == ExamEntryType.manuel) {
        return const ManualTestEntryTab(key: ValueKey('manual-test'));
      }
      return const OpticTestTab(key: ValueKey('optic-test'));
    }

    if (_entryType == ExamEntryType.manuel) {
      return const ManualPracticeExamEntryTab(key: ValueKey('manual-deneme'));
    }
    return const PracticeOpticExamTab(key: ValueKey('optic-deneme'));
  }
}

class NumericInputField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final bool enabled;

  const NumericInputField({
    super.key,
    required this.label,
    this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}

class CustomDropdown extends StatelessWidget {
  final String hint;
  final bool enabled;

  const CustomDropdown({super.key, required this.hint, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      items: const [
        DropdownMenuItem(value: '1', child: Text('Seçenek 1')),
        DropdownMenuItem(value: '2', child: Text('Seçenek 2')),
      ],
      onChanged: enabled ? (value) {} : null,
    );
  }
}

class ManualTestEntryTab extends StatefulWidget {
  const ManualTestEntryTab({super.key});

  @override
  State<ManualTestEntryTab> createState() => _ManualTestEntryTabState();
}

class _ManualTestEntryTabState extends State<ManualTestEntryTab> {
  static const String _duplicateErrorText =
      'Hata: Bu testi/denemeyi daha önce çözmüşsünüz. Mükerrer kayıt yapılamaz.';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _testNameController = TextEditingController();
  final TextEditingController _correctController = TextEditingController();
  final TextEditingController _wrongController = TextEditingController();
  final TextEditingController _emptyController = TextEditingController();

  List<CurriculumTopic> _curriculumTopics = [];
  List<String> _testTypeOptions = [];
  String? _selectedCourse;
  String? _selectedTopic;
  String? _selectedTestType;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDuplicateLocked = false;

  bool get _isFormLocked => _isSaving || _isDuplicateLocked;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _testNameController.dispose();
    _correctController.dispose();
    _wrongController.dispose();
    _emptyController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {required Color backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  String? get _studentId => FirebaseAuth.instance.currentUser?.uid;

  Future<bool> _hasDuplicateLog({required String testId}) async {
    final studentId = _studentId;
    if (studentId == null || testId.isEmpty) {
      return false;
    }

    final snapshot = await _firestore
        .collection('student_exam_logs')
        .where('student_id', isEqualTo: studentId)
        .where('test_id', isEqualTo: testId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<void> _saveManualTestEntry() async {
    final studentId = _studentId;
    if (studentId == null) {
      _showSnackBar(
        'Öğrenci oturumu bulunamadı.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    final testId = _testNameController.text.trim();
    if (testId.isEmpty) {
      _showSnackBar(
        'Lütfen test adını/ID bilgisini giriniz.',
        backgroundColor: Colors.orange.shade800,
      );
      return;
    }
    if (_selectedCourse == null ||
        _selectedTopic == null ||
        _selectedTestType == null) {
      _showSnackBar(
        'Lütfen ders, konu ve test türü alanlarını doldurunuz.',
        backgroundColor: Colors.orange.shade800,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final hasDuplicate = await _hasDuplicateLog(testId: testId);
      if (hasDuplicate) {
        if (!mounted) {
          return;
        }
        setState(() => _isDuplicateLocked = true);
        _showSnackBar(
          _duplicateErrorText,
          backgroundColor: Colors.deepOrange.shade700,
        );
        return;
      }

      final payload = {
        'student_id': studentId,
        'exam_mode': 'test',
        'entry_type': 'manuel',
        'test_id': testId,
        'test_name': testId,
        'course_name': _selectedCourse,
        'topic': _selectedTopic,
        'test_type': _selectedTestType,
        'correct_count': int.tryParse(_correctController.text.trim()) ?? 0,
        'wrong_count': int.tryParse(_wrongController.text.trim()) ?? 0,
        'empty_count': int.tryParse(_emptyController.text.trim()) ?? 0,
        'created_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('student_exam_logs').add(payload);

      if (!mounted) {
        return;
      }
      setState(() => _isDuplicateLocked = true);
      _showSnackBar(
        'İşleminiz tamamlandı',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      _showSnackBar(
        'Kayıt sırasında hata oluştu: $e',
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _loadOptions() async {
    try {
      final snapshots = await Future.wait([
        _firestore.collection('curriculum').get(),
        _firestore.collection('yks_optikli_test').get(),
      ]);

      final curriculumSnapshot = snapshots[0];
      final testTypeSnapshot = snapshots[1];

      final topics = <CurriculumTopic>[];
      for (final doc in curriculumSnapshot.docs) {
        final data = doc.data();
        final isActive = data['is_active'];
        final isRecordActive =
            isActive == true || isActive == 'TRUE' || isActive == 'true';
        if (!isRecordActive) {
          continue;
        }

        final code = data['konu_kodu']?.toString().trim() ?? '';
        final name = data['konu_adi']?.toString().trim() ?? '';
        final course = data['ders_adi']?.toString().trim() ?? 'Bilinmeyen Ders';
        if (code.isEmpty && name.isEmpty) {
          continue;
        }
        topics.add(CurriculumTopic(code: code, name: name, courseName: course));
      }

      final testTypes =
          testTypeSnapshot.docs
              .map((doc) => doc.data()['test_turu']?.toString().trim() ?? '')
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      topics.sort((a, b) {
        final byCourse = a.courseName.compareTo(b.courseName);
        if (byCourse != 0) {
          return byCourse;
        }
        return a.label.compareTo(b.label);
      });

      if (mounted) {
        setState(() {
          _curriculumTopics = topics;
          _testTypeOptions = testTypes;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(
          'Ders/Konu bilgileri yüklenemedi.',
          backgroundColor: Colors.red.shade700,
        );
      }
    }
  }

  List<String> get _courseOptions =>
      _curriculumTopics.map((topic) => topic.courseName).toSet().toList()
        ..sort();

  List<String> get _topicOptions {
    if (_selectedCourse == null) {
      return [];
    }
    return _curriculumTopics
        .where((topic) => topic.courseName == _selectedCourse)
        .map((topic) => topic.label)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedCourse,
            onChanged: _isFormLocked
                ? null
                : (value) {
                    setState(() {
                      _selectedCourse = value;
                      _selectedTopic = null;
                    });
                  },
            decoration: const InputDecoration(
              labelText: 'Ders seçiniz',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            items: _courseOptions
                .map(
                  (item) =>
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedTopic,
            decoration: const InputDecoration(
              labelText: 'Konu seçiniz',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            items: _topicOptions
                .map(
                  (item) =>
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                )
                .toList(),
            onChanged: _selectedCourse == null || _isFormLocked
                ? null
                : (value) => setState(() => _selectedTopic = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedTestType,
            decoration: const InputDecoration(
              labelText: 'Test türü',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            items: _testTypeOptions
                .map(
                  (item) =>
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                )
                .toList(),
            onChanged: _isFormLocked
                ? null
                : (value) => setState(() => _selectedTestType = value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _testNameController,
            enabled: !_isFormLocked,
            decoration: const InputDecoration(
              labelText: 'Test adı / ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: NumericInputField(
                  label: 'D',
                  controller: _correctController,
                  enabled: !_isFormLocked,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NumericInputField(
                  label: 'Y',
                  controller: _wrongController,
                  enabled: !_isFormLocked,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NumericInputField(
                  label: 'B',
                  controller: _emptyController,
                  enabled: !_isFormLocked,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isFormLocked ? null : _saveManualTestEntry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey.shade900,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(_isSaving ? 'Kaydediliyor...' : 'SİSTEME KAYDET'),
          ),
        ],
      ),
    );
  }
}

class CurriculumTopic {
  final String code;
  final String name;
  final String courseName;

  const CurriculumTopic({
    required this.code,
    required this.name,
    required this.courseName,
  });

  String get label => '$code $name';
}

class _LessonScoreEntry {
  final String title;
  final TextEditingController dController = TextEditingController();
  final TextEditingController yController = TextEditingController();
  final TextEditingController bController = TextEditingController();

  _LessonScoreEntry(this.title);

  Map<String, dynamic> toMap() {
    return {
      'lesson_title': title,
      'correct': int.tryParse(dController.text.trim()) ?? 0,
      'wrong': int.tryParse(yController.text.trim()) ?? 0,
      'empty': int.tryParse(bController.text.trim()) ?? 0,
    };
  }

  void dispose() {
    dController.dispose();
    yController.dispose();
    bController.dispose();
  }
}

class _WrongTopicEntry {
  String? selectedTopicLabel;
  final TextEditingController countController = TextEditingController();

  Map<String, dynamic> toMap() {
    return {
      'topic': selectedTopicLabel ?? '',
      'count': int.tryParse(countController.text.trim()) ?? 0,
    };
  }

  void dispose() {
    countController.dispose();
  }
}

class ManualPracticeExamEntryTab extends StatefulWidget {
  const ManualPracticeExamEntryTab({super.key});

  @override
  State<ManualPracticeExamEntryTab> createState() =>
      _ManualPracticeExamEntryTabState();
}

class _ManualPracticeExamEntryTabState
    extends State<ManualPracticeExamEntryTab> {
  static const String _duplicateErrorText =
      'Hata: Bu testi/denemeyi daha önce çözmüşsünüz. Mükerrer kayıt yapılamaz.';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _denemeInfoController = TextEditingController();
  final TextEditingController _timeNotSeenController = TextEditingController();

  final List<_LessonScoreEntry> _lessonRows = [
    _LessonScoreEntry('TYT Türkçe (40 soru)'),
    _LessonScoreEntry('TYT Sosyal (20 soru)'),
    _LessonScoreEntry('TYT Matematik (40 soru)'),
    _LessonScoreEntry('TYT Fen (20 soru)'),
  ];

  final List<_WrongTopicEntry> _wrongTopicRows = [_WrongTopicEntry()];

  List<CurriculumTopic> _curriculumTopics = [];
  String? _selectedDenemeType;
  bool _isLoadingTopics = true;
  bool _isSaving = false;
  bool _isDuplicateLocked = false;

  bool get _isFormLocked => _isSaving || _isDuplicateLocked;

  List<CurriculumTopic> get _filteredCurriculumTopics {
    final examType = (_selectedDenemeType ?? '').toUpperCase();
    if (examType == 'TYT' || examType == 'LGS') {
      return _curriculumTopics.where((topic) {
        final code = topic.code.toUpperCase();
        return code.startsWith('T_') ||
            code.startsWith('Y_') ||
            code.startsWith('L_');
      }).toList();
    }
    if (examType == 'AYT') {
      return _curriculumTopics
          .where((topic) => topic.code.toUpperCase().startsWith('A_'))
          .toList();
    }
    return _curriculumTopics;
  }

  @override
  void initState() {
    super.initState();
    _loadCurriculumTopics();
  }

  @override
  void dispose() {
    _denemeInfoController.dispose();
    _timeNotSeenController.dispose();
    for (final lesson in _lessonRows) {
      lesson.dispose();
    }
    for (final topic in _wrongTopicRows) {
      topic.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCurriculumTopics() async {
    try {
      final snapshot = await _firestore.collection('curriculum').get();
      final topics = <CurriculumTopic>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final isActive = data['is_active'];
        final isRecordActive =
            isActive == true || isActive == 'TRUE' || isActive == 'true';
        if (!isRecordActive) {
          continue;
        }

        final code = data['konu_kodu']?.toString().trim() ?? '';
        final name = data['konu_adi']?.toString().trim() ?? '';
        final course = data['ders_adi']?.toString().trim() ?? 'Bilinmeyen Ders';
        if (code.isEmpty && name.isEmpty) {
          continue;
        }
        topics.add(CurriculumTopic(code: code, name: name, courseName: course));
      }

      topics.sort((a, b) => a.label.compareTo(b.label));

      if (mounted) {
        setState(() {
          _curriculumTopics = topics;
          _isLoadingTopics = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingTopics = false);
        _showSnackBar(
          'Konu listesi yüklenemedi.',
          backgroundColor: Colors.red.shade700,
        );
      }
    }
  }

  void _showSnackBar(String message, {required Color backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  String? get _studentId => FirebaseAuth.instance.currentUser?.uid;

  Future<bool> _hasDuplicateLog({required String testId}) async {
    final studentId = _studentId;
    if (studentId == null || testId.isEmpty) {
      return false;
    }

    final snapshot = await _firestore
        .collection('student_exam_logs')
        .where('student_id', isEqualTo: studentId)
        .where('test_id', isEqualTo: testId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<void> _saveManualEntry() async {
    final studentId = _studentId;
    if (studentId == null) {
      _showSnackBar(
        'Öğrenci oturumu bulunamadı.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    final testId = _denemeInfoController.text.trim();
    if (testId.isEmpty) {
      _showSnackBar(
        'Lütfen deneme bilgisini giriniz.',
        backgroundColor: Colors.orange.shade800,
      );
      return;
    }

    if (_selectedDenemeType == null || _selectedDenemeType!.isEmpty) {
      _showSnackBar(
        'Lütfen deneme türünü seçiniz.',
        backgroundColor: Colors.orange.shade800,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final hasDuplicate = await _hasDuplicateLog(testId: testId);
      if (hasDuplicate) {
        if (!mounted) {
          return;
        }
        setState(() => _isDuplicateLocked = true);
        _showSnackBar(
          _duplicateErrorText,
          backgroundColor: Colors.deepOrange.shade700,
        );
        return;
      }

      final payload = {
        'student_id': studentId,
        'exam_mode': 'deneme',
        'entry_type': 'manuel',
        'test_id': testId,
        'test_name': testId,
        'exam_type': _selectedDenemeType,
        'time_not_seen_count':
            int.tryParse(_timeNotSeenController.text.trim()) ?? 0,
        'lesson_results': _lessonRows.map((row) => row.toMap()).toList(),
        'wrong_topics': _wrongTopicRows
            .map((row) => row.toMap())
            .where(
              (row) =>
                  (row['topic'] as String).trim().isNotEmpty ||
                  (row['count'] as int) > 0,
            )
            .toList(),
        'created_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('student_exam_logs').add(payload);

      if (!mounted) {
        return;
      }
      setState(() => _isDuplicateLocked = true);
      _showSnackBar(
        'İşleminiz tamamlandı',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      _showSnackBar(
        'Kayıt sırasında hata oluştu: $e',
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _denemeInfoController,
            enabled: !_isFormLocked,
            decoration: const InputDecoration(
              labelText: 'Deneme bilgisi. Örn: DST2601',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedDenemeType,
            decoration: const InputDecoration(
              labelText: 'Deneme türünü seçiniz. Örn: TYT',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'TYT', child: Text('TYT')),
              DropdownMenuItem(value: 'AYT', child: Text('AYT')),
              DropdownMenuItem(value: 'YDT', child: Text('YDT')),
              DropdownMenuItem(value: 'LGS', child: Text('LGS')),
            ],
            onChanged: _isFormLocked
                ? null
                : (value) {
                    setState(() {
                      _selectedDenemeType = value;
                      for (final row in _wrongTopicRows) {
                        row.selectedTopicLabel = null;
                      }
                    });
                  },
          ),
          const SizedBox(height: 24),
          ..._lessonRows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildLessonManualRow(
                title: row.title,
                dController: row.dController,
                yController: row.yController,
                bController: row.bController,
                enabled: !_isFormLocked,
              ),
            ),
          ),
          const SizedBox(height: 16),
          NumericInputField(
            label: 'Süre yetmediği için görülemeyen soru sayısı',
            controller: _timeNotSeenController,
            enabled: !_isFormLocked,
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Container(
                  color: Colors.grey.shade200,
                  padding: const EdgeInsets.all(8),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Doğru yapılamayan sorular alanı / Konu Kodu ve Adı',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Soru Sayısı',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoadingTopics)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _wrongTopicRows.length,
                    itemBuilder: (context, index) {
                      final row = _wrongTopicRows[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                initialValue: row.selectedTopicLabel,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Konu seçiniz',
                                  border: OutlineInputBorder(),
                                ),
                                items: _filteredCurriculumTopics
                                    .map(
                                      (topic) => DropdownMenuItem<String>(
                                        value: topic.label,
                                        child: Text(topic.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _isFormLocked
                                    ? null
                                    : (value) => setState(
                                        () => row.selectedTopicLabel = value,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: NumericInputField(
                                label: 'Adet',
                                controller: row.countController,
                                enabled: !_isFormLocked,
                              ),
                            ),
                            if (index > 0) ...[
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Satırı sil',
                                onPressed: _isFormLocked
                                    ? null
                                    : () {
                                        setState(() {
                                          final removed = _wrongTopicRows
                                              .removeAt(index);
                                          removed.dispose();
                                        });
                                      },
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                if (!_isLoadingTopics)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _isFormLocked
                            ? null
                            : () {
                                setState(() {
                                  _wrongTopicRows.add(_WrongTopicEntry());
                                });
                              },
                        icon: const Icon(Icons.add),
                        label: const Text('+ Yeni Konu Ekle'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isFormLocked ? null : _saveManualEntry,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(_isSaving ? 'Kaydediliyor...' : 'SİSTEME KAYDET'),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonManualRow({
    required String title,
    required TextEditingController dController,
    required TextEditingController yController,
    required TextEditingController bController,
    required bool enabled,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 1,
          child: NumericInputField(
            label: 'D',
            controller: dController,
            enabled: enabled,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: NumericInputField(
            label: 'Y',
            controller: yController,
            enabled: enabled,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: NumericInputField(
            label: 'B',
            controller: bController,
            enabled: enabled,
          ),
        ),
      ],
    );
  }
}

class OpticTestData {
  final String testTuru;
  final String yayinAdi;
  final String seri;
  final String konuKoduAdi;
  final String testAdi;
  final List<String> answers;

  const OpticTestData({
    required this.testTuru,
    required this.yayinAdi,
    required this.seri,
    required this.konuKoduAdi,
    required this.testAdi,
    required this.answers,
  });

  factory OpticTestData.fromMap(Map<String, dynamic> map) {
    final extractedAnswers = <String>[];
    for (int i = 1; i <= 120; i++) {
      final val = map[i.toString()]?.toString().trim();
      if (val != null && val.isNotEmpty) {
        extractedAnswers.add(val);
      } else {
        break;
      }
    }

    return OpticTestData(
      testTuru: map['test_turu']?.toString() ?? '',
      yayinAdi: map['yayin_adi']?.toString() ?? '',
      seri: map['seri']?.toString() ?? '',
      konuKoduAdi: map['konu_kodu_adi']?.toString() ?? '',
      testAdi: map['test_adi']?.toString() ?? '',
      answers: extractedAnswers,
    );
  }
}

class OpticTestTab extends StatefulWidget {
  const OpticTestTab({super.key});

  @override
  State<OpticTestTab> createState() => _OpticTestTabState();
}

class _OpticTestTabState extends State<OpticTestTab> {
  static const String _duplicateErrorText =
      'Hata: Bu testi/denemeyi daha önce çözmüşsünüz. Mükerrer kayıt yapılamaz.';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<CurriculumTopic> _curriculumTopics = [];

  String? _selectedCourse;
  String? _selectedTestTuru;
  String? _selectedYayinAdi;
  String? _selectedSeri;
  String? _selectedKonuKoduAdi;
  String? _selectedTestAdi;
  OpticTestData? _selectedTest;
  List<OpticTestData> _testList = [];
  List<String?> _selectedAnswers = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isInputLocked = false;
  bool _isDuplicateLocked = false;
  bool isChecked = false;

  int correctCount = 0;
  int wrongCount = 0;
  int emptyCount = 0;

  bool get _isFormLocked => _isInputLocked || _isDuplicateLocked || _isSaving;

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  void _showSnackBar(String message, {required Color backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  String? get _studentId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _loadTests() async {
    try {
      final snapshots = await Future.wait([
        _firestore.collection('yks_optikli_test').get(),
        _firestore.collection('curriculum').get(),
      ]);

      final snapshot = snapshots[0];
      final curriculumSnapshot = snapshots[1];

      final loadedTests = snapshot.docs
          .map((doc) {
            final data = doc.data();
            final parsed = OpticTestData.fromMap(data);
            return OpticTestData(
              testTuru: parsed.testTuru,
              yayinAdi: parsed.yayinAdi,
              seri: parsed.seri,
              konuKoduAdi: parsed.konuKoduAdi,
              testAdi: parsed.testAdi.isEmpty ? doc.id : parsed.testAdi,
              answers: parsed.answers,
            );
          })
          .where((e) => e.testAdi.isNotEmpty)
          .toList();

      final topics = <CurriculumTopic>[];
      for (final doc in curriculumSnapshot.docs) {
        final data = doc.data();
        final isActive = data['is_active'];
        final isRecordActive =
            isActive == true || isActive == 'TRUE' || isActive == 'true';
        if (!isRecordActive) {
          continue;
        }

        final code = data['konu_kodu']?.toString().trim() ?? '';
        final name = data['konu_adi']?.toString().trim() ?? '';
        final course = data['ders_adi']?.toString().trim() ?? 'Bilinmeyen Ders';
        if (code.isEmpty && name.isEmpty) {
          continue;
        }
        topics.add(CurriculumTopic(code: code, name: name, courseName: course));
      }

      if (mounted) {
        setState(() {
          _testList = loadedTests;
          _curriculumTopics = topics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(
          'Testler yüklenemedi: $e',
          backgroundColor: Colors.red.shade700,
        );
      }
    }
  }

  List<String> get _testTurleri =>
      _testList.map((e) => e.testTuru).toSet().toList();

  List<String> get _yayinAdlari {
    if (_selectedTestTuru == null) {
      return [];
    }
    return _testList
        .where((e) => e.testTuru == _selectedTestTuru)
        .map((e) => e.yayinAdi)
        .toSet()
        .toList();
  }

  List<String> get _seriListesi {
    if (_selectedTestTuru == null || _selectedYayinAdi == null) {
      return [];
    }
    return _testList
        .where(
          (e) =>
              e.testTuru == _selectedTestTuru &&
              e.yayinAdi == _selectedYayinAdi,
        )
        .map((e) => e.seri)
        .toSet()
        .toList();
  }

  List<String> get _konuKodlari {
    if (_selectedTestTuru == null ||
        _selectedYayinAdi == null ||
        _selectedSeri == null) {
      return [];
    }

    final selectedCourseCodes = _curriculumTopics
        .where((topic) => topic.courseName == _selectedCourse)
        .map((topic) => topic.code)
        .toSet();

    return _testList
        .where(
          (e) =>
              e.testTuru == _selectedTestTuru &&
              e.yayinAdi == _selectedYayinAdi &&
              e.seri == _selectedSeri &&
              (_selectedCourse == null ||
                  selectedCourseCodes.any(
                    (code) => e.konuKoduAdi.toUpperCase().contains(
                      code.toUpperCase(),
                    ),
                  )),
        )
        .map((e) => e.konuKoduAdi)
        .toSet()
        .toList();
  }

  List<String> get _courseOptions =>
      _curriculumTopics.map((topic) => topic.courseName).toSet().toList()
        ..sort();

  List<String> get _testAdlari {
    if (_selectedTestTuru == null ||
        _selectedYayinAdi == null ||
        _selectedSeri == null ||
        _selectedKonuKoduAdi == null) {
      return [];
    }
    return _testList
        .where(
          (e) =>
              e.testTuru == _selectedTestTuru &&
              e.yayinAdi == _selectedYayinAdi &&
              e.seri == _selectedSeri &&
              e.konuKoduAdi == _selectedKonuKoduAdi,
        )
        .map((e) => e.testAdi)
        .toSet()
        .toList();
  }

  void _resetBelow({required int level}) {
    switch (level) {
      case 1:
        _selectedYayinAdi = null;
        _selectedSeri = null;
        _selectedKonuKoduAdi = null;
        _selectedTestAdi = null;
        _selectedTest = null;
        break;
      case 2:
        _selectedSeri = null;
        _selectedKonuKoduAdi = null;
        _selectedTestAdi = null;
        _selectedTest = null;
        break;
      case 3:
        _selectedCourse = null;
        _selectedKonuKoduAdi = null;
        _selectedTestAdi = null;
        _selectedTest = null;
        break;
      case 4:
        _selectedTestAdi = null;
        _selectedTest = null;
        break;
      default:
        break;
    }

    _selectedAnswers = [];
    isChecked = false;
    _isInputLocked = false;
    _isDuplicateLocked = false;
    correctCount = 0;
    wrongCount = 0;
    emptyCount = 0;
  }

  void _selectTestAdi(String? value) {
    _selectedTestAdi = value;
    if (value == null) {
      _selectedTest = null;
      _selectedAnswers = [];
      return;
    }

    final found = _testList.where((e) => e.testAdi == value).toList();
    _selectedTest = found.isNotEmpty ? found.first : null;
    _selectedAnswers = List<String?>.filled(
      _selectedTest?.answers.length ?? 0,
      null,
    );
    _isInputLocked = false;
    _isDuplicateLocked = false;
    isChecked = false;
  }

  Future<bool> _hasDuplicateLog({required String testId}) async {
    final studentId = _studentId;
    if (studentId == null || testId.isEmpty) {
      return false;
    }

    final snapshot = await _firestore
        .collection('student_exam_logs')
        .where('student_id', isEqualTo: studentId)
        .where('test_id', isEqualTo: testId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  void _toggleAnswer(int index, String option) {
    if (_isFormLocked) {
      return;
    }
    setState(() {
      if (_selectedAnswers[index] == option) {
        _selectedAnswers[index] = null;
      } else {
        _selectedAnswers[index] = option;
      }
    });
  }

  Future<void> _checkAnswers() async {
    if (_selectedTest == null) {
      _showSnackBar(
        'Lütfen önce bir test seçiniz.',
        backgroundColor: Colors.orange.shade800,
      );
      return;
    }

    final hasDuplicate = await _hasDuplicateLog(testId: _selectedTest!.testAdi);
    if (hasDuplicate) {
      if (!mounted) {
        return;
      }
      setState(() => _isDuplicateLocked = true);
      _showSnackBar(
        _duplicateErrorText,
        backgroundColor: Colors.deepOrange.shade700,
      );
      return;
    }

    if (!mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Onay'),
          content: const Text('Emin misin? İşlem geri alınamaz.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Evet'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final totalQuestions = _selectedTest!.answers.length;
    final answeredCount = _selectedAnswers.where((e) => e != null).length;
    final correct = List.generate(totalQuestions, (index) {
      final answer = _selectedAnswers[index];
      return answer != null && answer == _selectedTest!.answers[index] ? 1 : 0;
    }).fold<int>(0, (acc, item) => acc + item);

    final empty = totalQuestions - answeredCount;
    final wrong = answeredCount - correct;

    setState(() {
      isChecked = true;
      _isInputLocked = true;
      correctCount = correct;
      wrongCount = wrong;
      emptyCount = empty;
    });

    _showSnackBar(
      'Kontrol tamamlandı: D:$correct, Y:$wrong, B:$empty, Toplam:$totalQuestions',
      backgroundColor: Colors.blue.shade700,
    );
  }

  Future<void> _saveOpticTestResult() async {
    if (!isChecked || _selectedTest == null) {
      return;
    }

    final studentId = _studentId;
    if (studentId == null) {
      _showSnackBar(
        'Öğrenci oturumu bulunamadı.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final hasDuplicate = await _hasDuplicateLog(
        testId: _selectedTest!.testAdi,
      );
      if (hasDuplicate) {
        if (!mounted) {
          return;
        }
        setState(() => _isDuplicateLocked = true);
        _showSnackBar(
          _duplicateErrorText,
          backgroundColor: Colors.deepOrange.shade700,
        );
        return;
      }

      await _firestore.collection('student_exam_logs').add({
        'student_id': studentId,
        'exam_mode': 'test',
        'entry_type': 'optikli',
        'test_id': _selectedTest!.testAdi,
        'test_name': _selectedTest!.testAdi,
        'test_turu': _selectedTestTuru,
        'yayin_adi': _selectedYayinAdi,
        'seri': _selectedSeri,
        'konu_kodu_adi': _selectedKonuKoduAdi,
        'correct_count': correctCount,
        'wrong_count': wrongCount,
        'empty_count': emptyCount,
        'question_count': _selectedTest!.answers.length,
        'selected_answers': _selectedAnswers,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }
      setState(() => _isDuplicateLocked = true);
      _showSnackBar(
        'İşleminiz tamamlandı',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      _showSnackBar(
        'Kayıt sırasında hata oluştu: $e',
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildResultPill(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required bool enabled,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDropdownField(
            label: 'Test Türü Seçiniz',
            value: _selectedTestTuru,
            items: _testTurleri,
            enabled: !_isFormLocked,
            onChanged: (value) {
              setState(() {
                _selectedTestTuru = value;
                _resetBelow(level: 1);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Yayın Adı Seçiniz',
            value: _selectedYayinAdi,
            items: _yayinAdlari,
            enabled: _selectedTestTuru != null && !_isFormLocked,
            onChanged: (value) {
              setState(() {
                _selectedYayinAdi = value;
                _resetBelow(level: 2);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Seri Seçiniz',
            value: _selectedSeri,
            items: _seriListesi,
            enabled: _selectedYayinAdi != null && !_isFormLocked,
            onChanged: (value) {
              setState(() {
                _selectedSeri = value;
                _resetBelow(level: 3);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Ders Seçiniz',
            value: _selectedCourse,
            items: _courseOptions,
            enabled: _selectedSeri != null && !_isFormLocked,
            onChanged: (value) {
              setState(() {
                _selectedCourse = value;
                _resetBelow(level: 4);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Konu Kodu ve Adı Seçiniz',
            value: _selectedKonuKoduAdi,
            items: _konuKodlari,
            enabled:
                _selectedSeri != null &&
                _selectedCourse != null &&
                !_isFormLocked,
            onChanged: (value) {
              setState(() {
                _selectedKonuKoduAdi = value;
                _resetBelow(level: 4);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Test Adı Seçiniz',
            value: _selectedTestAdi,
            items: _testAdlari,
            enabled: _selectedKonuKoduAdi != null && !_isFormLocked,
            onChanged: (value) {
              setState(() {
                _selectTestAdi(value);
              });
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Seçilen Test',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedTest?.testAdi ?? 'Henüz test seçilmedi',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedTest != null) ...[
            Text(
              '${_selectedTest!.testAdi} için ${_selectedTest!.answers.length} soruluk optik form',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    color: Colors.grey.shade200,
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'Soru No',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...['A', 'B', 'C', 'D', 'E'].map(
                          (e) => Expanded(
                            child: Center(
                              child: Text(
                                e,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedTest!.answers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 12.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${index + 1}. soru',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            ...['A', 'B', 'C', 'D', 'E'].map((option) {
                              final isSelected =
                                  _selectedAnswers[index] == option;
                              return Expanded(
                                child: Center(
                                  child: GestureDetector(
                                    onTap: _isFormLocked
                                        ? null
                                        : () => _toggleAnswer(index, option),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? colorScheme.primary
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? colorScheme.primary
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          color: isSelected
                                              ? colorScheme.onPrimary
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _isSaving
                  ? null
                  : (isChecked ? _saveOpticTestResult : _checkAnswers),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: isChecked
                      ? Colors.green.shade700
                      : colorScheme.primary,
                ),
                foregroundColor: isChecked
                    ? Colors.green.shade700
                    : colorScheme.primary,
              ),
              child: Text(
                _isSaving
                    ? 'Kaydediliyor...'
                    : (isChecked ? 'SİSTEME KAYDET' : 'KONTROL ET'),
              ),
            ),
            if (isChecked) ...[
              const SizedBox(height: 16),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    children: [
                      _buildResultPill(
                        'Doğru',
                        correctCount.toString(),
                        colorScheme.primary,
                      ),
                      _buildResultPill(
                        'Yanlış',
                        wrongCount.toString(),
                        Colors.red.shade700,
                      ),
                      _buildResultPill(
                        'Boş',
                        emptyCount.toString(),
                        Colors.grey.shade600,
                      ),
                      _buildResultPill(
                        'Toplam Soru',
                        _selectedTest!.answers.length.toString(),
                        Colors.blueGrey.shade700,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 24),
            const Text(
              'Test seçildikten sonra optik form burada oluşturulacaktır.',
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class PracticeOpticExamData {
  final String altSinavTuru;
  final String yayinAdi;
  final String seri;
  final String sayi;
  final String denemeAdi;
  final List<String> answers;

  const PracticeOpticExamData({
    required this.altSinavTuru,
    required this.yayinAdi,
    required this.seri,
    required this.sayi,
    required this.denemeAdi,
    required this.answers,
  });

  factory PracticeOpticExamData.fromMap(Map<String, dynamic> map) {
    final extractedAnswers = <String>[];
    for (int i = 1; i <= 120; i++) {
      final val = map['c_$i']?.toString().trim();
      if (val != null && val.isNotEmpty) {
        extractedAnswers.add(val);
      } else {
        break;
      }
    }

    return PracticeOpticExamData(
      altSinavTuru: map['alt_sinav_turu']?.toString() ?? '',
      yayinAdi: map['yayin_adi']?.toString() ?? '',
      seri: map['seri']?.toString() ?? '',
      sayi: map['sayi']?.toString() ?? '',
      denemeAdi: map['deneme_adi']?.toString() ?? '',
      answers: extractedAnswers,
    );
  }
}

class PracticeOpticExamTab extends StatefulWidget {
  const PracticeOpticExamTab({super.key});

  @override
  State<PracticeOpticExamTab> createState() => _PracticeOpticExamTabState();
}

class _PracticeOpticExamTabState extends State<PracticeOpticExamTab> {
  static const String _duplicateErrorText =
      'Hata: Bu testi/denemeyi daha önce çözmüşsünüz. Mükerrer kayıt yapılamaz.';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedAltSinavTuru;
  String? _selectedYayinAdi;
  String? _selectedSeri;
  String? _selectedSayi;
  String? _selectedDenemeAdi;
  PracticeOpticExamData? _selectedDeneme;
  List<PracticeOpticExamData> _denemeList = [];
  List<String?> _selectedAnswers = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isInputLocked = false;
  bool _isDuplicateLocked = false;
  bool isChecked = false;

  int correctCount = 0;
  int wrongCount = 0;
  int emptyCount = 0;

  bool get _isFormLocked => _isInputLocked || _isDuplicateLocked || _isSaving;

  @override
  void initState() {
    super.initState();
    _loadDenemeler();
  }

  void _showSnackBar(String message, {required Color backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  String? get _studentId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _loadDenemeler() async {
    try {
      final snapshot = await _firestore.collection('yks_optikli_deneme').get();
      final loadedDenemeler = snapshot.docs
          .map((doc) {
            final data = doc.data();
            final parsed = PracticeOpticExamData.fromMap(data);
            return PracticeOpticExamData(
              altSinavTuru: parsed.altSinavTuru,
              yayinAdi: parsed.yayinAdi,
              seri: parsed.seri,
              sayi: parsed.sayi,
              denemeAdi: parsed.denemeAdi.isEmpty ? doc.id : parsed.denemeAdi,
              answers: parsed.answers,
            );
          })
          .where((e) => e.denemeAdi.isNotEmpty)
          .toList();

      if (mounted) {
        setState(() {
          _denemeList = loadedDenemeler;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(
          'Denemeler yüklenemedi: $e',
          backgroundColor: Colors.red.shade700,
        );
      }
    }
  }

  List<String> get _altSinavTurleri =>
      _denemeList.map((e) => e.altSinavTuru).toSet().toList();

  List<String> get _yayinAdlari {
    if (_selectedAltSinavTuru == null) {
      return [];
    }
    return _denemeList
        .where((e) => e.altSinavTuru == _selectedAltSinavTuru)
        .map((e) => e.yayinAdi)
        .toSet()
        .toList();
  }

  List<String> get _seriListesi {
    if (_selectedAltSinavTuru == null || _selectedYayinAdi == null) {
      return [];
    }
    return _denemeList
        .where(
          (e) =>
              e.altSinavTuru == _selectedAltSinavTuru &&
              e.yayinAdi == _selectedYayinAdi,
        )
        .map((e) => e.seri)
        .toSet()
        .toList();
  }

  List<String> get _sayiListesi {
    if (_selectedAltSinavTuru == null ||
        _selectedYayinAdi == null ||
        _selectedSeri == null) {
      return [];
    }
    return _denemeList
        .where(
          (e) =>
              e.altSinavTuru == _selectedAltSinavTuru &&
              e.yayinAdi == _selectedYayinAdi &&
              e.seri == _selectedSeri,
        )
        .map((e) => e.sayi)
        .toSet()
        .toList();
  }

  List<String> get _denemeAdlari {
    if (_selectedAltSinavTuru == null ||
        _selectedYayinAdi == null ||
        _selectedSeri == null ||
        _selectedSayi == null) {
      return [];
    }
    return _denemeList
        .where(
          (e) =>
              e.altSinavTuru == _selectedAltSinavTuru &&
              e.yayinAdi == _selectedYayinAdi &&
              e.seri == _selectedSeri &&
              e.sayi == _selectedSayi,
        )
        .map((e) => e.denemeAdi)
        .toSet()
        .toList();
  }

  void _resetBelow({required int level}) {
    switch (level) {
      case 1:
        _selectedYayinAdi = null;
        _selectedSeri = null;
        _selectedSayi = null;
        _selectedDenemeAdi = null;
        _selectedDeneme = null;
        break;
      case 2:
        _selectedSeri = null;
        _selectedSayi = null;
        _selectedDenemeAdi = null;
        _selectedDeneme = null;
        break;
      case 3:
        _selectedSayi = null;
        _selectedDenemeAdi = null;
        _selectedDeneme = null;
        break;
      case 4:
        _selectedDenemeAdi = null;
        _selectedDeneme = null;
        break;
      default:
        break;
    }

    _selectedAnswers = [];
    isChecked = false;
    _isInputLocked = false;
    _isDuplicateLocked = false;
    correctCount = 0;
    wrongCount = 0;
    emptyCount = 0;
  }

  void _selectDenemeAdi(String? value) {
    _selectedDenemeAdi = value;
    if (value == null) {
      _selectedDeneme = null;
      _selectedAnswers = [];
      isChecked = false;
      _isInputLocked = false;
      _isDuplicateLocked = false;
      correctCount = 0;
      wrongCount = 0;
      emptyCount = 0;
      return;
    }

    final found = _denemeList.where((e) => e.denemeAdi == value).toList();
    _selectedDeneme = found.isNotEmpty ? found.first : null;
    _selectedAnswers = List<String?>.filled(
      _selectedDeneme?.answers.length ?? 0,
      null,
    );
    isChecked = false;
    _isInputLocked = false;
    _isDuplicateLocked = false;
    correctCount = 0;
    wrongCount = 0;
    emptyCount = 0;
  }

  Future<bool> _hasDuplicateLog({required String testId}) async {
    final studentId = _studentId;
    if (studentId == null || testId.isEmpty) {
      return false;
    }

    final snapshot = await _firestore
        .collection('student_exam_logs')
        .where('student_id', isEqualTo: studentId)
        .where('test_id', isEqualTo: testId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  void _toggleAnswer(int index, String option) {
    if (_isFormLocked) {
      return;
    }
    setState(() {
      if (_selectedAnswers[index] == option) {
        _selectedAnswers[index] = null;
      } else {
        _selectedAnswers[index] = option;
      }
    });
  }

  Future<void> _checkAnswers() async {
    if (_selectedDeneme == null) {
      _showSnackBar(
        'Lütfen önce bir deneme seçiniz.',
        backgroundColor: Colors.orange.shade800,
      );
      return;
    }

    final hasDuplicate = await _hasDuplicateLog(
      testId: _selectedDeneme!.denemeAdi,
    );
    if (hasDuplicate) {
      if (!mounted) {
        return;
      }
      setState(() => _isDuplicateLocked = true);
      _showSnackBar(
        _duplicateErrorText,
        backgroundColor: Colors.deepOrange.shade700,
      );
      return;
    }

    if (!mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Onay'),
          content: const Text('Emin misin? İşlem geri alınamaz.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Evet'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final totalQuestions = _selectedDeneme!.answers.length;
    final answeredCount = _selectedAnswers.where((e) => e != null).length;
    final correct = List.generate(totalQuestions, (index) {
      final answer = _selectedAnswers[index];
      return answer != null && answer == _selectedDeneme!.answers[index]
          ? 1
          : 0;
    }).fold<int>(0, (acc, item) => acc + item);

    final empty = totalQuestions - answeredCount;
    final wrong = answeredCount - correct;

    setState(() {
      isChecked = true;
      _isInputLocked = true;
      correctCount = correct;
      wrongCount = wrong;
      emptyCount = empty;
    });

    _showSnackBar(
      'Kontrol tamamlandı: D:$correct, Y:$wrong, B:$empty, Toplam:$totalQuestions',
      backgroundColor: Colors.blue.shade700,
    );
  }

  Future<void> _savePracticeOpticExamResult() async {
    if (!isChecked || _selectedDeneme == null) {
      return;
    }

    final studentId = _studentId;
    if (studentId == null) {
      _showSnackBar(
        'Öğrenci oturumu bulunamadı.',
        backgroundColor: Colors.red.shade700,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final hasDuplicate = await _hasDuplicateLog(
        testId: _selectedDeneme!.denemeAdi,
      );
      if (hasDuplicate) {
        if (!mounted) {
          return;
        }
        setState(() => _isDuplicateLocked = true);
        _showSnackBar(
          _duplicateErrorText,
          backgroundColor: Colors.deepOrange.shade700,
        );
        return;
      }

      await _firestore.collection('student_exam_logs').add({
        'student_id': studentId,
        'exam_mode': 'deneme',
        'entry_type': 'optikli',
        'test_id': _selectedDeneme!.denemeAdi,
        'test_name': _selectedDeneme!.denemeAdi,
        'alt_sinav_turu': _selectedAltSinavTuru,
        'yayin_adi': _selectedYayinAdi,
        'seri': _selectedSeri,
        'sayi': _selectedSayi,
        'correct_count': correctCount,
        'wrong_count': wrongCount,
        'empty_count': emptyCount,
        'question_count': _selectedDeneme!.answers.length,
        'selected_answers': _selectedAnswers,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }
      setState(() => _isDuplicateLocked = true);
      _showSnackBar(
        'İşleminiz tamamlandı',
        backgroundColor: Colors.green.shade700,
      );
    } catch (e) {
      _showSnackBar(
        'Kayıt sırasında hata oluştu: $e',
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildResultPill(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required bool enabled,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDropdownField(
            label: 'Alt Sınav Türü Seçiniz',
            value: _selectedAltSinavTuru,
            items: _altSinavTurleri,
            enabled: !_isFormLocked,
            onChanged: (value) {
              setState(() {
                _selectedAltSinavTuru = value;
                _resetBelow(level: 1);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Yayınevi Seçiniz',
            value: _selectedYayinAdi,
            items: _yayinAdlari,
            enabled: _selectedAltSinavTuru != null && !_isFormLocked,
            onChanged: (value) {
              setState(() {
                _selectedYayinAdi = value;
                _resetBelow(level: 2);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Seri Seçiniz',
            value: _selectedSeri,
            items: _seriListesi,
            enabled: _selectedYayinAdi != null && !_isFormLocked,
            onChanged: (value) {
              setState(() {
                _selectedSeri = value;
                _resetBelow(level: 3);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Deneme Sayısı Seçiniz',
            value: _selectedSayi,
            items: _sayiListesi,
            enabled: _selectedSeri != null && !_isFormLocked,
            onChanged: (value) {
              setState(() {
                _selectedSayi = value;
                _resetBelow(level: 4);
              });
            },
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Deneme Adı Seçiniz',
            value: _selectedDenemeAdi,
            items: _denemeAdlari,
            enabled: _selectedSayi != null && !_isFormLocked,
            onChanged: (value) {
              setState(() {
                _selectDenemeAdi(value);
              });
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Seçilen Deneme',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedDeneme?.denemeAdi ?? 'Henüz deneme seçilmedi',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedDeneme != null) ...[
            Text(
              '${_selectedDeneme!.denemeAdi} için ${_selectedDeneme!.answers.length} soruluk optik form',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    color: Colors.grey.shade200,
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'Soru No',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...['A', 'B', 'C', 'D', 'E'].map(
                          (e) => Expanded(
                            child: Center(
                              child: Text(
                                e,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedDeneme!.answers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 12.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${index + 1}. soru',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            ...['A', 'B', 'C', 'D', 'E'].map((option) {
                              final isSelected =
                                  _selectedAnswers[index] == option;
                              return Expanded(
                                child: Center(
                                  child: GestureDetector(
                                    onTap: _isFormLocked
                                        ? null
                                        : () => _toggleAnswer(index, option),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? colorScheme.primary
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? colorScheme.primary
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          color: isSelected
                                              ? colorScheme.onPrimary
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _isSaving
                  ? null
                  : (isChecked ? _savePracticeOpticExamResult : _checkAnswers),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: isChecked
                      ? Colors.green.shade700
                      : colorScheme.primary,
                ),
                foregroundColor: isChecked
                    ? Colors.green.shade700
                    : colorScheme.primary,
              ),
              child: Text(
                _isSaving
                    ? 'Kaydediliyor...'
                    : (isChecked ? 'SİSTEME KAYDET' : 'KONTROL ET'),
              ),
            ),
            if (isChecked) ...[
              const SizedBox(height: 16),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    children: [
                      _buildResultPill(
                        'Doğru',
                        correctCount.toString(),
                        colorScheme.primary,
                      ),
                      _buildResultPill(
                        'Yanlış',
                        wrongCount.toString(),
                        Colors.red.shade700,
                      ),
                      _buildResultPill(
                        'Boş',
                        emptyCount.toString(),
                        Colors.grey.shade600,
                      ),
                      _buildResultPill(
                        'Toplam Soru',
                        _selectedDeneme!.answers.length.toString(),
                        Colors.blueGrey.shade700,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 24),
            const Text(
              'Deneme seçildikten sonra optik form burada oluşturulacaktır.',
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
