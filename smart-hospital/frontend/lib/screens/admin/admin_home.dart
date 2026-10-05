import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/admin_service.dart';
import '../../widgets/widgets.dart';
import 'system_analytics_tab.dart';
import 'admin_hospitals_tab.dart';
import 'admin_map_tab.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final analyticsService = AnalyticsService(auth.apiClient);
    final adminService = AdminService(auth.apiClient);

    final List<Widget> tabs = [
      SystemAnalyticsTab(analyticsService: analyticsService),
      AdminHospitalsTab(adminService: adminService),
      AdminMapTab(adminService: adminService),
    ];

    const navItems = [
      AppShellNavItem(
        icon: Icons.analytics_outlined,
        selectedIcon: Icons.analytics_rounded,
        label: 'System Analytics',
      ),
      AppShellNavItem(
        icon: Icons.domain_outlined,
        selectedIcon: Icons.domain_rounded,
        label: 'Hospitals',
      ),
      AppShellNavItem(
        icon: Icons.map_outlined,
        selectedIcon: Icons.map_rounded,
        label: 'Live Network Map',
      ),
    ];

    return AppShell(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (idx) {
        setState(() => _selectedIndex = idx);
      },
      items: navItems,
      title: _getTabTitle(_selectedIndex),
      subtitle: _getTabSubtitle(_selectedIndex),
      body: IndexedStack(
        index: _selectedIndex,
        children: tabs,
      ),
    );
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'System Analytics';
      case 1:
        return 'Hospital Management';
      case 2:
        return 'Regional Hospital Map';
      default:
        return 'System Administration';
    }
  }

  String _getTabSubtitle(int index) {
    switch (index) {
      case 0:
        return 'Regional telemetry, bed utilization, and emergency triage performance';
      case 1:
        return 'Configure facilities, departments, and verification status';
      case 2:
        return 'Real-time geographic occupancy map across all network facilities';
      default:
        return 'System Administration Portal';
    }
  }
}
