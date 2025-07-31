import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/ui/features/home/home_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
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
    context.read<HomeCubit>().initialize();
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
      child: const Scaffold(body: Center(child: Text('Home Screen'))),
    );
  }
}
