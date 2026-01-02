import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    // 1. GỌI HÀM TẢI DỮ LIỆU TỪ FIREBASE KHI MỞ MÀN HÌNH
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VehicleProvider>(context, listen: false).fetchAppConfig();
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
                  maxLines: 3,
                ),

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
      final newVehicle = VehicleModel(
        id: '',
        ownerId: FirebaseAuth.instance.currentUser!.uid,
        title: _titleController.text,
        description: _descController.text,
        price: double.parse(_priceController.text),
        brand: _selectedBrand!, // Dùng biến đã chọn từ Dropdown
        category: _selectedCategory!, // Dùng biến đã chọn từ Dropdown
        year: int.parse(_yearController.text),
        mileage: int.tryParse(_mileageController.text) ?? 0,
        fuelType: _selectedFuel ?? 'Xăng',
        location: _selectedLocation!, // Dùng biến đã chọn từ Dropdown
        images: ["https://picsum.photos/200"],
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
