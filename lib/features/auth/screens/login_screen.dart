import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart'; // ← icon package
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart'; // ← tambah
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/neo_button.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordNode = FocusNode();

  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);
    await ref.read(authControllerProvider.notifier).login(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    ref.listen<AsyncValue<void>>(authControllerProvider, (_, state) {
      if (state.hasError) {
        setState(() => _errorMessage = AuthService.parseError(state.error!));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                // ── Header ──────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    border: Border.all(color: AppColors.black, width: 2.5),
                    boxShadow: const [AppColors.neoShadow],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.books(PhosphorIconsStyle.bold),
                        size: 40,
                        color: AppColors.black,
                      ),
                      const SizedBox(height: 10),
                      Text('DonasiBuku', style: AppTextStyles.display),
                      Text(
                        'Platform Hibah Buku Bekas',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Text('Masuk', style: AppTextStyles.heading1),
                const SizedBox(height: 4),
                Text(
                  'Selamat datang kembali.',
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),

                // ── Error ────────────────────────────────────────────────
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1), // ← fixed
                      border: Border.all(color: AppColors.danger, width: 2),
                    ),
                    child: Row(
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.warningCircle(),
                          size: 16,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Form ─────────────────────────────────────────────────
                NeoTextField(
                  label: 'Email',
                  controller: _emailCtrl,
                  hint: 'nama@email.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                  onFieldSubmitted: (_) => _passwordNode.requestFocus(),
                ),
                const SizedBox(height: 16),

                NeoTextField(
                  label: 'Password',
                  controller: _passwordCtrl,
                  hint: '••••••••',
                  obscureText: _obscurePassword,
                  focusNode: _passwordNode,
                  textInputAction: TextInputAction.done,
                  validator: Validators.password,
                  onFieldSubmitted: (_) => _submit(),
                  suffixIcon: IconButton(
                    icon: PhosphorIcon(
                      _obscurePassword
                          ? PhosphorIcons.eyeSlash()
                          : PhosphorIcons.eye(),
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Submit ───────────────────────────────────────────────
                NeoButton(
                  label: 'Masuk',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _submit,
                ),
                const SizedBox(height: 16),

                // ── Register link ─────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/register'),
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textMuted),
                        children: [
                          const TextSpan(text: 'Belum punya akun? '),
                          TextSpan(
                            text: 'Daftar sekarang',
                            style: AppTextStyles.bodyBold.copyWith(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
