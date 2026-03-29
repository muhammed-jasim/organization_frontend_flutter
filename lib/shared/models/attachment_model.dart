class AttachmentModel {
  final String id;
  final String fileUrl;
  final String fileName;
  final String? fileType;
  final int? fileSize;
  final String? description;

  AttachmentModel({
    required this.id,
    required this.fileUrl,
    required this.fileName,
    this.fileType,
    this.fileSize,
    this.description,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'].toString(),
      fileUrl: json['file'] ?? '',
      fileName: json['file_name'] ?? '',
      fileType: json['file_type'],
      fileSize: json['file_size'],
      description: json['description'],
    );
  }
}
