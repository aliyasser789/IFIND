import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

const _kPrimary    = Color(0xFF135BEC);
const _kBackground = Color(0xFF101622);
const _kSlate300   = Color(0xFFCBD5E1);
const _kSlate500   = Color(0xFF64748B);
const _kErrorText  = Color(0xFFFFB4AB);

// ─────────────────────────────────────────────────────────────────────────────
// ChangePasswordScreen
// ─────────────────────────────────────────────────────────────────────────────
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentCtrl  = TextEditingController();
  final _newCtrl      = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _saving         = false;
  String? _matchError;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final current = _currentCtrl.text;
    final newPass  = _newCtrl.text;
    final confirm  = _confirmCtrl.text;

    // Inline match validation
    if (newPass != confirm) {
      setState(() => _matchError = 'Passwords do not match.');
      return;
    }
    setState(() => _matchError = null);

    if (current.isEmpty || newPass.isEmpty) return;

    setState(() => _saving = true);
    final result = await ApiService().changePassword(
      currentPassword: current,
      newPassword:     newPass,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              (result['message'] as String?) ?? 'Password changed.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              (result['message'] as String?) ?? 'Password change failed.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: _buildAppBar(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF101622), Color(0xFF1A1435)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Password
                _fieldLabel('Current Password'),
                const SizedBox(height: 8),
                _PasswordField(
                  controller: _currentCtrl,
                  hint:       'Enter current password',
                  obscure:    _obscureCurrent,
                  onToggle:   () => setState(
                      () => _obscureCurrent = !_obscureCurrent),
                ),
                const SizedBox(height: 20),

                // New Password
                _fieldLabel('New Password'),
                const SizedBox(height: 8),
                _PasswordField(
                  controller: _newCtrl,
                  hint:       'Enter new password',
                  obscure:    _obscureNew,
                  onToggle:   () =>
                      setState(() => _obscureNew = !_obscureNew),
                ),
                const SizedBox(height: 20),

                // Confirm New Password
                _fieldLabel('Confirm New Password'),
                const SizedBox(height: 8),
                _PasswordField(
                  controller: _confirmCtrl,
                  hint:       'Confirm new password',
                  obscure:    _obscureConfirm,
                  onToggle:   () => setState(
                      () => _obscureConfirm = !_obscureConfirm),
                  hasError: _matchError != null,
                ),
                if (_matchError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _matchError!,
                    style: GoogleFonts.manrope(
                      color: _kErrorText,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          _kPrimary.withValues(alpha: 0.50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Save',
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) => Text(
        label,
        style: GoogleFonts.manrope(
          color: _kSlate300,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Change Password',
        style: GoogleFonts.manrope(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
    );
  }
}

// ─── Password field with eye toggle ──────────────────────────────────────────
class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    this.hasError = false,
  });

  final TextEditingController controller;
  final String                hint;
  final bool                  obscure;
  final VoidCallback          onToggle;
  final bool                  hasError;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? const Color(0xFFFFB4AB).withValues(alpha: 0.60)
              : Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller:  controller,
              obscureText: obscure,
              style: GoogleFonts.manrope(color: Colors.white, fontSize: 15),
              cursorColor: _kPrimary,
              decoration: InputDecoration(
                hintText:       hint,
                hintStyle:
                    GoogleFonts.manrope(color: _kSlate500, fontSize: 15),
                border:         InputBorder.none,
                enabledBorder:  InputBorder.none,
                focusedBorder:  InputBorder.none,
                isDense:        true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _kSlate500,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
