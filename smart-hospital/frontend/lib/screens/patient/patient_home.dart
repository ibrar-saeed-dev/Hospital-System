import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/patient_service.dart';
import '../../widgets/widgets.dart';
import 'find_hospital_tab.dart';
import 'my_requests_tab.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  int _currentIndex = 0;
  late PatientService _patientService;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _patientService = PatientService(apiClient: auth.apiClient);
  }

  void _switchToRequestsTab() {
    setState(() {
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isCoordinator = auth.role?.toLowerCase() == 'coordinator';
    final findTabLabel = isCoordinator ? 'Compare Hospitals' : 'Find Hospital';

    final List<Widget> tabs = [
      FindHospitalTab(
        patientService: _patientService,
        onRequestCreated: _switchToRequestsTab,
      ),
      MyRequestsTab(
        patientService: _patientService,
      ),
    ];

    final navItems = [
      AppShellNavItem(
        icon: Icons.local_hospital_outlined,
        selectedIcon: Icons.local_hospital_rounded,
        label: findTabLabel,
      ),
      const AppShellNavItem(
        icon: Icons.assignment_outlined,
        selectedIcon: Icons.assignment_rounded,
        label: 'My Requests',
      ),
    ];

    final pageTitle = _currentIndex == 0
        ? (isCoordinator ? 'Emergency Dispatch' : 'Find Hospital Bed')
        : 'Referral Requests';

    final pageSubtitle = _currentIndex == 0
        ? 'Real-time bed availability & clinical triage matching'
        : 'Track active hospital admission requests & status';

    return AppShell(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: navItems,
      title: pageTitle,
      subtitle: pageSubtitle,
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
    );
  }
}
