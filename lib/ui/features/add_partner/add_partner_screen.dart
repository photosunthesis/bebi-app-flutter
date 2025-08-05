import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/features/add_partner/add_partner_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/shadow/shadow_container.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:bebi_app/utils/formatter/user_code_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddPartnerScreen extends StatefulWidget {
  const AddPartnerScreen({super.key});

  @override
  State<AddPartnerScreen> createState() => _AddPartnerScreenState();
}

class _AddPartnerScreenState extends State<AddPartnerScreen> {
  late final _cubit = context.read<AddPartnerCubit>();
  final _userCodeController = TextEditingController();
  final _partnerCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _cubit.initialize();
  }

  @override
  void dispose() {
    _userCodeController.dispose();
    _partnerCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddPartnerCubit, AddPartnerState>(
      listener: (context, state) {
        if (state.currentUserCode.isNotEmpty) {
          final code = state.currentUserCode;
          final firstPart = code.substring(0, code.length ~/ 2);
          final secondPart = code.substring(code.length ~/ 2);
          _userCodeController.text = '$firstPart-$secondPart';
        }

        if (state.error != null) {
          context.showSnackbar(state.error!, duration: 6.seconds);
        }

        if (state.success) context.goNamed(AppRoutes.home);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SafeArea(child: SizedBox(height: UiConstants.padding)),
                _buildHeader(),
                const SizedBox(height: 32),
                _buildUserCodeSection(),
                const SizedBox(height: 12),
                Text(
                  'or',
                  style: context.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                _buildPartnerCodeSection(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Connect with a partner',
          style: context.primaryTextTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: context.screenWidth * 0.85,
          child: Text(
            'Share your code with a partner or enter theirs below. It\'s how you\'ll connect and start sharing moments together.',
            style: context.textTheme.bodyLarge?.copyWith(
              height: 1.4,
              fontWeight: FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildUserCodeSection() {
    return _buildCodeContainer(
      title: 'Share your code',
      child: Stack(
        children: [
          AppTextFormField(
            controller: _userCodeController,
            hintText: 'XXX-XXX',
            readOnly: true,
          ),
          Positioned(
            right: 10,
            top: 10,
            child: TextButton(
              child: const Text('Copy'),
              onPressed: () async {
                if (_userCodeController.text.isEmpty) return;

                await Clipboard.setData(
                  ClipboardData(
                    text: _userCodeController.text.replaceAll('-', ''),
                  ),
                );

                context.showSnackbar(
                  'Code "${_userCodeController.text}" copied to clipboard.',
                  type: SnackbarType.success,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerCodeSection() {
    return _buildCodeContainer(
      title: 'Enter their code',
      child: AppTextFormField(
        controller: _partnerCodeController,
        hintText: 'XXX-XXX',
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        inputFormatters: const <TextInputFormatter>[UserCodeFormatter()],
        autofillHints: const <String>[AutofillHints.oneTimeCode],
        validator: (value) {
          if (value == null || value.isEmpty) return null;
          if (value.length != 7) return 'Code must be 6 characters long.';
          return null;
        },
      ),
    );
  }

  Widget _buildCodeContainer({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: UiConstants.borderRadius,
        border: Border.all(
          color: context.colorScheme.onSecondary,
          width: UiConstants.borderWidth,
        ),
      ),
      margin: EdgeInsets.symmetric(horizontal: context.screenWidth * 0.05),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Text(title, style: context.textTheme.bodyMedium),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: context.screenWidth * 0.05),
        padding: const EdgeInsets.all(UiConstants.padding),
        child: BlocSelector<AddPartnerCubit, AddPartnerState, bool>(
          selector: (state) => state.loading,
          builder: (context, loading) {
            return ShadowContainer(
              child: ElevatedButton(
                onPressed: loading
                    ? null
                    : () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _cubit.submit(
                            partnerCode: _partnerCodeController.text.isEmpty
                                ? null
                                : _partnerCodeController.text.replaceAll(
                                    '-',
                                    '',
                                  ),
                          );
                        }
                      },

                child: const Text('Finish connecting'),
              ),
            );
          },
        ),
      ),
    );
  }
}
