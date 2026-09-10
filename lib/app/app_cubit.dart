import 'package:bebi_app/core/ui/async_value.dart';
import 'package:bebi_app/features/account/domain/couple_context.dart';
import 'package:bebi_app/features/account/domain/resolve_couple_context_usecase.dart';
import 'package:bebi_app/utils/mixins/localizations_mixin.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'app_state.dart';

/// {@template app_cubit}
///
/// Cubit responsible for managing the global app state.
///
/// This includes loading and storing user profiles and partnership information.
/// Other global stuff can be added here as needed.
///
/// {@endtemplate}
@injectable
class AppCubit extends Cubit<AppState> with LocalizationsMixin {
  /// {@macro app_cubit}
  AppCubit(this._resolveCoupleContext) : super(const AppState());

  final ResolveCoupleContextUsecase _resolveCoupleContext;

  Future<void> loadCoupleContext({bool useCache = true}) async {
    emit(
      state.copyWith(
        coupleContextAsync: await AsyncValue.guard(
          () => _resolveCoupleContext.withProfilePictures(useCache: useCache),
        ),
      ),
    );
  }

  void onUserSignInStatusChanged(bool isSignedIn) {
    emit(state.copyWith(userIsSignedIn: isSignedIn));
  }
}
