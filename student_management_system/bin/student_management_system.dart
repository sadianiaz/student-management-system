import 'dart:convert';
import 'dart:io';

class Student {
  int id;
  String name;
  int age;
  String course;
  String email;

  Student({
    required this.id,
    required this.name,
    required this.age,
    required this.course,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'course': course,
    'email': email,
  };

  static Student fromJson(Map<String, dynamic> json) => Student(
    id: json['id'] as int,
    name: json['name'] as String,
    age: json['age'] as int,
    course: json['course'] as String,
    email: json['email'] as String,
  );

  @override
  String toString() {
    return 'ID: $id | Name: $name | Age: $age | Course: $course | Email: $email';
  }
}

class StudentManager {
  final String storageFile;
  List<Student> students = [];
  int _nextId = 1;

  StudentManager({this.storageFile = 'students.json'}) {
    _load();
  }

  void _load() {
    final file = File(storageFile);
    if (!file.existsSync()) {
      file.writeAsStringSync('[]');
      return;
    }
    try {
      final text = file.readAsStringSync();
      final data = jsonDecode(text) as List<dynamic>;
      students = data
          .map((e) => Student.fromJson(e as Map<String, dynamic>))
          .toList();
      if (students.isNotEmpty) {
        _nextId = students.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1;
      }
    } catch (e) {
      print('Failed to load students: $e');
      students = [];
    }
  }

  void _save() {
    final file = File(storageFile);
    final jsonText = jsonEncode(students.map((s) => s.toJson()).toList());
    file.writeAsStringSync(jsonText);
  }

  void addStudent(String name, int age, String course, String email) {
    final student = Student(
      id: _nextId++,
      name: name,
      age: age,
      course: course,
      email: email,
    );
    students.add(student);
    _save();
    print('Student added with ID ${student.id}.');
  }

  void listStudents() {
    if (students.isEmpty) {
      print('No students found.');
      return;
    }
    print('--- Students ---');
    for (var s in students) {
      print(s);
    }
    print('----------------');
  }

  Student? findById(int id) {
    for (var s in students) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<Student> searchByName(String query) {
    final q = query.toLowerCase();
    return students.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  void updateStudent(
    int id, {
    String? name,
    int? age,
    String? course,
    String? email,
  }) {
    final student = findById(id);
    if (student == null) {
      print('No student found with ID $id.');
      return;
    }
    if (name != null) student.name = name;
    if (age != null) student.age = age;
    if (course != null) student.course = course;
    if (email != null) student.email = email;
    _save();
    print('Student $id updated.');
  }

  void deleteStudent(int id) {
    students.removeWhere((s) => s.id == id);
    _save();
    print('If existed, student with ID $id was deleted.');
  }
}

String prompt(String message, {bool allowEmpty = false}) {
  stdout.write(message);
  final input = stdin.readLineSync();
  if (!allowEmpty && (input == null || input.trim().isEmpty)) {
    return prompt(message, allowEmpty: allowEmpty);
  }
  return input ?? '';
}

int promptInt(String message) {
  final input = prompt(message);
  final val = int.tryParse(input);
  if (val == null) {
    print('Please enter a valid number.');
    return promptInt(message);
  }
  return val;
}

void main() {
  final manager = StudentManager();
  print('Simple Student Management System (single file)');
  while (true) {
    print('\nMenu:');
    print('1) Add student');
    print('2) List students');
    print('3) Search by name');
    print('4) View by ID');
    print('5) Update student');
    print('6) Delete student');
    print('0) Exit');
    final choice = prompt('Choose an option: ');

    switch (choice) {
      case '1':
        final name = prompt('Name: ');
        final age = promptInt('Age: ');
        final course = prompt('Course: ');
        final email = prompt('Email: ');
        manager.addStudent(name, age, course, email);
        break;
      case '2':
        manager.listStudents();
        break;
      case '3':
        final q = prompt('Search name: ');
        final results = manager.searchByName(q);
        if (results.isEmpty) {
          print('No matches.');
        } else {
          results.forEach(print);
        }
        break;
      case '4':
        final id = promptInt('Enter ID: ');
        final s = manager.findById(id);
        if (s == null)
          print('Not found.');
        else
          print(s);
        break;
      case '5':
        final idToUpdate = promptInt('ID to update: ');
        final s = manager.findById(idToUpdate);
        if (s == null) {
          print('No student with that ID.');
          break;
        }
        print('Press Enter to keep existing value.');
        final newName = prompt('Name (${s.name}): ', allowEmpty: true);
        final ageInput = prompt('Age (${s.age}): ', allowEmpty: true);
        final newCourse = prompt('Course (${s.course}): ', allowEmpty: true);
        final newEmail = prompt('Email (${s.email}): ', allowEmpty: true);

        manager.updateStudent(
          idToUpdate,
          name: newName.trim().isEmpty ? null : newName,
          age: ageInput.trim().isEmpty ? null : int.tryParse(ageInput),
          course: newCourse.trim().isEmpty ? null : newCourse,
          email: newEmail.trim().isEmpty ? null : newEmail,
        );
        break;
      case '6':
        final idToDelete = promptInt('ID to delete: ');
        manager.deleteStudent(idToDelete);
        break;
      case '0':
        print('Goodbye!');
        exit(0);
      default:
        print('Invalid option. Try again.');
    }
  }
}
