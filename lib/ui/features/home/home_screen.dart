import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/ui/features/home/home_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final _cubit = context.read<HomeCubit>();

  @override
  void initState() {
    super.initState();
    _cubit.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeCubit, HomeState>(
      listener: (context, state) => switch (state) {
        HomeShouldSetUpProfile() => context.goNamed(AppRoutes.profileSetup),
        HomeShouldAddPartner() => context.goNamed(AppRoutes.addPartner),
        HomeError(:final String message) => context.showSnackbar(message),
        _ => null,
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Home Screen'),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await _cubit.signOut();
                  context.goNamed(AppRoutes.signIn);
                },
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
