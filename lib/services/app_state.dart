import 'package:flutter/foundation.dart';

import '../content/copy.dart';
import '../models/models.dart';

/// 앱 전역 상태 (선택 카테고리, 입력 중인 프로필 등).
class AppState extends ChangeNotifier {
  AnalysisCategory _selectedCategory = AnalysisCategory.basic;
  AnalysisCategory get selectedCategory => _selectedCategory;

  final UserProfile user = UserProfile();
  final PartnerProfile partner = PartnerProfile();
  String userQuestion = '';

  void selectCategory(AnalysisCategory c) {
    _selectedCategory = c;
    notifyListeners();
  }
}
