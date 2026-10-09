/// Preserves the provisional OTP bridge capability without owning auth/session.
class OtpService {
  /// TODO(CONTRACT): Implement Android OTP retrieval only after the web team
  /// confirms how a received code is delivered into the PWA and the backend
  /// confirms its SMS Retriever-compatible message template.
  Future<Map<String, dynamic>> startListening() async => {
    'listening': false,
    'implemented': false,
    'message':
        'OTP native listening is not implemented until the web/native OTP contract is confirmed.',
  };
}
