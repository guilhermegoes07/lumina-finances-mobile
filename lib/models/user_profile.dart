import 'package:flutter/foundation.dart';

class UserProfile extends ChangeNotifier {
  String _name = '';
  String _email = '';
  String _profileType = 'Pessoal';
  String _avatarUrl = '';

  UserProfile({
    String name = '',
    String email = '',
    String profileType = 'Pessoal',
    String avatarUrl = '',
  }) : 
    _name = name,
    _email = email,
    _profileType = profileType,
    _avatarUrl = avatarUrl;

  String get name => _name;
  String get email => _email;
  String get profileType => _profileType;
  String get avatarUrl => _avatarUrl;

  void updateProfile({
    String? name,
    String? email,
    String? profileType,
    String? avatarUrl,
  }) {
    if (name != null) _name = name;
    if (email != null) _email = email;
    if (profileType != null) _profileType = profileType;
    if (avatarUrl != null) _avatarUrl = avatarUrl;
    notifyListeners();
  }
} 