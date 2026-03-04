import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import thư viện biểu đồ
import 'package:my_app/views/admin/tabs/report_tab.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  // Các biến lưu trữ số liệu tổng quan
  int _totalUsers = 0;
  int _totalPosts = 0;
  int _pendingPosts = 0;
  int _reports = 0;
  int _bannedUsers = 0;
  bool _isLoadingTotal = true;

  // --- BIẾN CHO BIỂU ĐỒ ---
  String _selectedChartType = 'posts'; // Mặc định hiển thị biểu đồ Tin đăng
  bool _isChartLoading = true;
  Map<int, int> _monthlyData = {}; // Chứa dữ liệu: {Tháng: Số lượng}

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  // Gộp chung hàm để refresh kéo xuống
  Future<void> _fetchAllData() async {
    await Future.wait([
      _fetchTotalStats(),
      _fetchChartData(),
    ]);
  }

  // 1. Tải số liệu tổng quan (Giữ nguyên logic của bạn, đã sửa lỗi count)
  Future<void> _fetchTotalStats() async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('users').count().get(),
        FirebaseFirestore.instance.collection('vehicles').count().get(),
        FirebaseFirestore.instance.collection('vehicles').where('status', isEqualTo: 'pending').count().get(),
        FirebaseFirestore.instance.collection('reports').count().get(),
        FirebaseFirestore.instance.collection('users').where('isBanned', isEqualTo: true).count().get(),
      ]);

      if (mounted) {
        setState(() {
          _totalUsers = results[0].count ?? 0;
          _totalPosts = results[1].count ?? 0;
          _pendingPosts = results[2].count ?? 0;
          _reports = results[3].count ?? 0;
          _bannedUsers = results[4].count ?? 0;
          _isLoadingTotal = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải tổng quan: $e");
      if (mounted) setState(() => _isLoadingTotal = false);
    }
  }

  // 2. Lấy dữ liệu cho biểu đồ theo tháng (Trong năm hiện tại)
  Future<void> _fetchChartData() async {
    setState(() => _isChartLoading = true);
    
    // Khởi tạo mảng 12 tháng với giá trị 0
    Map<int, int> tempData = {for (var i = 1; i <= 12; i++) i: 0}; 

    try {
      int currentYear = DateTime.now().year;
      DateTime startOfYear = DateTime(currentYear, 1, 1);
      DateTime endOfYear = DateTime(currentYear, 12, 31, 23, 59, 59);

      QuerySnapshot snapshot;

      // Lấy data dựa trên lựa chọn Dropdown
      if (_selectedChartType == 'posts') {
        snapshot = await FirebaseFirestore.instance
            .collection('vehicles')
            .where('createdAt', isGreaterThanOrEqualTo: startOfYear)
            .where('createdAt', isLessThanOrEqualTo: endOfYear)
            .get();
      } else if (_selectedChartType == 'reports') {
        snapshot = await FirebaseFirestore.instance
            .collection('reports')
            .where('createdAt', isGreaterThanOrEqualTo: startOfYear)
            .where('createdAt', isLessThanOrEqualTo: endOfYear)
            .get();
      } else {
        // Tài khoản bị khóa (Giả sử bạn có trường bannedAt hoặc dùng createdAt tạm)
        snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('isBanned', isEqualTo: true)
            // Nếu bạn có trường bannedAt thì thay chữ createdAt ở dưới thành bannedAt nhé
            .where('createdAt', isGreaterThanOrEqualTo: startOfYear)
            .where('createdAt', isLessThanOrEqualTo: endOfYear)
            .get();
      }

      // Phân loại đếm vào từng tháng
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        Timestamp? ts = data['createdAt']; // Đổi thành bannedAt nếu tra tài khoản bị khóa
        if (ts != null) {
          int month = ts.toDate().month;
          tempData[month] = (tempData[month] ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _monthlyData = tempData;
          _isChartLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải biểu đồ: $e");
      if (mounted) setState(() => _isChartLoading = false);
    }
  }

  // --- WIDGET VẼ BIỂU ĐỒ (BAR CHART) ---
  Widget _buildChart() {
    if (_isChartLoading) {
      return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
    }

    // Chuyển đổi dữ liệu Map thành định dạng của fl_chart
    List<BarChartGroupData> barGroups = [];
    double maxY = 0;

    _monthlyData.forEach((month, count) {
      if (count > maxY) maxY = count.toDouble();
      
      barGroups.add(
        BarChartGroupData(
          x: month,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: _getChartColor(), // Đổi màu cột theo loại biểu đồ
              width: 16,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            )
          ],
        ),
      );
    });

    if (maxY == 0) maxY = 5; // Cột Y tối thiểu nếu chưa có data

    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Năm ${DateTime.now().year}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              
              // SỬA THÀNH POPUP MENU BUTTON
              PopupMenuButton<String>(
                initialValue: _selectedChartType,
                // Ép menu thả thẳng xuống dưới, không bị nhảy lên nhảy xuống
                position: PopupMenuPosition.under, 
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onSelected: (val) {
                  setState(() => _selectedChartType = val);
                  _fetchChartData(); // Tải lại biểu đồ
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'posts',
                    child: Text(
                      "Tin đăng mới",
                      style: TextStyle(
                        // Nếu đang chọn thì in đậm và đổi màu xanh
                        fontWeight: _selectedChartType == 'posts' ? FontWeight.bold : FontWeight.normal,
                        color: _selectedChartType == 'posts' ? Colors.blue : Colors.black87,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'reports',
                    child: Text(
                      "Lượt tố cáo",
                      style: TextStyle(
                        fontWeight: _selectedChartType == 'reports' ? FontWeight.bold : FontWeight.normal,
                        color: _selectedChartType == 'reports' ? Colors.blue : Colors.black87,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'banned',
                    child: Text(
                      "TK bị khóa",
                      style: TextStyle(
                        fontWeight: _selectedChartType == 'banned' ? FontWeight.bold : FontWeight.normal,
                        color: _selectedChartType == 'banned' ? Colors.blue : Colors.black87,
                      ),
                    ),
                  ),
                ],
                // Giao diện của nút bấm hiển thị trên màn hình
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedChartType == 'posts' 
                          ? "Tin đăng mới" 
                          : _selectedChartType == 'reports' 
                              ? "Lượt tố cáo" 
                              : "TK bị khóa",
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.blue),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY + (maxY * 0.2), // Thêm 20% khoảng trống phía trên
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        "${rod.toY.toInt()}",
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('T${value.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0) return const SizedBox.shrink(); // Chỉ hiện số nguyên
                        return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200], strokeWidth: 1),
                ),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Chọn màu cột theo loại
  Color _getChartColor() {
    switch (_selectedChartType) {
      case 'reports': return Colors.red;
      case 'banned': return Colors.grey;
      default: return Colors.green;
    }
  }

  // --- HÀM WIDGET THẺ CHỈ SỐ (Giữ nguyên của bạn) ---
  Widget _buildStatCard({required String title, required int count, required IconData icon, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                if (onTap != null) Icon(Icons.arrow_forward, size: 16, color: Colors.grey[400]),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text("$count", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
                ),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- GIAO DIỆN CHÍNH ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Chỉnh nền xám xíu cho nổi Box
      body: _isLoadingTotal
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAllData, // Gọi cả 2 hàm
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. BIỂU ĐỒ (MỚI THÊM)
                    const Text("Thống kê năm nay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildChart(),

                    const SizedBox(height: 25),

                    // 2. HOẠT ĐỘNG CẦN XỬ LÝ
                    const Text("Hoạt động cần xử lý", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: "Chờ duyệt", count: _pendingPosts, icon: Icons.hourglass_top, color: Colors.orange,
                            onTap: () {
                              // Chuyển tab Duyệt xe nếu cần
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            title: "Đơn tố cáo", count: _reports, icon: Icons.report_problem, color: Colors.red,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportTab()));
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // 3. TỔNG QUAN HỆ THỐNG
                    const Text("Dữ liệu hệ thống", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.4,
                      children: [
                        _buildStatCard(title: "Thành viên", count: _totalUsers, icon: Icons.group, color: Colors.blue),
                        _buildStatCard(title: "Tin đăng", count: _totalPosts, icon: Icons.car_rental, color: Colors.green),
                        _buildStatCard(title: "Bị khóa", count: _bannedUsers, icon: Icons.block, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 