abstract interface class CopyrightComplaintService {
  Future<void> submitCopyrightComplaint({
    required Uri endpoint,
    required CopyrightComplaintSubmission complaint,
  });
}

final class CopyrightComplaintSubmission {
  CopyrightComplaintSubmission({
    required this.complainant,
    required this.email,
    required this.work,
    required this.ownership,
    required this.content,
    this.details = '',
  }) {
    if (complainant.trim().isEmpty ||
        complainant.length > 160 ||
        email.trim().isEmpty ||
        email.length > 254 ||
        !email.contains('@') ||
        work.trim().isEmpty ||
        work.length > 500 ||
        ownership.trim().isEmpty ||
        ownership.length > 2000 ||
        content.trim().isEmpty ||
        content.length > 2000 ||
        details.length > 2000) {
      throw ArgumentError('Invalid copyright complaint');
    }
  }

  final String complainant;
  final String email;
  final String work;
  final String ownership;
  final String content;
  final String details;
}
