import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuro_word/core/services/user_profile_service.dart';

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});
