enum DocumentType {
  medicalLicense,
  nationalId,
  specialtyCertificate,
  profilePhoto,
}

/// A locally-picked file. [bytes] holds the actual file content in memory so
/// it can be uploaded for real to `POST /v1/provider-verification-documents`
/// right after registration submits — never persisted to Hive (too large;
/// see `RegistrationFormController._persist`, which deliberately drops it),
/// so a document picked in a previous app session must be re-picked before
/// it can actually upload.
class UploadedDocument {
  const UploadedDocument({
    required this.id,
    required this.fileName,
    required this.sizeBytes,
    required this.localPath,
    required this.type,
    this.bytes,
  });

  final String id;
  final String fileName;
  final int sizeBytes;
  final String localPath;
  final DocumentType type;
  final List<int>? bytes;

  double get sizeMb => sizeBytes / (1024 * 1024);
}
