/// A feature-level failure that the bridge translates into its generic error envelope.
class NativeOperationException implements Exception {
  final String code;
  final String message;

  const NativeOperationException(this.code, this.message);

  @override
  String toString() => 'NativeOperationException($code): $message';
}
