import 'package:flutter/material.dart';
import '../../models/vehicle_model.dart';
// Lưu ý: Cần thêm package 'intl' vào pubspec.yaml để format tiền cho đẹp
// intl: ^0.19.0
import 'package:intl/intl.dart'; 

class VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback onTap; // Hàm xử lý khi bấm vào thẻ

  const VehicleCard({
    super.key, 
    required this.vehicle, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    // Format giá tiền: VD 50000000 -> 50.000.000 đ
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Card(
      elevation: 2, // Độ đổ bóng
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ẢNH XE (Phần trên)
            Expanded(
              flex: 3, // Chiếm 3 phần chiều cao
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  image: vehicle.images.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(vehicle.images.first), // Lấy ảnh đầu tiên
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: vehicle.images.isEmpty
                    ? const Icon(Icons.image, color: Colors.grey, size: 50)
                    : null,
              ),
            ),
            
            // 2. THÔNG TIN (Phần dưới)
            Expanded(
              flex: 2, // Chiếm 2 phần chiều cao
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tên xe
                    Text(
                      vehicle.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis, // Dài quá thì hiện dấu ...
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    // Giá tiền
                    Text(
                      currencyFormatter.format(vehicle.price),
                      style: const TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.red
                      ),
                    ),
                    // Địa điểm & Thời gian
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            vehicle.location,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}