class UpdateNameRequest {
  final String name;

  UpdateNameRequest({required this.name});

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}
