import 'package:flutter/material.dart';
import 'bill_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  @override
  void initState() {
    super.initState();

    _loadSavedPassword();

    _usernameController.addListener(() {
      setState(() {
        _errorMessage = '';
      });
    });

    _passwordController.addListener(() {
      setState(() {
        _errorMessage = '';
      });
    });
  }

  String _savedPassword = '1234';

  Future<void> _loadSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPassword = prefs.getString('password') ?? '1234';
    });
  }

  Future<void> _saveNewPassword(String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', newPassword);

    setState(() {
      _savedPassword = newPassword;
      _passwordController.text = newPassword;
    });
  }

  void _showForgotPasswordDialog() {
    FocusScope.of(context).unfocus();

    final keyController = TextEditingController();
    final usernameController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final FocusNode keyFocus = FocusNode();

    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          keyFocus.requestFocus();
        });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Focus(
            autofocus: true,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Reset Password',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    'Enter Key',
                    keyController,
                    false,
                    keyFocus,
                    true,
                  ),
                  const SizedBox(height: 12),

                  _buildField('Username', usernameController),
                  const SizedBox(height: 12),

                  _buildField('New Password', newPasswordController, true),
                  const SizedBox(height: 12),

                  _buildField(
                    'Confirm Password',
                    confirmPasswordController,
                    true,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (keyController.text != 'Aksh_Patel') {
                              _showMessage('Invalid Key');
                              return;
                            }

                            if (usernameController.text != 'admin') {
                              _showMessage('Invalid Username');
                              return;
                            }

                            if (newPasswordController.text.isEmpty ||
                                confirmPasswordController.text.isEmpty) {
                              _showMessage('Fill all fields');
                              return;
                            }

                            if (newPasswordController.text !=
                                confirmPasswordController.text) {
                              _showMessage('Passwords do not match');
                              return;
                            }

                            await _saveNewPassword(newPasswordController.text);

                            Navigator.pop(context);

                            _showMessage('Password Reset Successful');
                          },
                          child: const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, [
    bool isPassword = false,
    FocusNode? focusNode,
    bool autoFocus = false,
  ]) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autoFocus,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF7A18)),
        ),
      ),
    );
  }

  final FocusNode keyFocus = FocusNode();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;
  bool get isEnabled =>
      _usernameController.text.trim().isNotEmpty &&
      _passwordController.text.trim().isNotEmpty &&
      !_isLoading;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });

      if (_usernameController.text == 'admin' &&
          _passwordController.text == _savedPassword) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BillScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid username or password';
        });
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey.shade200,
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 250),
            child: Container(
              width: 380,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Aksh Enterprises',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    const SizedBox(height: 24),

                    /// Username
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    /// Password with eye icon
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }
                        return null;
                      },
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Error message
                    if (_errorMessage.isNotEmpty &&
                        _usernameController.text.isNotEmpty &&
                        _passwordController.text.isNotEmpty)
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),

                    const SizedBox(height: 12),

                    /// Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Builder(
                        builder: (context) {
                          bool isEnabled =
                              _usernameController.text.trim().isNotEmpty &&
                              _passwordController.text.trim().isNotEmpty &&
                              !_isLoading;

                          return ElevatedButton(
                            onPressed: isEnabled ? _login : null,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isEnabled
                                      ? [
                                          const Color(0xFF4A90E2),
                                          const Color(0xFF2F6DB3),
                                        ]
                                      : [
                                          Colors.grey.shade400,
                                          Colors.grey.shade400,
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'LOGIN',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1,
                                          color: isEnabled
                                              ? Colors.white
                                              : Colors.white70,
                                        ),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
