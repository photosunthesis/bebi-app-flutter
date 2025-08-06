import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

@Injectable()
class UserPreferencesRepository {
  const UserPreferencesRepository(this._userPreferencesBox);

  final Box<bool> _userPreferencesBox;

  // Generate keys here: http://bit.ly/random-strings-generator
  static const _didSetUpCycleKey = '3BR9yUWlCGAH';

  Future<void> saveCycleSetupCompletion({required bool isCompleted}) async {
    await _userPreferencesBox.put(_didSetUpCycleKey, isCompleted);
  }

  bool isCycleSetupCompleted() {
    return _userPreferencesBox.get(_didSetUpCycleKey) ?? false;
  }
}
