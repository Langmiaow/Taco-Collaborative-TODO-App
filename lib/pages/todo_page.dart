import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taco/pages/detail_page.dart';
import 'package:taco/pages/add_page.dart';
import 'package:taco/l10n/app_localizations.dart';
import 'package:taco/main.dart';
import 'package:taco/services/todo_storage.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<StatefulWidget> createState() => _TodoPage();
}

class _TodoPage extends State<TodoPage> {
  // Select mode vars
  bool selectMode = false;
  bool showDone = false;

  Set<int> selectedIndex = {};
  Set<int> pendingSet = {};

  Future<void> _setDone(int index, bool done) async {
    await TodoStorage.setDone(index, done);
    setState(() {});
  }

  // To do card
  Widget todoCard(String content, int index, {bool disableLongPress = false}) {
    final bool isSelected = selectedIndex.contains(index);
    final bool isPending = pendingSet.contains(index);

    return Column(
      children: [
        Material(
          color: isSelected ? Colors.grey[300] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),

            // Long press, go into select mode
            onLongPress: disableLongPress
                ? null
                : () {
                    setState(() {
                      selectMode = true;
                      selectedIndex.add(index);
                    });
                  },

            onTap: () async {
              if (selectMode) {
                setState(() {
                  if (isSelected) {
                    selectedIndex.remove(index);
                    if (selectedIndex.isEmpty) selectMode = false;
                  } else {
                    selectedIndex.add(index);
                  }
                });
                return;
              }

              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => DetailPage(todoIndex: index)),
              );

              if (updated == true) {
                setState(() {});
              }
            },

            child: Container(
              width: double.infinity,
              height: 80,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      if (selectMode) {
                        setState(() {
                          if (isSelected) {
                            selectedIndex.remove(index);
                            if (selectedIndex.isEmpty) selectMode = false;
                          } else {
                            selectedIndex.add(index);
                          }
                        });
                        return;
                      }

                      // avoid repeat
                      if (pendingSet.contains(index)) return;

                      // mark icon
                      setState(() {
                        pendingSet.add(index);
                      });

                      HapticFeedback.mediumImpact();

                      // show icon change
                      await Future.delayed(const Duration(milliseconds: 500));

                      // edit data
                      if (showDone) {
                        await _setDone(index, false); // done → to do
                        HapticFeedback.mediumImpact();
                      } else {
                        await _setDone(index, true); // to do → done
                        HapticFeedback.mediumImpact();
                      }

                      // clear pending
                      if (mounted) {
                        setState(() {
                          pendingSet.remove(index);
                        });
                      }
                    },

                    child: Padding(
                      padding: const EdgeInsets.all(10), //expand tap area
                      child: Icon(
                        showDone
                            ? (isPending
                                  ? Icons
                                        .check_box_outline_blank // done → reset
                                  : Icons.check_box) // done
                            : (isPending
                                  ? Icons
                                        .check_box // to do → to be done
                                  : Icons.check_box_outline_blank),
                        color: isPending
                            ? const Color.fromARGB(255, 40, 110, 240)
                            : Colors.grey,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      content,
                      style: const TextStyle(fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  List<int> _filteredIndex(List todos) {
    final result = <int>[];

    for (int i = 0; i < todos.length; i++) {
      final t = todos[i];
      if ((t is Map && t["isDone"] == true) == showDone) {
        result.add(i);
      }
    }

    if (showDone) {
      result.sort((a, b) {
        final ta = todos[a];
        final tb = todos[b];

        final doneAtA = ta is Map && ta["doneAt"] is int
            ? ta["doneAt"] as int
            : 0;

        final doneAtB = tb is Map && tb["doneAt"] is int
            ? tb["doneAt"] as int
            : 0;

        return doneAtB.compareTo(doneAtA);
      });
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color.fromARGB(255, 237, 237, 237),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          // selectMode -> exit
          if (selectMode) {
            setState(() {
              selectedIndex.clear();
              selectMode = false;
            });
            return;
          }

          // done → to do
          if (showDone) {
            setState(() {
              showDone = false;
              selectedIndex.clear();
              selectMode = false;
            });
            return;
          }

          SystemNavigator.pop();
        },
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 45),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FutureBuilder(
                    future: TodoStorage.readTodoList(),
                    builder: (context, tempTop) {
                      final List topTodos =
                          (tempTop.data?["todos"] ?? []) as List;

                      final filteredIndex = _filteredIndex(topTodos);

                      final int selectedInView = selectedIndex
                          .where((i) => filteredIndex.contains(i))
                          .length;

                      final bool allSelected =
                          filteredIndex.isNotEmpty &&
                          selectedInView == filteredIndex.length;

                      final count = selectedIndex.length;
                      final title = selectMode
                          ? t.selectedCount(count > 99 ? "99+" : "$count")
                          : showDone
                          ? t.doneTitle
                          : t.todoTitle;

                      return SizedBox(
                        height: 80,
                        child: Row(
                          children: [
                            const SizedBox(width: 4),
                            Text(title, style: TextStyle(fontSize: 32)),
                            const Spacer(),
                            if (selectMode) ...[
                              // select all
                              Material(
                                shape: CircleBorder(),
                                color: Colors.white,
                                child: IconButton(
                                  icon: Icon(
                                    allSelected ? Icons.undo : Icons.done_all,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (allSelected) {
                                        selectedIndex.clear();
                                      } else {
                                        selectedIndex = Set<int>.from(
                                          filteredIndex,
                                        );
                                        selectMode = true;
                                      }
                                    });
                                  },
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // delete
                              Material(
                                shape: const CircleBorder(),
                                color: Colors.white,
                                child: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: selectedIndex.isEmpty
                                      ? null
                                      : () async {
                                          final data =
                                              await TodoStorage.readTodoList();
                                          final List todos = List.from(
                                            data["todos"],
                                          );

                                          //back up deleted cards
                                          final removedItems =
                                              <Map<String, dynamic>>[];
                                          final removedIndexes =
                                              selectedIndex.toList()..sort(
                                                (a, b) => b.compareTo(a),
                                              );

                                          for (final i in removedIndexes) {
                                            removedItems.add(todos[i]);
                                            todos.removeAt(i);
                                          }

                                          // add back to list
                                          await TodoStorage.writeAllTodos(
                                            todos,
                                          );

                                          setState(() {
                                            selectedIndex.clear();
                                            selectMode = false;
                                          });

                                          HapticFeedback.mediumImpact();
                                          await Future.delayed(
                                            const Duration(milliseconds: 80),
                                          );
                                          HapticFeedback.mediumImpact();

                                          // undo
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                              content: Row(
                                                children: [
                                                  Text(
                                                    t.deletedCount(
                                                      "${removedItems.length}",
                                                    ),
                                                  ),
                                                  Spacer(),
                                                  GestureDetector(
                                                    onTap: () async {
                                                      todos.addAll(
                                                        removedItems,
                                                      );
                                                      await TodoStorage.writeAllTodos(
                                                        todos,
                                                      );
                                                      setState(() {});
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).hideCurrentSnackBar();
                                                    },
                                                    child: Text(
                                                      t.undo,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                              const SizedBox(width: 10),

                              //exit select mode
                              Material(
                                shape: const CircleBorder(),
                                color: Colors.white,
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      selectedIndex.clear();
                                      selectMode = false;
                                    });
                                  },
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                            ] else ...[
                              Material(
                                shape: const CircleBorder(),
                                color: Colors.white,
                                child: IconButton(
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      showDone = !showDone;
                                      selectedIndex.clear();
                                      selectMode = false;
                                    });
                                  },
                                  icon: showDone
                                      ? Icon(Icons.check_box_outline_blank)
                                      : Icon(Icons.check_box_outlined),
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                              SizedBox(width: 10),
                              Material(
                                shape: const CircleBorder(),
                                color: Colors.white,
                                child: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  padding: const EdgeInsets.all(12),
                                  onSelected: (value) {
                                    if (value == 'zh')
                                      Taco.of(
                                        context,
                                      ).setLocale(const Locale('zh'));
                                    if (value == 'en')
                                      Taco.of(
                                        context,
                                      ).setLocale(const Locale('en'));
                                    if (value == 'system')
                                      Taco.of(context).setLocale(null);
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'zh',
                                      child: Text('中文'),
                                    ),
                                    PopupMenuItem(
                                      value: 'en',
                                      child: Text('English'),
                                    ),
                                    PopupMenuDivider(),
                                    PopupMenuItem(
                                      value: 'system',
                                      child: Text('Follow system'),
                                    ),
                                  ],
                                  tooltip: "Language",
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 24),
                Expanded(
                  child: FutureBuilder(
                    future: TodoStorage.readTodoList(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return SizedBox();
                      }

                      final List todos = snapshot.data!["todos"];

                      final filteredIndex = _filteredIndex(todos);

                      if (filteredIndex.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.done,
                                size: 72,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                showDone ? t.emptyDone : t.emptyTodo,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredIndex.length,
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            elevation: 8,
                            color: Colors.transparent,
                            shadowColor: Colors.black26,
                            child: child,
                          );
                        },
                        onReorder: (oldPos, newPos) async {
                          if (!selectMode || showDone) return;

                          if (newPos > oldPos) newPos -= 1;

                          final List todosTmp = List.from(todos);

                          final List<int> view = [];
                          for (int i = 0; i < todosTmp.length; i++) {
                            final t = todosTmp[i];
                            final isDone = (t is Map && t["isDone"] == true);
                            if (isDone == showDone) view.add(i);
                          }
                          if (view.isEmpty) return;

                          final moved = view.removeAt(oldPos);
                          view.insert(newPos, moved);

                          final viewSet = view.toSet();
                          int k = 0;
                          final List newTodos = [];
                          for (int i = 0; i < todosTmp.length; i++) {
                            if (viewSet.contains(i)) {
                              newTodos.add(todosTmp[view[k++]]);
                            } else {
                              newTodos.add(todosTmp[i]);
                            }
                          }

                          setState(() {
                            // update to do sequence
                            todos
                              ..clear()
                              ..addAll(newTodos);

                            // synchronize selectedIndex
                            if (selectedIndex.isNotEmpty) {
                              final newSelected = <int>{};

                              for (int i = 0; i < todos.length; i++) {
                                final t = todos[i];
                                if (selectedIndex.any(
                                  (oldIndex) => todosTmp[oldIndex] == t,
                                )) {
                                  newSelected.add(i);
                                }
                              }

                              selectedIndex
                                ..clear()
                                ..addAll(newSelected);
                            }
                          });

                          await TodoStorage.writeAllTodos(newTodos);
                        },

                        itemBuilder: (context, i) {
                          final realIndex = filteredIndex[i];
                          final t = todos[realIndex];

                          final card = todoCard(
                            t["content"],
                            realIndex,
                            disableLongPress: selectMode,
                          );

                          return KeyedSubtree(
                            key: ObjectKey(t),
                            child: selectMode && !showDone
                                ? ReorderableDelayedDragStartListener(
                              index: i,
                              child: card,
                            )
                                : card,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            if (!showDone && !selectMode)
              Positioned(
                bottom: 120,
                right: 50,
                child: Material(
                  color: const Color.fromARGB(255, 40, 110, 240),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () async {
                      final added = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => const AddPage()),
                      );

                      if (added == true) {
                        setState(() {});
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
