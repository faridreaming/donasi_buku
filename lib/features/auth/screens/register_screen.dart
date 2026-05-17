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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _emailNode = FocusNode();
  final _passwordNode = FocusNode();
  final _confirmNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _emailNode.dispose();
    _passwordNode.dispose();
    _confirmNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);
    await ref.read(authControllerProvider.notifier).register(
          name: _nameCtrl.text,
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

                // ── Header ───────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    border: Border.all(color: AppColors.black, width: 2.5),
                    boxShadow: const [AppColors.neoShadow],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.userPlus(PhosphorIconsStyle.bold),
                        size: 40,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Buat Akun',
                        style: AppTextStyles.display.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Bergabung dan mulai berdonasi buku.',
                        style: AppTextStyles.body.copyWith(
                          color:
                              AppColors.white.withValues(alpha: 0.7), // ← fixed
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Error ─────────────────────────────────────────────────
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
                  label: 'Nama Lengkap',
                  controller: _nameCtrl,
                  hint: 'Nama kamu',
                  textInputAction: TextInputAction.next,
                  validator: Validators.name,
                  onFieldSubmitted: (_) => _emailNode.requestFocus(),
                ),
                const SizedBox(height: 16),

                NeoTextField(
                  label: 'Email',
                  controller: _emailCtrl,
                  hint: 'nama@email.com',
                  keyboardType: TextInputType.emailAddress,
                  focusNode: _emailNode,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                  onFieldSubmitted: (_) => _passwordNode.requestFocus(),
                ),
                const SizedBox(height: 16),

                NeoTextField(
                  label: 'Password',
                  controller: _passwordCtrl,
                  hint: 'Minimal 8 karakter',
                  obscureText: _obscurePassword,
                  focusNode: _passwordNode,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                  onFieldSubmitted: (_) => _confirmNode.requestFocus(),
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
                const SizedBox(height: 16),

                NeoTextField(
                  label: 'Konfirmasi Password',
                  controller: _confirmCtrl,
                  hint: 'Ulangi password',
                  obscureText: _obscureConfirm,
                  focusNode: _confirmNode,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      Validators.confirmPassword(v, _passwordCtrl.text),
                  onFieldSubmitted: (_) => _submit(),
                  suffixIcon: IconButton(
                    icon: PhosphorIcon(
                      _obscureConfirm
                          ? PhosphorIcons.eyeSlash()
                          : PhosphorIcons.eye(),
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Submit ───────────────────────────────────────────────
                NeoButton(
                  label: 'Daftar',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _submit,
                ),
                const SizedBox(height: 16),

                // ── Login link ────────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/login'),
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textMuted),
                        children: [
                          const TextSpan(text: 'Sudah punya akun? '),
                          TextSpan(
                            text: 'Masuk',
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
