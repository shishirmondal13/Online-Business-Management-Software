/// Firebase Auth emails that are trusted administrators for this project.
/// Keep this list synchronized with firestore.rules.
class AdminAccounts {
  AdminAccounts._();

  static const emails = <String>{
    'smart06buy08online25@gmail.com',
    'smshishir13@gmail.com',
    'raihan@gmail.com',
    'raihanx9@gmail.com',
    'smdew20@gmail.com',
    'test@gmail.com',
  };

  static bool contains(String? email) =>
      email != null && emails.contains(email.trim().toLowerCase());
}
