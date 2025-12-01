import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isCreateAccount = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, authProvider, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // Logo and Title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: themeProvider.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: themeProvider.accentColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.coffee,
                            size: 50,
                            color: themeProvider.accentColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Cafeist',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.primaryTextColor,
                          ),
                        ),
                        Text(
                          'Your Personal Coffee Journey',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: themeProvider.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Welcome Text
                  Text(
                    _isCreateAccount ? 'Create Account' : 'Welcome Back',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isCreateAccount
                        ? 'Start tracking your coffee journey'
                        : 'Sign in to continue your journey',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: themeProvider.secondaryTextColor,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Display Name (only for create account)
                        if (_isCreateAccount) ...[
                          _buildTextField(
                            controller: _displayNameController,
                            label: 'Display Name',
                            hint: 'Enter your name',
                            icon: Icons.person,
                            themeProvider: themeProvider,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter your email',
                          icon: Icons.email_outlined,
                          themeProvider: themeProvider,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 20),

                        // Password Field
                        _buildPasswordTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter your password',
                          obscureText: _obscurePassword,
                          onToggle: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          themeProvider: themeProvider,
                        ),

                        const SizedBox(height: 20),

                        // Confirm Password (only for create account)
                        if (_isCreateAccount) ...[
                          _buildPasswordTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            hint: 'Confirm your password',
                            obscureText: _obscureConfirmPassword,
                            onToggle: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                            themeProvider: themeProvider,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Sign In Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeProvider.accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: authProvider.isLoading
                                ? const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  )
                                : Text(
                                    _isCreateAccount ? 'Create Account' : 'Sign In',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Forgot Password
                        if (!_isCreateAccount)
                          TextButton(
                            onPressed: _handleForgotPassword,
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.poppins(
                                color: themeProvider.accentColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: themeProvider.secondaryTextColor.withOpacity(0.3),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: GoogleFonts.poppins(
                                  color: themeProvider.secondaryTextColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: themeProvider.secondaryTextColor.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Google Sign In
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: authProvider.isLoading ? null : _handleGoogleSignIn,
                            icon: Icon(
                              Icons.g_translate,
                              color: themeProvider.primaryTextColor,
                            ),
                            label: Text(
                              'Continue with Google',
                              style: GoogleFonts.poppins(
                                color: themeProvider.primaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: themeProvider.secondaryTextColor.withOpacity(0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Toggle Create/Sign In
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isCreateAccount = !_isCreateAccount;
                              _formKey.currentState?.reset();
                              authProvider.clearError();
                            });
                          },
                          child: Text(
                            _isCreateAccount
                                ? 'Already have an account? Sign In'
                                : 'Don\'t have an account? Create one',
                            style: GoogleFonts.poppins(
                              color: themeProvider.accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        // Error Message
                        if (authProvider.error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    authProvider.error!,
                                    style: GoogleFonts.poppins(
                                      color: Colors.red.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeProvider themeProvider,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: themeProvider.primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(
            color: themeProvider.primaryTextColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: themeProvider.secondaryTextColor),
            hintStyle: GoogleFonts.poppins(
              color: themeProvider.secondaryTextColor,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: themeProvider.secondaryTextColor.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: themeProvider.accentColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your $label';
            }
            if (label == 'Email' && !value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggle,
    required ThemeProvider themeProvider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: themeProvider.primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: GoogleFonts.poppins(
            color: themeProvider.primaryTextColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(Icons.lock_outline, color: themeProvider.secondaryTextColor),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: themeProvider.secondaryTextColor,
              ),
              onPressed: onToggle,
            ),
            hintStyle: GoogleFonts.poppins(
              color: themeProvider.secondaryTextColor,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: themeProvider.secondaryTextColor.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: themeProvider.accentColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            if (label == 'Confirm Password' && value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    if (_isCreateAccount) {
      await authProvider.createEmailUser(
        _emailController.text.trim(),
        _passwordController.text,
        _displayNameController.text.trim(),
      );
    } else {
      await authProvider.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  void _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.signInWithGoogle();
  }

  void _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    await authProvider.resetPassword(_emailController.text.trim());

    if (authProvider.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to ${_emailController.text.trim()}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}