class City {
  final int id;
  final String name;
  final double deliveryCost;

  City({required this.id, required this.name, required this.deliveryCost});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'],
      name: json['name'],
      deliveryCost: (json['deliveryCost'] ?? 0).toDouble(),
    );
  }
}
