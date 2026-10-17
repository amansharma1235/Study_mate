import 'sync_status.dart';

class ResumeProfileModel {
  final String fullName;
  final String email;
  final String phone;
  final String location;
  final String linkedin;
  final String github;
  final String summary;
  final List<String> skills;
  final List<Map<String, String>> education; // institution, degree, year, cgpa
  final List<Map<String, String>>
  projects; // title, techStack, description, link
  final List<Map<String, String>>
  experience; // role, company, duration, details

  ResumeProfileModel({
    required this.fullName,
    required this.email,
    this.phone = '',
    this.location = '',
    this.linkedin = '',
    this.github = '',
    this.summary = '',
    List<String>? skills,
    List<Map<String, String>>? education,
    List<Map<String, String>>? projects,
    List<Map<String, String>>? experience,
  }) : skills = skills ?? [],
       education = education ?? [],
       projects = projects ?? [],
       experience = experience ?? [];
}

class JobApplicationModel {
  final String id;
  final String userId;
  final String company;
  final String role;
  final String
  status; // 'Applied', 'Shortlisted', 'Interviewing', 'Offer', 'Rejected'
  final DateTime appliedDate;
  final DateTime? deadline;
  final String location;
  final String stipendOrSalary;
  final String notes;
  final String link;
  final SyncStatus syncStatus;

  JobApplicationModel({
    required this.id,
    required this.userId,
    required this.company,
    required this.role,
    this.status = 'Applied',
    DateTime? appliedDate,
    this.deadline,
    this.location = '',
    this.stipendOrSalary = '',
    this.notes = '',
    this.link = '',
    this.syncStatus = SyncStatus.synced,
  }) : appliedDate = appliedDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'company': company,
      'role': role,
      'status': status,
      'appliedDate': appliedDate.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'location': location,
      'stipendOrSalary': stipendOrSalary,
      'notes': notes,
      'link': link,
      'syncStatus': syncStatus.name,
    };
  }

  factory JobApplicationModel.fromMap(Map<String, dynamic> map) {
    return JobApplicationModel(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '',
      company: map['company'] as String? ?? '',
      role: map['role'] as String? ?? '',
      status: map['status'] as String? ?? 'Applied',
      appliedDate:
          DateTime.tryParse(map['appliedDate'] as String? ?? '') ??
          DateTime.now(),
      deadline: map['deadline'] != null
          ? DateTime.tryParse(map['deadline'] as String)
          : null,
      location: map['location'] as String? ?? '',
      stipendOrSalary: map['stipendOrSalary'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      link: map['link'] as String? ?? '',
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == map['syncStatus'],
        orElse: () => SyncStatus.synced,
      ),
    );
  }
}
