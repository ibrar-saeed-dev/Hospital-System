import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/staff_service.dart';
import '../../services/analytics_service.dart';
import '../../widgets/widgets.dart';
import 'capacity_tab.dart';
import 'requests_tab.dart';
import 'staff_dashboard_tab.dart';

class StaffHome extends StatefulWidget {
  const StaffHome({super.key});

  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<StaffHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final staffService = StaffService(auth.apiClient);
    final analyticsService = AnalyticsService(auth.apiClient);

    final List<Widget> tabs = [
      CapacityTab(staffService: staffService),
      RequestsTab(staffService: staffService),
      StaffDashboardTab(analyticsService: analyticsService),
    ];

    const navItems = [
      AppShellNavItem(
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2_rounded,
        label: 'Capacity',
      ),
      AppShellNavItem(
        icon: Icons.move_to_inbox_outlined,
        selectedIcon: Icons.move_to_inbox_rounded,
        label: 'Requests',
      ),
      AppShellNavItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
        label: 'Dashboard',
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
        return 'Hospital Capacity';
      case 1:
        return 'Referral Requests';
      case 2:
        return 'Staff Analytics';
      default:
        return 'Hospital Staff';
    }
  }

  String _getTabSubtitle(int index) {
    switch (index) {
      case 0:
        return 'Manage and broadcast available beds and equipment';
      case 1:
        return 'Review and process inbound patient referral requests';
      case 2:
        return 'Occupancy metrics, turnaround times, and flow analysis';
      default:
        return 'Hospital Operations Portal';
    }
  }
}
