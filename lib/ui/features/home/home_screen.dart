import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/ui/features/home/home_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeCubit>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeCubit, HomeState>(
      listener: (context, state) => switch (state) {
        HomeShouldSetUpProfile() => context.goNamed(AppRoutes.profileSetup),
        HomeError(:final message) => context.showSnackbar(message),
        _ => null,
      },
      child: ListView(
        children: [
          Center(
            child: Text(
              'Welcome to the Home Screen',
              style: context.textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}
