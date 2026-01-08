 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/vehicle_model.dart';
import '../widgets/vehicle_card.dart';

class SearchScreen extends StatefulWidget {
  // Có thể truyền từ khóa hoặc bộ lọc ban đầu vào đây nếu muốn
  final String? initialKeyword;
  final String? initialLocation;
  
  const SearchScreen({super.key, this.initialKeyword, this.initialLocation});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<VehicleModel> _allVehicles = []; // Danh sách gốc
  List<VehicleModel> _filteredVehicles = []; // Danh sách sau khi lọc
  bool _isLoading = true;
  bool _isSearching = false; // Để kiểm tra xem người dùng đã bấm tìm chưa
  String? _filterLocation;

  @override
  void initState() {
    super.initState();
    if (widget.initialKeyword != null) {
      _searchController.text = widget.initialKeyword!;
    }
    // Gán giá trị ban đầu được truyền từ Home
    _filterLocation = widget.initialLocation;
    _fetchAllVehicles();
  }

  // 1. Tải toàn bộ xe "approved" về trước (Client-side filtering)
  // Cách này tốt cho App < 5000 xe. Nếu nhiều hơn phải dùng giải pháp khác (Algolia).
  Future<void> _fetchAllVehicles() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .get();

      final data = snapshot.docs.map((doc) {
        return VehicleModel.fromMap(doc.data(), doc.id);
      }).toList();

      setState(() {
        _allVehicles = data;
        _isLoading = false;
        // Nếu có từ khóa ban đầu thì lọc luôn
        if (_searchController.text.isNotEmpty) {
          _runFilter(_searchController.text);
        } else {
           // Nếu chưa nhập gì thì hiện tất cả hoặc danh sách rỗng tùy bạn
           _filteredVehicles = data; 
        }
      });
    } catch (e) {
      print("Lỗi tải xe: $e");
      setState(() => _isLoading = false);
    }
  }

 // 2. CẬP NHẬT LOGIC LỌC (QUAN TRỌNG)
  void _runFilter(String keyword) {
    setState(() {
      _isSearching = true;
      
      // Bắt đầu từ danh sách gốc
      List<VehicleModel> temp = _allVehicles;

      // A. Lọc theo địa điểm (Nếu có)
      if (_filterLocation != null && _filterLocation != "Toàn quốc") {
        temp = temp.where((v) => v.location == _filterLocation).toList();
      }

      // B. Lọc theo từ khóa (Nếu có)
      if (keyword.isNotEmpty) {
        final searchLower = keyword.toLowerCase();
        temp = temp.where((vehicle) {
          final titleLower = vehicle.title.toLowerCase();
          final brandLower = vehicle.brand.toLowerCase();
          return titleLower.contains(searchLower) || brandLower.contains(searchLower);
        }).toList();
      }

      // Gán kết quả cuối cùng
      _filteredVehicles = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: Colors.black),
        title: TextField(
          controller: _searchController,
          autofocus: true, // Tự động bật bàn phím khi vào trang này
          decoration: const InputDecoration(
            hintText: "Nhập tên xe, hãng xe...",
            border: InputBorder.none,
          ),
          onChanged: _runFilter, // Gõ đến đâu lọc đến đó
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () {
              _searchController.clear();
              _runFilter('');
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredVehicles.isEmpty
              ? _buildEmptyState() // Hiện thông báo không tìm thấy
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _filteredVehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = _filteredVehicles[index];
                    // Dùng lại VehicleCard nhưng bọc SizedBox để tránh lỗi layout
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      height: 140, // Chiều cao cho item dạng danh sách ngang
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
                           const SizedBox(width: 10),
                           // Thông tin
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Text(vehicle.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                 Text("${vehicle.price} VND", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                 Text("${vehicle.brand} - ${vehicle.year}", style: const TextStyle(color: Colors.grey)),
                               ],
                             ),
                           )
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  // Widget hiển thị khi không tìm thấy
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            "Không tìm thấy kết quả nào cho \"${_searchController.text}\"",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}