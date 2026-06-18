import 'dart:io';

// import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../providers/vehicle_provider.dart';

class AddVehicleScreen extends StatefulWidget {
  final bool isStorePost;
  final VehicleModel? vehicleToEdit;
  const AddVehicleScreen({
    super.key,
    this.isStorePost = false,
    this.vehicleToEdit,
  });

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
  final TextEditingController _capacityController = TextEditingController(); // Dung tích
  final TextEditingController _weightController = TextEditingController(); // Trọng lượng

  String? _selectedCondition; // Lưu tình trạng xe
  String? _selectedOrigin; // Lưu xuất xứA

  // List dữ liệu cứng
  final List<String> _conditions = ["Xe mới", "Đã sử dụng"];
  final List<String> _origins = ["Lắp ráp trong nước", "Nhập khẩu"];
  
  String? _selectedCategory;
  String? _selectedBrand;
  String? _selectedFuel;
  String? _selectedLocation;
  String? _selectedColor; 

  // 3. Biến quản lý danh sách ảnh đã chọn
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  List<String> _existingImages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VehicleProvider>(context, listen: false).fetchAppConfig();
    });
    if (widget.vehicleToEdit != null) {
      final v = widget.vehicleToEdit!;

      _titleController.text = v.title;
      _priceController.text = v.price.toStringAsFixed(0); 
      _yearController.text = v.year.toString();
      _mileageController.text = v.mileage.toString();
      _phoneController.text = v.contactPhone;
      _descController.text = v.description;
      _capacityController.text = v.capacity;
      _weightController.text = v.weight.toString();

      _selectedCategory = v.category;
      _selectedBrand = v.brand;
      _selectedFuel = v.fuelType;
      _selectedLocation = v.location;
      _selectedColor = v.color;
      _selectedCondition = v.condition;
      _selectedOrigin = v.origin;

      _existingImages = List.from(v.images);
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(); 
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((e) => File(e.path)).toList());
      });
    }
  }
  
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // 👇 HÀM TẠO GIAO DIỆN BOX BO TRÒN DÙNG CHUNG 👇
  InputDecoration _customInputStyle(String label, {String? suffix, String? helper}) {
    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      helperText: helper,
      filled: true,
      fillColor: Colors.grey[50], // Màu nền xám thật nhẹ
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), // Độ bo góc
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5D3FD3), width: 1.5), // Đổi màu viền khi bấm vào
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }
  // 👆 KẾT THÚC HÀM GIAO DIỆN 👆

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Chỉnh nền trang thành màu trắng cho hộp nổi lên
      appBar: AppBar(
        title: Text(
          widget.vehicleToEdit != null ? "Cập nhật tin" : "Đăng tin bán xe",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5D3FD3), Color(0xFFC51162)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Consumer<VehicleProvider>(
        builder: (context, provider, child) {
          if (provider.categories.isEmpty && provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20), // Tăng lề 2 bên lên một chút
              children: [
                const Text(
                  "Thông tin cơ bản",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _titleController,
                  decoration: _customInputStyle("Tiêu đề bài đăng (VD: Honda Vision 2023)"),
                  validator: (val) => val!.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start, // Giúp các ô bằng nhau nếu có lỗi error text
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: _customInputStyle("Giá bán", suffix: "VNĐ"),
                        keyboardType: TextInputType.number,
                        validator: (val) => val!.isEmpty ? 'Nhập giá' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        items: provider.categories
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategory = val;
                            _selectedBrand = null; 
                          });
                        },
                        validator: (val) => val == null ? 'Chọn loại' : null,
                        decoration: _customInputStyle("Loại xe"),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Text(
                  "Thông số kỹ thuật",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                ),
                const SizedBox(height: 16),

                Consumer<VehicleProvider>(
                  builder: (context, provider, _) {
                    final filteredBrands = provider.getBrandsByCategory(_selectedCategory);
                    return DropdownButtonFormField<String>(
                      value: _selectedBrand,
                      items: _selectedCategory == null
                          ? []
                          : filteredBrands
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                      onChanged: (val) => setState(() => _selectedBrand = val),
                      validator: (val) => val == null ? 'Chọn hãng' : null,
                      decoration: _customInputStyle(
                        "Hãng xe", 
                        helper: _selectedCategory == null ? "Vui lòng chọn Loại xe trước" : null
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    );
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCondition,
                        items: _conditions
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCondition = val;
                            if (val == "Xe mới") _mileageController.text = "0"; 
                          });
                        },
                        validator: (val) => val == null ? 'Chọn tình trạng' : null,
                        decoration: _customInputStyle("Tình trạng"),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedOrigin,
                        items: _origins
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedOrigin = val),
                        validator: (val) => val == null ? 'Chọn xuất xứ' : null,
                        decoration: _customInputStyle("Xuất xứ"),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _mileageController,
                        enabled: _selectedCondition != "Xe mới", 
                        decoration: _customInputStyle("Số Km đã đi"),
                        keyboardType: TextInputType.number,
                        validator: (val) => val!.isEmpty ? 'Nhập số Km' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        decoration: _customInputStyle("Trọng lượng", suffix: "kg"),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _capacityController,
                  decoration: _customInputStyle("Dung tích động cơ (VD: 150cc, 2.0L)"),
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: _selectedColor,
                  items: provider.colors
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedColor = val),
                  validator: (val) => val == null ? 'Chọn màu xe' : null,
                  decoration: _customInputStyle("Màu ngoại thất"),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yearController,
                        decoration: _customInputStyle("Năm sản xuất"),
                        keyboardType: TextInputType.number,
                        validator: (val) => val!.isEmpty ? 'Nhập năm' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFuel,
                        items: provider.fuelTypes
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedFuel = val),
                        decoration: _customInputStyle("Nhiên liệu"),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  items: provider.locations
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedLocation = val),
                  validator: (val) => val == null ? 'Chọn khu vực' : null,
                  decoration: _customInputStyle("Khu vực / Thành phố"),
                  icon: const Icon(Icons.location_on, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  decoration: _customInputStyle("Số điện thoại liên hệ"),
                  keyboardType: TextInputType.phone,
                  validator: (val) => val!.isEmpty ? 'Nhập SĐT' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descController,
                  // Đổi thành maxLines lớn hơn để hộp mô tả to ra
                  maxLines: 4, 
                  decoration: _customInputStyle("Mô tả chi tiết về tình trạng xe..."),
                ),
                
                const SizedBox(height: 24),
                const Text(
                  "Hình ảnh xe ",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // NÚT THÊM ẢNH
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5D3FD3).withOpacity(0.05), // Đổi màu xám thành tím nhạt
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF5D3FD3).withOpacity(0.5), width: 1.5, style: BorderStyle.solid), // Đổi viền
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, color: Color(0xFF5D3FD3), size: 30),
                              SizedBox(height: 5),
                              Text("Thêm ảnh", style: TextStyle(fontSize: 12, color: Color(0xFF5D3FD3), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),

                      // HIỂN THỊ ẢNH CŨ 
                      ..._existingImages.asMap().entries.map((entry) {
                        int index = entry.key;
                        String imageUrl = entry.value;
                        
                        return Stack(
                          children: [
                            Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imageUrl, 
                                  fit: BoxFit.cover,
                                  loadingBuilder: (ctx, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                  },
                                  errorBuilder: (ctx, error, stack) => const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 5,
                              top: 5,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _existingImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),

                      // HIỂN THỊ ẢNH MỚI 
                      ..._selectedImages.asMap().entries.map((entry) {
                        int index = entry.key;
                        File imageFile = entry.value;

                        return Stack(
                          children: [
                            Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                image: DecorationImage(
                                  image: FileImage(imageFile), 
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 5,
                              top: 5,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC51162), // Nút hồng đậm mạnh mẽ
                          minimumSize: const Size.fromHeight(55),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // Bo góc nút
                          ),
                        ),
                        onPressed: () => _submitData(provider),
                        child: Text(
                          widget.vehicleToEdit != null ? "LƯU CẬP NHẬT" : "ĐĂNG TIN NGAY",
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submitData(VehicleProvider provider) async {
    if (_formKey.currentState!.validate()) {
      
      // 1. VALIDATE ẢNH
      if (_selectedImages.isEmpty && _existingImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng chọn ít nhất 1 ảnh xe!")),
        );
        return;
      }

      // 2. Lấy thông tin User
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi: Không tìm thấy thông tin người dùng!")),
        );
        return; 
      }

      // --- LOGIC TÊN SHOP (Giữ nguyên) ---
      String? finalStoreName;
      if (widget.isStorePost) {
        if (currentUser.storeName != null && currentUser.storeName!.isNotEmpty) {
          finalStoreName = currentUser.storeName;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lỗi: Bạn chưa thiết lập tên cửa hàng!")),
          );
          return;
        }
      } else {
        finalStoreName = null; 
      }
      // ------------------------------------

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đang xử lý dữ liệu...")),
      );

      // 3. LOGIC UPLOAD ẢNH
      List<String> finalImageUrls = [..._existingImages]; 

      if (_selectedImages.isNotEmpty) {
        List<String> newImageUrls = await provider.uploadImages(_selectedImages);
        if (newImageUrls.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lỗi tải ảnh mới, vui lòng thử lại!")),
          );
          return;
        }
        finalImageUrls.addAll(newImageUrls);
      }

      // 4. TẠO MODEL
      final newVehicle = VehicleModel(
        id: widget.vehicleToEdit?.id ?? '', 
        ownerId: currentUser.uid,
        storeName: finalStoreName, 
        title: _titleController.text,
        description: _descController.text,
        price: double.parse(_priceController.text),
        brand: _selectedBrand!,
        category: _selectedCategory!,
        year: int.parse(_yearController.text),
        mileage: int.tryParse(_mileageController.text) ?? 0,
        fuelType: _selectedFuel ?? 'Xăng',
        location: _selectedLocation!,
        color: _selectedColor!,
        images: finalImageUrls, 
        contactPhone: _phoneController.text,
        createdAt: widget.vehicleToEdit?.createdAt ?? DateTime.now(),
        status: 'pending', 
        condition: _selectedCondition!,
        origin: _selectedOrigin!,
        capacity: _capacityController.text,
        weight: int.tryParse(_weightController.text) ?? 0,
      );

      // 5. GỬI DỮ LIỆU
      bool success;
      
      if (widget.vehicleToEdit != null) {
        success = await provider.updateVehicle(newVehicle);
      } else {
        success = await provider.uploadVehicle(newVehicle);
      }
      
      if (success && mounted) {
        Navigator.pop(context);
        
        String actionText = widget.vehicleToEdit != null ? "Cập nhật" : "Đăng tin";
        String message = widget.isStorePost 
            ? "Đã $actionText dưới tên Cửa hàng!"
            : "Đã gửi yêu cầu $actionText!";
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }
    }
  }
}