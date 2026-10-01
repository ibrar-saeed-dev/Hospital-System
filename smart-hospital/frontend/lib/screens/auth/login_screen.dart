import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.login(
        _emailController.text,
        _passwordController.text,
      );
    }
  }

  void _fillDemo(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
    });
    _handleLogin();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: isWide ? AppColors.black : AppColors.surface,
      body: isWide ? _buildDesktopLayout(auth) : _buildMobileLayout(auth),
    );
  }

  Widget _buildDesktopLayout(AuthProvider auth) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Row(
          children: [
            // Left Half - Dark Emergency-Tech Hero
            Expanded(
              flex: 5,
              child: Container(
                color: AppColors.black,
                height: double.infinity,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Brand Logo
                        const AppLogo(
                          size: 38,
                          showText: true,
                          isDark: true,
                          subtitle: 'EMERGENCY DISPATCH & BED SYSTEM',
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        // Large Bold Headline
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Right bed.\nRight hospital.\n',
                                style: AppTypography.display(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                  height: 1.15,
                                ),
                              ),
                              TextSpan(
                                text: 'Right now.',
                                style: AppTypography.display(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryRed,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        Text(
                          'Real-time bed allocation, emergency triage dispatch, and inter-hospital patient transfers powered by instant telemetry.',
                          style: AppTypography.bodyLarge(
                            color: const Color(0xFFA1A1AA),
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        // 3 Feature Points with Red Icons
                        _buildFeatureItem(
                          icon: Icons.sensors_rounded,
                          title: 'Live Capacity',
                          description:
                              'Real-time telemetry on ICU, HDU, oxygen & ventilator availability across regional facilities.',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFeatureItem(
                          icon: Icons.hub_rounded,
                          title: 'Smart Matching',
                          description:
                              'Algorithmic clinical triage matching patients to the fastest available facility with required care.',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFeatureItem(
                          icon: Icons.speed_rounded,
                          title: 'Instant Referral',
                          description:
                              'Zero-friction digital dispatch with automated bed reservations and ambulance routing.',
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        // Footer Protocol Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16161F),
                            borderRadius: AppRadius.radiusPill,
                            border: Border.all(color: const Color(0xFF272733)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'EMERGENCY PROTOCOL ACTIVE • 24/7 REGIONAL NETWORK',
                                  style: AppTypography.label(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFA1A1AA),
                                    letterSpacing: 0.6,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Right Half - White Form
            Expanded(
              flex: 5,
              child: Container(
                color: AppColors.surface,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _buildLoginForm(auth),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(AuthProvider auth) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Black Header Band
              Container(
                width: double.infinity,
                color: AppColors.black,
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppLogo(
                      size: 32,
                      showText: true,
                      isDark: true,
                      subtitle: 'DISPATCH & BED TRIAGE',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Right bed.\nRight hospital. Right now.',
                      style: AppTypography.display(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Instant healthcare bed allocation & emergency triage.',
                      style: AppTypography.bodySmall(
                        color: const Color(0xFFA1A1AA),
                      ),
                    ),
                  ],
                ),
              ),

              // White Form Body
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _buildLoginForm(auth),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withValues(alpha: 0.15),
            borderRadius: AppRadius.radiusMd,
            border: Border.all(
              color: AppColors.primaryRed.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: AppColors.primaryRed,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.headingSmall(color: AppColors.white),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.bodySmall(
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(AuthProvider auth) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sign In',
            style: AppTypography.display(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enter your credentials to access live bed dispatch.',
            style: AppTypography.bodyMedium(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Error Alert Box
          if (auth.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.redTint,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.primaryRed, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      auth.errorMessage!,
                      style: AppTypography.bodySmall(color: AppColors.redDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Email Field
          Text(
            'Email Address',
            style: AppTypography.label(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: AppTypography.bodyMedium(),
            decoration: const InputDecoration(
              hintText: 'name@hospital.org',
              prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your email address';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Password Field
          Text(
            'Password',
            style: AppTypography.label(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: AppTypography.bodyMedium(),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Submit Button
          AppButton(
            text: 'Sign In to Portal',
            isLoading: auth.isLoading,
            onPressed: _handleLogin,
            height: 52,
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Quick Demo Roles Section
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'QUICK DEMO ACCESS',
                  style: AppTypography.label(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4 Role Chips
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2.6,
            children: [
              _buildRoleCard(
                label: 'Patient',
                roleDesc: 'Find & Request Beds',
                icon: Icons.person_rounded,
                onTap: () => _fillDemo('patient@smarthospital.org', 'demo123'),
              ),
              _buildRoleCard(
                label: 'Coordinator',
                roleDesc: 'Emergency Triage',
                icon: Icons.support_agent_rounded,
                onTap: () => _fillDemo('coordinator@smarthospital.org', 'demo123'),
              ),
              _buildRoleCard(
                label: 'Hospital Staff',
                roleDesc: 'Manage Capacity',
                icon: Icons.local_hospital_rounded,
                onTap: () => _fillDemo('staff.qasimabad@smarthospital.org', 'demo123'),
              ),
              _buildRoleCard(
                label: 'Admin',
                roleDesc: 'System Overview',
                icon: Icons.admin_panel_settings_rounded,
                onTap: () => _fillDemo('admin@smarthospital.org', 'demo123'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String label,
    required String roleDesc,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadius.radiusSm,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.headingSmall(
                    fontSize: 12,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  roleDesc,
                  style: AppTypography.label(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
