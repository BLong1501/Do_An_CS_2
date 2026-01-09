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
  final DateTime createdAt;
  final String status;

  // --- 1. THÊM CÁC TRƯỜNG MỚI TẠI ĐÂY ---
  final String condition; // "Xe mới" hoặc "Đã sử dụng"
  final String origin;    // "Nhập khẩu" hoặc "Lắp ráp trong nước"
  final String capacity;  // Ví dụ: "150cc", "2.0L"
  final int weight;       // Đơn vị kg
  // ---------------------------------------
  final String color;

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
    required this.createdAt,
    required this.status,
    // Nhớ thêm vào constructor
    required this.condition,
    required this.origin,
    required this.capacity,
    required this.weight,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
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
      'createdAt': createdAt,
      'status': status,
      // Thêm vào Map để đẩy lên Firebase
      'condition': condition,
      'origin': origin,
      'capacity': capacity,
      'weight': weight,
      'color': color,
    };
  }

  factory VehicleModel.fromMap(Map<String, dynamic> map, String id) {
    return VehicleModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      brand: map['brand'] ?? '',
      category: map['category'] ?? '',
      year: map['year'] ?? 0,
      mileage: map['mileage'] ?? 0,
      fuelType: map['fuelType'] ?? '',
      location: map['location'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      contactPhone: map['contactPhone'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      // Lấy từ Firebase về (kèm giá trị mặc định tránh lỗi data cũ)
      condition: map['condition'] ?? 'Đã sử dụng',
      origin: map['origin'] ?? 'Lắp ráp trong nước',
      capacity: map['capacity'] ?? '',
      weight: map['weight'] ?? 0,
      color: map['color'] ?? 'Khác',
    );
  }
}