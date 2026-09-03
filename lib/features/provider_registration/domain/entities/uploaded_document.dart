enum DocumentType {
  medicalLicense,
  nationalId,
  specialtyCertificate,
  profilePhoto,
}

/// A locally-picked file, not yet uploaded to any real backend (mock-first app).
class UploadedDocument {
  const UploadedDocument({
    required this.id,
    required this.fileName,
    required this.sizeBytes,
    required this.localPath,
    required this.type,
  });

  final String id;
  final String fileName;
  final int sizeBytes;
  final String localPath;
  final DocumentType type;

  double get sizeMb => sizeBytes / (1024 * 1024);
}
