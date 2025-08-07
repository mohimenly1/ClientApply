class ShipmentRequest {
  final String description;
  final String senderName;
  final String receiverName;
  final String receiverPhone;
  final int cityId;
  final int customerId;

  ShipmentRequest({
    required this.description,
    required this.senderName,
    required this.receiverName,
    required this.receiverPhone,
    required this.cityId,
    required this.customerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'senderName': senderName,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'cityId': cityId,
      'customerId': customerId,
    };
  }
}
