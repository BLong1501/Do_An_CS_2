import 'package:flutter/material.dart';
import 'package:my_app/views/admin/tabs/vehicle_approval_tab.dart';
import 'package:my_app/views/admin/tabs/seller_approval_tab.dart';
import 'package:my_app/views/admin/tabs/report_tab.dart';

class RequestManagementScreen extends StatelessWidget {
  const RequestManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sử dụng DefaultTabController để tạo Tab Bar con ở phía trên
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Thanh Tab Bar nằm ngay dưới AppBar chính
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Colors.blueGrey,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orange,
              tabs: [
                Tab(icon: Icon(Icons.directions_car), text: "Duyệt Xe"),
                Tab(icon: Icon(Icons.verified_user), text: "Seller"),
                Tab(icon: Icon(Icons.report_problem), text: "Tố cáo"),
              ],
            ),
          ),
          // Nội dung của từng Tab
          const Expanded(
            child: TabBarView(
              children: [
                VehicleApprovalTab(),
                SellerApprovalTab(),
                ReportTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}