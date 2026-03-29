import '../../shared/models/location_models.dart';

class WarehouseAddressModel {
  final String id;
  final String warehouseId;
  final AddressModel? addressDetails;

  WarehouseAddressModel({
    required this.id,
    required this.warehouseId,
    this.addressDetails,
  });

  factory WarehouseAddressModel.fromJson(Map<String, dynamic> json) {
    return WarehouseAddressModel(
      id: json['id']?.toString() ?? '',
      warehouseId: json['warehouse']?.toString() ?? '',
      addressDetails: json['address_details'] != null 
          ? AddressModel.fromJson(json['address_details']) 
          : null,
    );
  }
}
