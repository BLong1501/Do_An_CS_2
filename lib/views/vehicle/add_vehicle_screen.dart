import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../providers/vehicle_provider.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers cho các ô nhập liệu văn bản
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();

  // Biến lưu giá trị được chọn từ Dropdown
  // Lưu ý: Để null ban đầu để bắt buộc người dùng phải chọn
  String? _selectedCategory;
  String? _selectedBrand;
  String? _selectedFuel;
  String? _selectedLocation;

  // 3. Biến quản lý danh sách ảnh đã chọn
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    // 1. GỌI HÀM TẢI DỮ LIỆU TỪ FIREBASE KHI MỞ MÀN HÌNH
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VehicleProvider>(context, listen: false).fetchAppConfig();
    });
  }
  // 4. Hàm chọn ảnh từ thư viện
  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(); // Chọn nhiều ảnh
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((e) => File(e.path)).toList());
      });
    }
  }
  // Hàm xóa ảnh đã chọn (nếu user đổi ý)
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Không cần khai báo final vehicleProvider ở đây nữa vì đã dùng Consumer bên dưới
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng tin bán xe")),
      body: Consumer<VehicleProvider>(
        // 2. DÙNG CONSUMER ĐỂ LẤY DỮ LIỆU
        builder: (context, provider, child) {
          // Nếu đang tải dữ liệu thì hiện vòng quay
          if (provider.categories.isEmpty && provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                
                const Text(
                  "Thông tin cơ bản",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: "Tiêu đề bài đăng (VD: Honda Vision 2023)",
                  ),
                  validator: (val) =>
                      val!.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
                ),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: "Giá bán (VNĐ)",
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) => val!.isEmpty ? 'Nhập giá' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      // 3. DROPDOWN LOẠI XE (Lấy từ provider.categories)
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        hint: const Text("Loại xe"),
                        items: provider.categories
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategory = val;
                            _selectedBrand =
                                null; // ⚠️ QUAN TRỌNG: Reset hãng xe khi đổi loại xe
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Text(
                  "Thông số kỹ thuật",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),

                // 4. DROPDOWN HÃNG XE (Thay cho TextField cũ)
                Consumer<VehicleProvider>(
                  // Dùng Consumer để chắc chắn lấy dữ liệu mới nhất
                  builder: (context, provider, _) {
                    // Gọi hàm lọc mà ta vừa viết trong Provider
                    final filteredBrands = provider.getBrandsByCategory(
                      _selectedCategory,
                    );

                    return DropdownButtonFormField<String>(
                      value: _selectedBrand,
                      hint: const Text("Chọn Hãng xe"),
                      // Nếu chưa chọn Loại xe thì disable dropdown hãng
                      items: _selectedCategory == null
                          ? []
                          : filteredBrands
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                      onChanged: (val) => setState(() => _selectedBrand = val),
                      // Thêm dòng này để nếu list rỗng thì báo người dùng
                      decoration: InputDecoration(
                        labelText: "Hãng xe",
                        helperText: _selectedCategory == null
                            ? "Vui lòng chọn Loại xe trước"
                            : null,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          labelText: "Năm sản xuất",
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      // 5. DROPDOWN NHIÊN LIỆU (Lấy từ provider.fuelTypes)
                      child: DropdownButtonFormField<String>(
                        value: _selectedFuel,
                        hint: const Text("Nhiên liệu"),
                        items: provider.fuelTypes
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _selectedFuel = val),
                        decoration: const InputDecoration(
                          labelText: "Nhiên liệu",
                        ),
                      ),
                    ),
                  ],
                ),

                // 6. DROPDOWN ĐỊA ĐIỂM (Thay cho TextField cũ)
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  hint: const Text("Chọn khu vực bán"),
                  items: provider.locations
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedLocation = val),
                  validator: (val) => val == null ? 'Chọn khu vực' : null,
                  decoration: const InputDecoration(
                    labelText: "Khu vực / Thành phố",
                  ),
                ),

                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: "Số điện thoại liên hệ",
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (val) => val!.isEmpty ? 'Nhập SĐT' : null,
                ),

                TextFormField(
                  
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: "Mô tả chi tiết",
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 20),
                // --- THÊM GIAO DIỆN CHỌN ẢNH TẠI ĐÂY ---
                const Text("Hình ảnh xe (Tối đa 10 ảnh)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length + 1, // +1 cho nút thêm ảnh
                    itemBuilder: (context, index) {
                      // Nút thêm ảnh (Luôn nằm cuối)
                      if (index == _selectedImages.length) {
                        return GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: Colors.grey),
                                Text("Thêm ảnh", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      }

                      // Hiển thị ảnh đã chọn
                      return Stack(
                        children: [
                          Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: FileImage(_selectedImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 5, top: 5,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: const CircleAvatar(
                                radius: 10, backgroundColor: Colors.red,
                                child: Icon(Icons.close, size: 15, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const Divider(height: 30),

                const SizedBox(height: 30),
                provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: () => _submitData(provider),
                        child: const Text(
                          "ĐĂNG TIN NGAY",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submitData(VehicleProvider provider) async {
    if (_formKey.currentState!.validate()) {
      // 1. Kiểm tra xem đã chọn ảnh chưa
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng chọn ít nhất 1 ảnh xe!")),
        );
        return;
      }

      // Hiển thị thông báo đang xử lý
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đang tải ảnh và đăng tin...")),
      );

      // 2. Upload ảnh lên Firebase Storage để lấy link
      // (Hàm uploadImages này bạn đã viết trong VehicleProvider ở bước trước)
      List<String> imageUrls = await provider.uploadImages(_selectedImages);

      if (imageUrls.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi tải ảnh, vui lòng thử lại!")),
        );
        return;
      }

      // 3. Tạo Model với link ảnh thật (thay vì link ảo picsum)
      final newVehicle = VehicleModel(
        id: '',
        ownerId: FirebaseAuth.instance.currentUser!.uid,
        title: _titleController.text,
        description: _descController.text,
        price: double.parse(_priceController.text),
        brand: _selectedBrand!,
        category: _selectedCategory!,
        year: int.parse(_yearController.text),
        mileage: int.tryParse(_mileageController.text) ?? 0,
        fuelType: _selectedFuel ?? 'Xăng',
        location: _selectedLocation!,
        
        images: imageUrls, // <--- QUAN TRỌNG: Dùng link ảnh thật ở đây
        
        contactPhone: _phoneController.text,
        createdAt: DateTime.now(),
        status: 'pending',
      );

      final success = await provider.uploadVehicle(newVehicle);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã gửi bài đăng, chờ Admin duyệt!")),
        );
      }
    }
  }
}