import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../models/vehicle_model.dart';

class VehicleApprovalTab extends StatelessWidget {
  const VehicleApprovalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Lắng nghe các xe đang chờ duyệt
      stream: FirebaseFirestore.instance
          .collection('vehicles')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Không có tin nào chờ duyệt"));

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final vehicle = VehicleModel.fromMap(data, docs[index].id);

            return Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                leading: Image.network(vehicle.images.first, width: 80, fit: BoxFit.cover),
                title: Text(vehicle.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${vehicle.price} VND - ${vehicle.brand}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nút Từ chối
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _updateStatus(vehicle.id, 'rejected'),
                    ),
                    // Nút Duyệt
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _updateStatus(vehicle.id, 'approved'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Hàm cập nhật trạng thái xe
  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance.collection('vehicles').doc(docId).update({'status': status});
  }
}