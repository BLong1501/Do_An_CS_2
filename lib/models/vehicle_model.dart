import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final double price;
  final String brand;
  final String category;
  final int year;
  final int mileage;
  final String fuelType;
  final String location;
  final List<String> images;
  final String contactPhone;
  final bool isNegotiable;
  final int views;
  final String status; // pending, approved, rejected, sold
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;

  VehicleModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.price,
    required this.brand,
    required this.category,
    required this.year,
    required this.mileage,
    required this.fuelType,
    required this.location,
    required this.images,
    required this.contactPhone,
    this.isNegotiable = false,
    this.views = 0,
    this.status = 'pending',
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'title': title,
    'description': description,
    'price': price,
    'brand': brand,
    'category': category,
    'year': year,
    'mileage': mileage,
    'fuelType': fuelType,
    'location': location,
    'images': images,
    'contactPhone': contactPhone,
    'isNegotiable': isNegotiable,
    'views': views,
    'status': status,
    'approvedBy': approvedBy,
    'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory VehicleModel.fromMap(Map<String, dynamic> map, String id) {
    return VehicleModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      brand: map['brand'] ?? '',
      category: map['category'] ?? '',
      year: map['year'] ?? 2000,
      mileage: map['mileage'] ?? 0,
      fuelType: map['fuelType'] ?? 'Xăng',
      location: map['location'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      contactPhone: map['contactPhone'] ?? '',
      isNegotiable: map['isNegotiable'] ?? false,
      views: map['views'] ?? 0,
      status: map['status'] ?? 'pending',
      approvedBy: map['approvedBy'],
      approvedAt: map['approvedAt'] != null ? (map['approvedAt'] as Timestamp).toDate() : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}