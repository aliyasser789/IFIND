import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/user_profile_provider.dart';
import '../services/api_service.dart';

const _kPrimary    = Color(0xFF135BEC);
const _kBackground = Color(0xFF101622);
const _kSlate300   = Color(0xFFCBD5E1);
const _kSlate400   = Color(0xFF94A3B8);
const _kSlate500   = Color(0xFF64748B);

// ─────────────────────────────────────────────────────────────────────────────
// ChangeDisplayNameScreen
// ─────────────────────────────────────────────────────────────────────────────
class ChangeDisplayNameScreen extends StatefulWidget {
  const ChangeDisplayNameScreen({super.key});

  @override
  State<ChangeDisplayNameScreen> createState() =>
      _ChangeDisplayNameScreenState();
}

class _ChangeDisplayNameScreenState extends State<ChangeDisplayNameScreen> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving  = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final result = await ApiService().getUserProfile();
    if (!mounted) return;
    setState(() {
      _controller.text = (result['full_name'] as String?) ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    final newName = _controller.text.trim();
    if (newName.isEmpty) return;
    setState(() => _saving = true);
    final result = await ApiService().updateUserProfile(fullName: newName);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result['success'] == true) {
      Provider.of<UserProfileProvider>(context, listen: false).updateName(newName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              (result['message'] as String?) ?? 'Display name updated.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result['message'] as String?) ?? 'Update failed.'),
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
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: _kPrimary, strokeWidth: 2.5,
                ),
              )
            : SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label
                      Text(
                        'Display Name',
                        style: GoogleFonts.manrope(
                          color: _kSlate300,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Input field
                      _DarkTextField(
                        controller: _controller,
                        hint: 'Enter new display name',
                      ),
                      const SizedBox(height: 8),

                      // Helper text
                      Text(
                        'This is how you will appear to other users in the app.',
                        style: GoogleFonts.manrope(
                          color: _kSlate400,
                          fontSize: 12,
                        ),
                      ),
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
        'Change Display Name',
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

// ─── Dark text field ──────────────────────────────────────────────────────────
class _DarkTextField extends StatelessWidget {
  const _DarkTextField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String                hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        style: GoogleFonts.manrope(color: Colors.white, fontSize: 15),
        cursorColor: _kPrimary,
        decoration: InputDecoration(
          hintText:       hint,
          hintStyle:      GoogleFonts.manrope(color: _kSlate500, fontSize: 15),
          border:         InputBorder.none,
          enabledBorder:  InputBorder.none,
          focusedBorder:  InputBorder.none,
          isDense:        true,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
