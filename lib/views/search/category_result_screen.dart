import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../providers/vehicle_provider.dart';
import '../widgets/vehicle_card.dart';

class CategoryResultScreen extends StatefulWidget {
  final String category; // VD: "Xe máy", "Ô tô"

  const CategoryResultScreen({super.key, required this.category});

  @override
  State<CategoryResultScreen> createState() => _CategoryResultScreenState();
}

class _CategoryResultScreenState extends State<CategoryResultScreen> {
  // 1. CÁC BIẾN LƯU TRẠNG THÁI BỘ LỌC
  String? _selectedLocation;
  String? _selectedBrand;
  int? _selectedYear;

  // 2. HÀM HIỂN THỊ BẢNG LỌC (BOTTOM SHEET)
  void _showFilterModal() {
    final provider = Provider.of<VehicleProvider>(context, listen: false);
    
    // Lấy danh sách Hãng xe tương ứng với Danh mục hiện tại (VD: Chọn Xe máy chỉ hiện hãng Honda, Yamaha...)
    final brandList = provider.getBrandsByCategory(widget.category);
    
    // Tạo danh sách năm (VD: Từ 2026 lùi về 1990)
    final yearList = List.generate(37, (index) => DateTime.now().year + 1 - index);

    // Biến tạm để lưu lựa chọn trong Modal (tránh ảnh hưởng màn hình chính khi chưa bấm Áp dụng)
    String? tempLocation = _selectedLocation;
    String? tempBrand = _selectedBrand;
    int? tempYear = _selectedYear;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Để modal cao hơn nếu cần
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder( // Dùng StatefulBuilder để cập nhật UI bên trong Modal
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 500, // Chiều cao bảng lọc
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Bộ lọc tìm kiếm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          // Nút Xóa bộ lọc
                          setModalState(() {
                            tempLocation = null;
                            tempBrand = null;
                            tempYear = null;
                          });
                        },
                        child: const Text("Đặt lại", style: TextStyle(color: Colors.red)),
                      )
                    ],
                  ),
                  const Divider(),
                  
                  // --- 1. CHỌN KHU VỰC ---
                  const Text("Khu vực:", style: TextStyle(fontWeight: FontWeight.w600)),
                  DropdownButtonFormField<String>(
                    value: tempLocation,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text("Toàn quốc"),
                    items: provider.locations.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setModalState(() => tempLocation = val),
                  ),
                  const SizedBox(height: 15),

                  // --- 2. CHỌN HÃNG XE ---
                  const Text("Hãng xe:", style: TextStyle(fontWeight: FontWeight.w600)),
                  DropdownButtonFormField<String>(
                    value: tempBrand,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text("Tất cả hãng"),
                    items: brandList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setModalState(() => tempBrand = val),
                  ),
                  const SizedBox(height: 15),

                  // --- 3. CHỌN NĂM SX ---
                  const Text("Năm sản xuất:", style: TextStyle(fontWeight: FontWeight.w600)),
                  DropdownButtonFormField<int>(
                    value: tempYear,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text("Tất cả đời xe"),
                    items: yearList.map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
                    onChanged: (val) => setModalState(() => tempYear = val),
                  ),

                  const Spacer(),
                  
                  // --- NÚT ÁP DỤNG ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () {
                        // Cập nhật state của màn hình chính
                        setState(() {
                          _selectedLocation = tempLocation;
                          _selectedBrand = tempBrand;
                          _selectedYear = tempYear;
                        });
                        Navigator.pop(context); // Đóng modal
                      },
                      child: const Text("Áp dụng bộ lọc", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // NÚT MỞ BỘ LỌC
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                // Hiển thị chấm đỏ nếu đang có lọc
                if (_selectedBrand != null || _selectedLocation != null || _selectedYear != null)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                    ),
                  )
              ],
            ),
            onPressed: _showFilterModal,
          )
        ],
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        // 3. QUERY GỐC: Chỉ lọc Category và Approved
        // (Các lọc chi tiết sẽ làm ở Client-side bên dưới để tránh lỗi Index)
        stream: FirebaseFirestore.instance
            .collection('vehicles')
            .where('status', isEqualTo: 'approved')
            .where('category', isEqualTo: widget.category)
            .orderBy('createdAt', descending: true)
            .snapshots(),
            
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          
          // 4. LOGIC LỌC DỮ LIỆU (Client-side Filtering)
          // Lọc danh sách docs dựa trên các biến đã chọn
          final filteredVehicles = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return VehicleModel.fromMap(data, doc.id);
          }).where((vehicle) {
            // A. Lọc Địa điểm (Nếu có chọn)
            if (_selectedLocation != null && vehicle.location != _selectedLocation) {
              return false;
            }
            // B. Lọc Hãng xe (Nếu có chọn)
            if (_selectedBrand != null && vehicle.brand != _selectedBrand) {
              return false;
            }
            // C. Lọc Năm sx (Nếu có chọn)
            if (_selectedYear != null && vehicle.year != _selectedYear) {
              return false;
            }
            return true; // Giữ lại nếu thỏa mãn tất cả
          }).toList();

          // 5. HIỂN THỊ KẾT QUẢ
          if (filteredVehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.filter_alt_off, size: 80, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text("Không tìm thấy xe nào phù hợp bộ lọc.", style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedLocation = null;
                        _selectedBrand = null;
                        _selectedYear = null;
                      });
                    }, 
                    child: const Text("Xóa bộ lọc")
                  )
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: filteredVehicles.length,
            itemBuilder: (context, index) {
              final vehicle = filteredVehicles[index];

              // Tái sử dụng VehicleCard
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
                          Text(vehicle.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 5),
                          Text("${vehicle.price} VNĐ", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 5),
                          Text("${vehicle.brand} • ${vehicle.year}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 12, color: Colors.grey),
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