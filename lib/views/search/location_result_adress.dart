import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/vehicle_model.dart';
import '../widgets/vehicle_card.dart';

class LocationResultScreen extends StatelessWidget {
  final String location;

  const LocationResultScreen({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    // Logic xác định Query
    Query query = FirebaseFirestore.instance.collection('vehicles')
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true);

    // Nếu không phải "Toàn quốc" thì thêm điều kiện lọc theo địa điểm
    if (location != "Toàn quốc") {
      query = query.where('location', isEqualTo: location);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          location == "Toàn quốc" ? "Tất cả khu vực" : "Xe tại $location",
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 80, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text("Chưa có xe nào tại $location", style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final vehicle = VehicleModel.fromMap(data, docs[index].id);

              // Tái sử dụng VehicleCard nhưng bọc Container để chỉnh chiều cao cho list dọc
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 140, 
                child: Row(
                  children: [
                    // Ảnh xe
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        vehicle.images.isNotEmpty ? vehicle.images.first : 'https://via.placeholder.com/150',
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Thông tin
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            vehicle.title, 
                            maxLines: 2, 
                            overflow: TextOverflow.ellipsis, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "${vehicle.price} VNĐ", 
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(vehicle.location, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}