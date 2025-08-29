import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/state_extensions.dart';
import 'package:bebi_app/utils/extensions/widgets_binding_extensions.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:super_editor/super_editor.dart';

/// {@template markdown_toolbar}
///
/// Customized mobile document editing toolbar based on Super Editor's implementation.
///
/// Source: https://github.com/superlistapp/super_editor/blob/main/super_editor/lib/src/default_editor/document_ime/mobile_toolbar.dart
///
/// Displays above the software keyboard in the application overlay while optionally
/// reserving equivalent space in the widget tree to prevent content overlap.
///
/// Features markdown editing capabilities including paragraph conversion to
/// blockquotes and list items, plus horizontal rule insertion.
///
/// {@endtemplate}
class StickyMarkdownToolbar extends StatefulWidget {
  /// {@macro markdown_toolbar}
  const StickyMarkdownToolbar({
    required this.editor,
    required this.document,
    required this.composer,
    required this.commonOps,
    this.takeUpSameSpaceAsToolbar = false,
    super.key,
  });

  final Editor editor;
  final Document document;
  final DocumentComposer composer;
  final CommonEditorOperations commonOps;
  final bool takeUpSameSpaceAsToolbar;

  @override
  State<StickyMarkdownToolbar> createState() => _StickyMarkdownToolbarState();
}

class _StickyMarkdownToolbarState extends State<StickyMarkdownToolbar>
    with WidgetsBindingObserver {
  late StickyMarkdownToolbarOperations _toolbarOps;

  final _portalController = GroupedOverlayPortalController(
    displayPriority: OverlayGroupPriority.windowChrome,
  );

  double _toolbarHeight = 0;

  @override
  void initState() {
    super.initState();

    _toolbarOps = StickyMarkdownToolbarOperations(
      editor: widget.editor,
      document: widget.document,
      composer: widget.composer,
      commonOps: widget.commonOps,
    );

    WidgetsBinding.instance.runAsSoonAsPossible(_portalController.show);
  }

  @override
  void didUpdateWidget(StickyMarkdownToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _toolbarOps = StickyMarkdownToolbarOperations(
      editor: widget.editor,
      document: widget.document,
      composer: widget.composer,
      commonOps: widget.commonOps,
    );
  }

  @override
  void dispose() {
    if (_portalController.isShowing) _portalController.hide();
    super.dispose();
  }

  void _onToolbarLayout(double toolbarHeight) {
    if (toolbarHeight == _toolbarHeight) return;

    // The toolbar in the overlay changed its height. Our child needs to take up the
    // same amount of height so that content doesn't go behind our toolbar. Rebuild
    // with the latest toolbar height and take up an equal amount of height.
    setStateAsSoonAsPossible(() => _toolbarHeight = toolbarHeight);
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portalController,
      overlayChildBuilder: _buildToolbarOverlay,
      // Take up empty space that's as tall as the toolbar so that other content
      // doesn't layout behind it.
      child: SizedBox(
        height: widget.takeUpSameSpaceAsToolbar ? _toolbarHeight : 0,
      ),
    );
  }

  Widget _buildToolbarOverlay(BuildContext context) {
    final selection = widget.composer.selection;
    if (selection == null) return const SizedBox();

    return KeyboardHeightBuilder(
      builder: (context, keyboardHeight) {
        return Padding(
          // Add padding that takes up the height of the software keyboard so
          // that the toolbar sits just above the keyboard.
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: _buildToolbar(context),
          ),
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final selection = widget.composer.selection!;

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: context.colorScheme.outline,
            width: UiConstants.borderWidth,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          _onToolbarLayout(constraints.maxHeight);
          return ListenableBuilder(
            listenable: widget.composer,
            builder: (context, _) {
              final selectedNode = widget.document.getNodeById(
                selection.extent.nodeId,
              );
              final isSingleNodeSelected =
                  selection.extent.nodeId == selection.base.nodeId;

              return Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ..._buildFormattingButtons(selectedNode),
                          ..._buildListButtons(
                            selectedNode,
                            isSingleNodeSelected,
                          ),
                          ..._buildHeadingButtons(
                            selectedNode,
                            isSingleNodeSelected,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    color: context.colorScheme.outline.withAlpha(80),
                    height: 38,
                    width: 1,
                  ),
                  _buildKeyboardHideButton(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildFormattingButtons(DocumentNode? selectedNode) {
    return [
      _buildToolbarButton(
        onPressed: selectedNode is TextNode ? _toolbarOps.toggleBold : null,
        icon: Symbols.format_bold,
        isActive: _toolbarOps.isBoldActive,
      ),
      _buildToolbarButton(
        onPressed: selectedNode is TextNode ? _toolbarOps.toggleItalics : null,
        icon: Symbols.format_italic,
        isActive: _toolbarOps.isItalicsActive,
      ),
      _buildToolbarButton(
        onPressed: selectedNode is TextNode
            ? _toolbarOps.toggleUnderline
            : null,
        icon: Symbols.format_underlined,
        isActive: _toolbarOps.isUnderlineActive,
      ),
      _buildToolbarButton(
        onPressed: selectedNode is TextNode
            ? _toolbarOps.toggleStrikethrough
            : null,
        icon: Symbols.strikethrough_s,
        isActive: _toolbarOps.isStrikethroughActive,
      ),
    ];
  }

  List<Widget> _buildListButtons(
    DocumentNode? selectedNode,
    bool isSingleNodeSelected,
  ) {
    return [
      _buildToolbarButton(
        onPressed:
            isSingleNodeSelected &&
                (selectedNode is TextNode && selectedNode is! ListItemNode ||
                    (selectedNode is ListItemNode &&
                        selectedNode.type != ListItemType.ordered))
            ? _toolbarOps.convertToOrderedListItem
            : null,
        icon: Symbols.format_list_numbered,
      ),
      _buildToolbarButton(
        onPressed:
            isSingleNodeSelected &&
                (selectedNode is TextNode && selectedNode is! ListItemNode ||
                    (selectedNode is ListItemNode &&
                        selectedNode.type != ListItemType.unordered))
            ? _toolbarOps.convertToUnorderedListItem
            : null,
        icon: Symbols.format_list_bulleted,
      ),
    ];
  }

  List<Widget> _buildHeadingButtons(
    DocumentNode? selectedNode,
    bool isSingleNodeSelected,
  ) {
    return [
      _buildToolbarButton(
        onPressed: isSingleNodeSelected && selectedNode is TextNode
            ? () => _toolbarOps.convertToHeading(1)
            : null,
        icon: Symbols.format_h1,
      ),
      _buildToolbarButton(
        onPressed: isSingleNodeSelected && selectedNode is TextNode
            ? () => _toolbarOps.convertToHeading(2)
            : null,
        icon: Symbols.format_h2,
      ),
      _buildToolbarButton(
        onPressed: isSingleNodeSelected && selectedNode is TextNode
            ? () => _toolbarOps.convertToHeading(3)
            : null,
        icon: Symbols.format_h3,
      ),
      _buildToolbarButton(
        onPressed: isSingleNodeSelected && selectedNode is TextNode
            ? () => _toolbarOps.convertToHeading(4)
            : null,
        icon: Symbols.format_h4,
      ),
      _buildToolbarButton(
        onPressed: isSingleNodeSelected && selectedNode is TextNode
            ? () => _toolbarOps.convertToHeading(5)
            : null,
        icon: Symbols.format_h5,
      ),
      _buildToolbarButton(
        onPressed: isSingleNodeSelected && selectedNode is TextNode
            ? () => _toolbarOps.convertToHeading(6)
            : null,
        icon: Symbols.format_h6,
      ),
    ];
  }

  Widget _buildKeyboardHideButton() {
    return _buildToolbarButton(
      onPressed: _toolbarOps.closeKeyboard,
      icon: Symbols.keyboard_hide,
    );
  }

  Widget _buildToolbarButton({
    required VoidCallback? onPressed,
    required IconData icon,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, weight: isActive ? 700 : 400),
        color: isActive
            ? context.colorScheme.primary
            : context.colorScheme.secondary.withAlpha(180),
      ),
    );
  }
}

@visibleForTesting
class StickyMarkdownToolbarOperations {
  StickyMarkdownToolbarOperations({
    required this.editor,
    required this.document,
    required this.composer,
    required this.commonOps,
    this.brightness,
  });

  final Editor editor;
  final Document document;
  final DocumentComposer composer;
  final CommonEditorOperations commonOps;
  final Brightness? brightness;

  bool get isBoldActive => _doesSelectionHaveAttributions({boldAttribution});
  void toggleBold() => _toggleAttributions({boldAttribution});

  bool get isItalicsActive =>
      _doesSelectionHaveAttributions({italicsAttribution});
  void toggleItalics() => _toggleAttributions({italicsAttribution});

  bool get isUnderlineActive =>
      _doesSelectionHaveAttributions({underlineAttribution});
  void toggleUnderline() => _toggleAttributions({underlineAttribution});

  bool get isStrikethroughActive =>
      _doesSelectionHaveAttributions({strikethroughAttribution});
  void toggleStrikethrough() => _toggleAttributions({strikethroughAttribution});

  bool _doesSelectionHaveAttributions(Set<Attribution> attributions) {
    final selection = composer.selection;
    if (selection == null) return false;

    if (selection.isCollapsed) {
      return composer.preferences.currentAttributions.containsAll(attributions);
    }

    return document.doesSelectedTextContainAttributions(
      selection,
      attributions,
    );
  }

  void _toggleAttributions(Set<Attribution> attributions) {
    final selection = composer.selection;
    if (selection == null) return;

    selection.isCollapsed
        ? commonOps.toggleComposerAttributions(attributions)
        : commonOps.toggleAttributionsOnSelection(attributions);
  }

  void convertToOrderedListItem() {
    final selectedNode =
        document.getNodeById(composer.selection!.extent.nodeId)! as TextNode;

    commonOps.convertToListItem(ListItemType.ordered, selectedNode.text);
  }

  void convertToUnorderedListItem() {
    final selectedNode =
        document.getNodeById(composer.selection!.extent.nodeId)! as TextNode;

    commonOps.convertToListItem(ListItemType.unordered, selectedNode.text);
  }

  void convertToHeading(int level) {
    final selectedNode =
        document.getNodeById(composer.selection!.extent.nodeId)! as TextNode;

    editor.execute([
      ReplaceNodeRequest(
        existingNodeId: selectedNode.id,
        newNode: ParagraphNode(
          id: selectedNode.id,
          text: selectedNode.text,
          metadata: {'blockType': NamedAttribution('header$level')},
        ),
      ),
    ]);
  }

  void closeKeyboard() {
    editor.execute([
      const ChangeSelectionRequest(
        null,
        SelectionChangeType.clearSelection,
        SelectionReason.userInteraction,
      ),
    ]);
  }
}
