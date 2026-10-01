import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_hospital/config/app_theme.dart';
import 'package:smart_hospital/providers/auth_provider.dart';
import 'package:smart_hospital/screens/auth/login_screen.dart';
import 'package:smart_hospital/widgets/widgets.dart';

void main() {
  testWidgets('AppTheme tokens and typography load correctly', (tester) async {
    expect(AppColors.primaryRed, const Color(0xFFE11D2E));
    expect(AppColors.black, const Color(0xFF0B0B0F));
    expect(AppColors.ink, const Color(0xFF16161D));
    expect(AppColors.border, const Color(0xFFE5E7EB));
    expect(AppColors.green, const Color(0xFF16A34A));
    expect(AppColors.amber, const Color(0xFFF59E0B));
  });

  testWidgets('Reusable widgets render without error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const AppLogo(size: 36, showText: true),
                AppButton(
                  text: 'Primary Action',
                  onPressed: () {},
                ),
                AppButton(
                  text: 'Secondary Action',
                  variant: AppButtonVariant.secondary,
                  onPressed: () {},
                ),
                const AppCard(
                  child: Text('Card Content'),
                ),
                const StatTile(
                  label: 'Available ICU Beds',
                  value: '24',
                  icon: Icons.bed_rounded,
                ),
                const StatusChip(status: 'Accepted'),
                const StatusChip(status: 'Pending'),
                const StatusChip(status: 'Rejected'),
                const StatusChip(status: 'Expired'),
                const SectionHeader(
                  title: 'Overview',
                  subtitle: 'System performance summary',
                ),
                const EmptyState(
                  icon: Icons.inbox_rounded,
                  title: 'No Active Requests',
                  message: 'When new referrals arrive they will appear here.',
                ),
                const LoadingSkeleton(width: 100, height: 20),
                const LoadingSkeleton.card(height: 80),
                const MatchRing(score: 85),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('SMART HOSPITAL'), findsOneWidget);
    expect(find.text('Primary Action'), findsOneWidget);
    expect(find.text('Secondary Action'), findsOneWidget);
    expect(find.text('Card Content'), findsOneWidget);
    expect(find.text('Available ICU Beds'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('ACCEPTED'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('REJECTED'), findsOneWidget);
    expect(find.text('EXPIRED'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('No Active Requests'), findsOneWidget);
    expect(find.text('85%'), findsOneWidget);
  });

  testWidgets('LoginScreen renders desktop split layout with features and demo roles', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Live Capacity'), findsOneWidget);
    expect(find.text('Smart Matching'), findsOneWidget);
    expect(find.text('Instant Referral'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Patient'), findsOneWidget);
    expect(find.text('Coordinator'), findsOneWidget);
    expect(find.text('Hospital Staff'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });

  testWidgets('LoginScreen renders mobile layout with header band and role chips without overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Right bed.\nRight hospital. Right now.'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Patient'), findsOneWidget);
    expect(find.text('Coordinator'), findsOneWidget);
    expect(find.text('Hospital Staff'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });

  testWidgets('AppShell renders sidebar on desktop width', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: AppShell(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            items: const [
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
            ],
            title: 'Hospital Capacity',
            subtitle: 'Manage and broadcast available beds',
            body: const Center(child: Text('Main Body Content')),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('SMART HOSPITAL'), findsOneWidget);
    expect(find.text('NAVIGATION'), findsOneWidget);
    expect(find.text('Capacity'), findsOneWidget);
    expect(find.text('Requests'), findsOneWidget);
    expect(find.text('Updated just now'), findsOneWidget);
    expect(find.text('Main Body Content'), findsOneWidget);
  });

  testWidgets('AppShell renders bottom navigation on mobile width without overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: AppShell(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            items: const [
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
            ],
            title: 'Hospital Capacity',
            body: const Center(child: Text('Main Body Content')),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Hospital Capacity'), findsOneWidget);
    expect(find.text('Main Body Content'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
