import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/patient/patient_home.dart';
import 'screens/staff/staff_home.dart';
import 'screens/admin/admin_home.dart';
import 'widgets/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartHospitalApp());
}

class SmartHospitalApp extends StatelessWidget {
  const SmartHospitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Smart Hospital Bed System',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: _buildHome(auth),
          );
        },
      ),
    );
  }

  Widget _buildHome(AuthProvider auth) {
    if (!auth.isInitialized || auth.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 48, showText: false),
              const SizedBox(height: AppSpacing.xl),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'SMART HOSPITAL BED SYSTEM',
                style: AppTypography.label(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Initializing real-time telemetry...',
                style: AppTypography.bodySmall(
                  color: const Color(0xFF71717A),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    switch (auth.role?.toLowerCase()) {
      case 'admin':
        return const AdminHome();
      case 'staff':
        return const StaffHome();
      case 'patient':
      case 'coordinator':
      default:
        return const PatientHome();
    }
  }
}
