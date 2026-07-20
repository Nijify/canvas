// Path: oss_packages/canvas_editor_flutter/lib/src/presentation/widgets/editor_app_bar.dart

import 'package:flutter/material.dart';

import 'package:canvas_editor_flutter/src/presentation/actions/editor_actions.dart';

class EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EditorAppBar({
    super.key,
    required this.title,
    required this.state,
    required this.actions,
    required this.actionSpecs,
  });

  final String title;
  final EditorToolbarState state;
  final EditorActionDispatcher actions;
  final List<EditorActionSpec> actionSpecs;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: buildEditorToolbarActions(
        state: state,
        actions: actions,
        actionSpecs: actionSpecs,
      ),
    );
  }
}

List<Widget> buildEditorToolbarActions({
  required EditorToolbarState state,
  required EditorActionDispatcher actions,
  required List<EditorActionSpec> actionSpecs,
}) {
  final sections = _sectionsInOrder(actionSpecs, state);

  if (state.compact) {
    return [
      _CompactOverflow(
        state: state,
        actions: actions,
        sections: sections,
        allActions: actionSpecs,
      ),
    ];
  }

  final widgets = <Widget>[];

  for (final section in sections) {
    if (section == EditorToolbarSection.add) {
      widgets.add(
        _InsertActionMenu(
          state: state,
          actions: actions,
          allActions: actionSpecs,
        ),
      );
      continue;
    }

    if (_renderAsIconButtons(section)) {
      widgets.addAll(
        _buildIconButtons(
          actions: actions,
          state: state,
          section: section,
          allActions: actionSpecs,
        ),
      );
      continue;
    }

    final menu = _buildSectionMenu(
      actions: actions,
      state: state,
      section: section,
      allActions: actionSpecs,
    );
    if (menu != null) widgets.add(menu);
  }

  return widgets;
}

class _InsertActionMenu extends StatelessWidget {
  const _InsertActionMenu({
    required this.state,
    required this.actions,
    required this.allActions,
  });

  final EditorToolbarState state;
  final EditorActionDispatcher actions;
  final List<EditorActionSpec> allActions;

  @override
  Widget build(BuildContext context) {
    final items = _sectionItems(EditorToolbarSection.add, state, allActions);

    if (items.isEmpty) return const SizedBox.shrink();

    final ungrouped = <EditorActionSpec>[];
    final grouped = <String, List<EditorActionSpec>>{};

    for (final action in items) {
      final group = action.menuGroup?.trim();

      if (group == null || group.isEmpty) {
        ungrouped.add(action);
      } else {
        grouped.putIfAbsent(group, () => <EditorActionSpec>[]).add(action);
      }
    }

    return PopupMenuButton<EditorActionSpec>(
      tooltip: 'Insert',
      icon: const Icon(Icons.add),
      onSelected: (action) => actions.invoke(action.id),
      itemBuilder: (context) {
        final entries = <PopupMenuEntry<EditorActionSpec>>[];

        void addDividerIfNeeded() {
          if (entries.isNotEmpty) {
            entries.add(const PopupMenuDivider());
          }
        }

        for (final action in ungrouped) {
          entries.add(_insertMenuItem(action));
        }

        for (final entry in grouped.entries) {
          addDividerIfNeeded();

          entries.add(_insertGroupHeader(context, entry.key));

          for (final action in entry.value) {
            entries.add(_insertMenuItem(action));
          }
        }

        return entries;
      },
    );
  }

  PopupMenuItem<EditorActionSpec> _insertGroupHeader(
    BuildContext context,
    String groupName,
  ) {
    final theme = Theme.of(context);

    return PopupMenuItem<EditorActionSpec>(
      enabled: false,
      height: 32,
      child: Text(
        groupName,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  PopupMenuItem<EditorActionSpec> _insertMenuItem(EditorActionSpec action) {
    return PopupMenuItem<EditorActionSpec>(
      value: action,
      enabled: _canInvokeAction(actions, state, action),
      child: ListTile(
        dense: true,
        leading: Icon(action.iconBuilder(state)),
        title: Text(action.labelBuilder(state)),
      ),
    );
  }
}

bool _renderAsIconButtons(EditorToolbarSection section) {
  return section == EditorToolbarSection.undoRedo ||
      section == EditorToolbarSection.export;
}

List<EditorToolbarSection> _sectionsInOrder(
  List<EditorActionSpec> allActions,
  EditorToolbarState state,
) {
  final sections = <EditorToolbarSection>[];

  for (final action in allActions) {
    if (!action.isVisible(state)) continue;
    if (sections.contains(action.section)) continue;
    sections.add(action.section);
  }

  return sections;
}

List<EditorActionSpec> _sectionItems(
  EditorToolbarSection section,
  EditorToolbarState state,
  List<EditorActionSpec> allActions,
) {
  return allActions
      .where((action) => action.section == section)
      .where((action) => action.isVisible(state))
      .toList(growable: false)
    ..sort((a, b) => b.priority.compareTo(a.priority));
}

bool _canInvokeAction(
  EditorActionDispatcher actions,
  EditorToolbarState state,
  EditorActionSpec action,
) {
  return action.isEnabled(state) && actions.canInvoke(action.id);
}

Widget? _buildSectionMenu({
  required EditorActionDispatcher actions,
  required EditorToolbarState state,
  required EditorToolbarSection section,
  required List<EditorActionSpec> allActions,
}) {
  final items = _sectionItems(section, state, allActions);
  if (items.isEmpty) return null;

  final first = items.first;
  final tooltip = section.label ?? first.labelBuilder(state);
  final icon = section.icon ?? first.iconBuilder(state);

  return _ActionMenu(
    tooltip: tooltip,
    icon: Icon(icon),
    actions: actions,
    state: state,
    items: items,
  );
}

List<Widget> _buildIconButtons({
  required EditorActionDispatcher actions,
  required EditorToolbarState state,
  required EditorToolbarSection section,
  required List<EditorActionSpec> allActions,
}) {
  return _sectionItems(section, state, allActions)
      .map(
        (action) => IconButton(
          tooltip: action.labelBuilder(state),
          onPressed: _canInvokeAction(actions, state, action)
              ? () => actions.invoke(action.id)
              : null,
          icon: Icon(action.iconBuilder(state)),
        ),
      )
      .toList(growable: false);
}

class _ActionMenu extends StatelessWidget {
  const _ActionMenu({
    required this.tooltip,
    required this.icon,
    required this.actions,
    required this.state,
    required this.items,
  });

  final String tooltip;
  final Widget icon;
  final EditorActionDispatcher actions;
  final EditorToolbarState state;
  final List<EditorActionSpec> items;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<EditorActionSpec>(
      tooltip: tooltip,
      icon: icon,
      onSelected: (action) => actions.invoke(action.id),
      itemBuilder: (context) => [
        for (final action in items)
          PopupMenuItem(
            value: action,
            enabled: _canInvokeAction(actions, state, action),
            child: ListTile(
              dense: true,
              leading: Icon(action.iconBuilder(state)),
              title: Text(action.labelBuilder(state)),
            ),
          ),
      ],
    );
  }
}

class _CompactOverflow extends StatelessWidget {
  const _CompactOverflow({
    required this.state,
    required this.actions,
    required this.sections,
    required this.allActions,
  });

  final EditorToolbarState state;
  final EditorActionDispatcher actions;
  final List<EditorToolbarSection> sections;
  final List<EditorActionSpec> allActions;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<EditorActionSpec>(
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => actions.invoke(action.id),
      itemBuilder: (context) =>
          _buildCompactItems(state, actions, sections, allActions),
    );
  }
}

List<PopupMenuEntry<EditorActionSpec>> _buildCompactItems(
  EditorToolbarState state,
  EditorActionDispatcher actions,
  List<EditorToolbarSection> sections,
  List<EditorActionSpec> allActions,
) {
  final entries = <PopupMenuEntry<EditorActionSpec>>[];

  for (final section in sections) {
    final items = _sectionItems(section, state, allActions);
    if (items.isEmpty) continue;

    if (entries.isNotEmpty) {
      entries.add(const PopupMenuDivider());
    }

    entries.addAll(
      items.map(
        (action) => PopupMenuItem(
          value: action,
          enabled: _canInvokeAction(actions, state, action),
          child: ListTile(
            dense: true,
            leading: Icon(action.iconBuilder(state)),
            title: Text(action.labelBuilder(state)),
          ),
        ),
      ),
    );
  }

  return entries;
}
