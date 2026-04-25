import 'package:flutter/foundation.dart';

class UserProfileProvider extends ChangeNotifier {
  String displayName = '';

  void updateName(String name) {
    displayName = name;
    notifyListeners();
  }
}
