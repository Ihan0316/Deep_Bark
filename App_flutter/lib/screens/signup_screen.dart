// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/locale_provider.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _passwordError;
  String? _usernameError;
  String? _emailError;
  bool _isUsernameAvailable = false;
  bool _isEmailAvailable = false;
  bool _isCheckingUsername = false;
  bool _isCheckingEmail = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _authService.dispose();
    super.dispose();
  }

  void _validatePasswords() {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _passwordError = '비밀번호가 일치하지 않습니다.';
      });
    } else {
      setState(() {
        _passwordError = null;
      });
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }
    if (value.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return '대문자를 포함해야 합니다';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return '소문자를 포함해야 합니다';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return '숫자를 포함해야 합니다';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return '특수문자를 포함해야 합니다';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return '사용자 이름을 입력해주세요';
    }
    if (value.length < 3) {
      return '사용자 이름은 3자 이상이어야 합니다';
    }
    if (value.length > 15) {
      return '사용자 이름은 15자 이하여야 합니다';
    }
    if (!RegExp(r'^[a-zA-Z0-9가-힣]+$').hasMatch(value)) {
      return '사용자 이름은 영문, 숫자, 한글만 사용 가능합니다';
    }
    return null;
  }

  void _handleUsernameChange(String value) {
    setState(() {
      _usernameError = null;
      _isUsernameAvailable = false;
      _isCheckingUsername = true;
    });

    if (!RegExp(r'^[a-zA-Z0-9가-힣]+$').hasMatch(value)) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = false;
        _usernameError = '사용자 이름은 영문, 숫자, 한글만 사용 가능합니다';
      });
      return;
    }

    _authService.debouncedCheckUsername(value, (isAvailable) {
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = isAvailable;
          if (!isAvailable && value.isNotEmpty) {
            _usernameError = '이미 사용 중인 사용자 이름입니다.';
          }
        });
      }
    });
  }

  void _handleEmailChange(String value) {
    setState(() {
      _emailError = null;
      _isEmailAvailable = false;
      _isCheckingEmail = true;
    });

    _authService.debouncedCheckEmail(value, (isAvailable) {
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
          _isEmailAvailable = isAvailable;
          if (!isAvailable && value.isNotEmpty) {
            _emailError = '이미 사용 중인 이메일입니다.';
          }
        });
      }
    });
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _passwordError = '비밀번호가 일치하지 않습니다.';
        });
        return;
      }

      if (!_isUsernameAvailable) {
        setState(() {
          _usernameError = '사용 가능한 사용자 이름을 입력해주세요.';
        });
        return;
      }

      if (!_isEmailAvailable) {
        setState(() {
          _emailError = '사용 가능한 이메일을 입력해주세요.';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _passwordError = null;
      });

      try {
        final success = await _authService.signup(
          _emailController.text,
          _passwordController.text,
          _usernameController.text,
        );

        if (success) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = '회원가입에 실패했습니다.';
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            if (e.toString().contains('이미 사용 중인 사용자 이름입니다')) {
              _usernameError = '이미 사용 중인 사용자 이름입니다.';
              _isUsernameAvailable = false;
            } else if (e.toString().contains('이미 사용 중인 이메일입니다')) {
              _emailError = '이미 사용 중인 이메일입니다.';
              _isEmailAvailable = false;
            } else {
              _errorMessage = '오류가 발생했습니다: $e';
            }
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: Colors.brown,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (_errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: '사용자 이름',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                    errorText: _usernameError,
                    suffixIcon: _isCheckingUsername
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                            ),
                          )
                        : _usernameController.text.isNotEmpty
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isUsernameAvailable ? Icons.check_circle : Icons.cancel,
                                    color: _isUsernameAvailable ? Colors.green : Colors.red,
                                    size: 20,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _usernameController.clear();
                                      setState(() {
                                        _isUsernameAvailable = false;
                                        _usernameError = null;
                                      });
                                    },
                                  ),
                                ],
                              )
                            : null,
                  ),
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                  ),
                  onChanged: _handleUsernameChange,
                  validator: _validateUsername,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    errorText: _emailError,
                    suffixIcon: _isCheckingEmail
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                            ),
                          )
                        : _emailController.text.isNotEmpty
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isEmailAvailable ? Icons.check_circle : Icons.cancel,
                                    color: _isEmailAvailable ? Colors.green : Colors.red,
                                    size: 20,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _emailController.clear();
                                      setState(() {
                                        _isEmailAvailable = false;
                                        _emailError = null;
                                      });
                                    },
                                  ),
                                ],
                              )
                            : null,
                  ),
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: _handleEmailChange,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return '올바른 이메일 형식이 아닙니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                  ),
                  obscureText: true,
                  onChanged: (_) => _validatePasswords(),
                  validator: _validatePassword,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: '비밀번호 재확인',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                    errorText: _passwordError,
                  ),
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                  ),
                  obscureText: true,
                  onChanged: (_) => _validatePasswords(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 다시 입력해주세요';
                    }
                    if (value != _passwordController.text) {
                      return '비밀번호가 일치하지 않습니다';
                    }
                    return null;
                  },
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          minimumSize: Size(double.infinity, MediaQuery.of(context).size.height * 0.06),
                        ),
                        child: Text(
                          '회원가입',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                          ),
                        ),
                      ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    '이미 계정이 있으신가요?',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
