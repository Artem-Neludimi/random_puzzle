import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class Game extends StatelessWidget {
  const Game({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GameCubit(),
      child: Scaffold(
        body: BlocListener<GameCubit, GameState>(
          listenWhen: (previous, current) => current.isWon,
          listener: (context, state) {
            showDialog(
              context: context,
              builder: (_) => const Dialog(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 100,
                      child: Center(
                        child: Text('You won!'),
                      ),
                    ),
                  ],
                ),
              ),
            ).then((value) => context.read<GameCubit>().refresh());
          },
          child: const _Body(),
        ),
        floatingActionButton: const _Floating(),
      ),
    );
  }
}

class _Floating extends StatelessWidget {
  const _Floating();

  @override
  Widget build(BuildContext context) {
    final imageBytes = context.select((GameCubit cubit) => cubit.state.imageBytes);
    final isLoading = context.select((GameCubit cubit) => cubit.state.isLoading);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: () {
            if (imageBytes == null) return;
            if (isLoading) return;

            showDialog(
              context: context,
              builder: (_) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.memory(imageBytes),
                  ],
                ),
              ),
            );
          },
          child: const Icon(Icons.image),
        ),
        const SizedBox(height: 4),
        FloatingActionButton(
          onPressed: context.read<GameCubit>().refresh,
          child: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  @override
  void initState() {
    super.initState();
    context.read<GameCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select((GameCubit cubit) => cubit.state.isLoading);

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16.0),
      child: isLoading
          ? const CircularProgressIndicator()
          : const AspectRatio(
              aspectRatio: 5 / 4,
              child: _Puzzle(),
            ),
    );
  }
}

class _Puzzle extends StatelessWidget {
  const _Puzzle();
  @override
  Widget build(BuildContext context) {
    final read = context.read<GameCubit>();
    final randomPuzzleIndexes = context.select((GameCubit cubit) => cubit.state.randomPuzzleIndexes);
    final dragKey = context.select((GameCubit cubit) => cubit.state.dragKey);
    final imageBytes = context.select((GameCubit cubit) => cubit.state.imageBytes);

    return LayoutBuilder(builder: (context, constraints) {
      final puzzleItem = [
        _PuzzleItem(key: const ValueKey(0), const Alignment(-1, -1), constraints, imageBytes!),
        _PuzzleItem(key: const ValueKey(1), const Alignment(-0.5, -1), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(2), const Alignment(0, -1), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(3), const Alignment(0.5, -1), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(4), const Alignment(1, -1), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(5), const Alignment(-1, -0.5), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(6), const Alignment(-0.5, -0.5), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(7), const Alignment(0, -0.5), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(8), const Alignment(0.5, -0.5), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(9), const Alignment(1, -0.5), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(10), const Alignment(-1, 0), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(11), const Alignment(-0.5, 0), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(12), const Alignment(0, 0), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(13), const Alignment(0.5, 0), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(14), const Alignment(1, 0), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(15), const Alignment(-1, 0.5), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(16), const Alignment(-0.5, 0.5), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(17), const Alignment(0, 0.5), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(18), const Alignment(0.5, 0.5), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(19), const Alignment(1, 0.5), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(20), const Alignment(-1, 1), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(21), const Alignment(-0.5, 1), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(22), const Alignment(0, 1), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(23), const Alignment(0.5, 1), constraints, imageBytes),
        _PuzzleItem(key: const ValueKey(24), const Alignment(1, 1), constraints, imageBytes),
      ];

      return GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 5,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
        childAspectRatio: (constraints.maxWidth - 12) / (constraints.maxHeight - 12),
        children: List.generate(
          randomPuzzleIndexes.length,
          (index) {
            final item = puzzleItem[randomPuzzleIndexes[index]];
            return Draggable(
              onDragUpdate: (details) {
                read.startDrag((item.key as ValueKey<int>).value, index, details.globalPosition);
                read.swapPuzzles(details.globalPosition);
              },
              onDragEnd: (details) {
                read.stopDrag();
              },
              feedback: SizedBox(
                height: (constraints.maxHeight - 12) / 5,
                width: (constraints.maxWidth - 12) / 5,
                child: item,
              ),
              childWhenDragging: item.key == ValueKey(dragKey) ? const SizedBox() : item,
              child: item.key == ValueKey(dragKey) ? const SizedBox() : item,
            );
          },
        ),
      );
    });
  }
}

class _PuzzleItem extends StatelessWidget {
  const _PuzzleItem(this.alignment, this.constraints, this.imageBytes, {super.key});

  final Alignment alignment;
  final BoxConstraints constraints;
  final Uint8List imageBytes;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(boxShadow: [
        BoxShadow(
          color: Colors.white,
          blurRadius: 0.1,
          offset: Offset(0.1, 0.1),
        ),
      ]),
      child: ClipRect(
        child: OverflowBox(
          alignment: alignment,
          maxHeight: constraints.maxHeight,
          maxWidth: constraints.maxWidth,
          child: Image.memory(
            imageBytes,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class GameCubit extends Cubit<GameState> {
  GameCubit() : super(GameState(isLoading: true, randomPuzzleIndexes: List.generate(25, (index) => index)..shuffle()));

  Future<void> load() async {
    try {
      final response = await http.get(Uri.parse('https://picsum.photos/800/640'));
      emit(state.copyWith(
        imageBytes: response.bodyBytes,
        isLoading: false,
      ));
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
      load();
    }
  }

  Future<void> refresh() async {
    emit(state.copyWith(
      isLoading: true,
      randomPuzzleIndexes: List.generate(25, (index) => index)..shuffle(),
      isDragging: false,
      didSwap: false,
      dragKey: -1,
      isWon: false,
    ));
    await load();
  }

  void startDrag(int key, int dragIndex, Offset startDragOffset) {
    if (state.isDragging) return;
    emit(state.copyWith(
      isDragging: true,
      randomPuzzleIndexesBeforeSwapping: state.randomPuzzleIndexes,
      dragKey: key,
      dragIndex: dragIndex,
      startDragOffset: startDragOffset,
    ));
  }

  void stopDrag() {
    emit(state.copyWith(
      isDragging: false,
      didSwap: false,
      dragKey: -1,
      dragIndex: -1,
      startDragOffset: Offset.zero,
    ));
    _checkCompleted();
  }

  void swapPuzzles(Offset currentOffset) {
    final currentDragPuzzleIndex = _findIndexByOffset(currentOffset);
    if (currentDragPuzzleIndex < 0) return;

    if (!state.didSwap && _buildAvailableDraggingIndexes(state.dragIndex).contains(currentDragPuzzleIndex)) {
      final newRandomList = [...state.randomPuzzleIndexes]..swap(state.dragIndex, currentDragPuzzleIndex);
      if (const ListEquality().equals(newRandomList, state.randomPuzzleIndexes) == false) {
        emit(state.copyWith(
          randomPuzzleIndexes: newRandomList,
          didSwap: true,
        ));
      }
    } else if (currentDragPuzzleIndex == state.dragIndex) {
      emit(state.copyWith(
        randomPuzzleIndexes: state.randomPuzzleIndexesBeforeSwapping,
        didSwap: false,
      ));
    }
  }

  void _checkCompleted() {
    if (const ListEquality().equals(state.randomPuzzleIndexes, List.generate(25, (index) => index))) {
      emit(state.copyWith(isWon: true));
    }
  }

  List<int> _buildAvailableDraggingIndexes(int index) {
    return switch (index) {
      0 => [1, 5],
      1 => [0, 2, 6],
      2 => [1, 3, 7],
      3 => [2, 4, 8],
      4 => [3, 9],
      5 => [0, 6, 10],
      6 => [1, 5, 7, 11],
      7 => [2, 6, 8, 12],
      8 => [3, 7, 9, 13],
      9 => [4, 8, 14],
      10 => [5, 11, 15],
      11 => [6, 10, 12, 16],
      12 => [7, 11, 13, 17],
      13 => [8, 12, 14, 18],
      14 => [9, 13, 19],
      15 => [10, 16, 20],
      16 => [11, 15, 17, 21],
      17 => [12, 16, 18, 22],
      18 => [13, 17, 19, 23],
      19 => [14, 18, 24],
      20 => [15, 21],
      21 => [16, 20, 22],
      22 => [17, 21, 23],
      23 => [18, 22, 24],
      24 => [19, 23],
      _ => [],
    };
  }

  int _findIndexByOffset(Offset offset) {
    final initialOffset = state.startDragOffset;
    final dragIndex = state.dragIndex;
    if (dragIndex < 0) return -1;

    if (offset.dx < initialOffset.dx + 60 &&
        offset.dx > initialOffset.dx - 60 &&
        offset.dy < initialOffset.dy + 40 &&
        offset.dy > initialOffset.dy - 40) return dragIndex;

    if (offset.dx > initialOffset.dx + 60) return dragIndex + 1;
    if (offset.dx < initialOffset.dx - 60) return dragIndex - 1;
    if (offset.dy > initialOffset.dy + 40) return dragIndex + 5;
    if (offset.dy < initialOffset.dy - 40) return dragIndex - 5;
    return -1;
  }
}

class GameState {
  GameState({
    required this.isLoading,
    this.imageBytes,
    required this.randomPuzzleIndexes,
    this.randomPuzzleIndexesBeforeSwapping = const [],
    this.isDragging = false,
    this.didSwap = false,
    this.dragKey = -1,
    this.dragIndex = -1,
    this.startDragOffset = Offset.zero,
    this.isWon = false,
  });

  final bool isLoading;
  final Uint8List? imageBytes;
  final List<int> randomPuzzleIndexes;
  final List<int> randomPuzzleIndexesBeforeSwapping;
  final bool isDragging;
  final bool didSwap;
  final int dragKey;
  final int dragIndex;
  final Offset startDragOffset;
  final bool isWon;

  GameState copyWith({
    bool? isLoading,
    Uint8List? imageBytes,
    List<int>? randomPuzzleIndexes,
    List<int>? randomPuzzleIndexesBeforeSwapping,
    bool? isDragging,
    bool? didSwap,
    int? dragKey,
    int? dragIndex,
    Offset? startDragOffset,
    bool? isWon,
  }) {
    return GameState(
      isLoading: isLoading ?? this.isLoading,
      imageBytes: imageBytes ?? this.imageBytes,
      randomPuzzleIndexes: randomPuzzleIndexes ?? this.randomPuzzleIndexes,
      randomPuzzleIndexesBeforeSwapping: randomPuzzleIndexesBeforeSwapping ?? this.randomPuzzleIndexesBeforeSwapping,
      isDragging: isDragging ?? this.isDragging,
      didSwap: didSwap ?? this.didSwap,
      dragKey: dragKey ?? this.dragKey,
      dragIndex: dragIndex ?? this.dragIndex,
      startDragOffset: startDragOffset ?? this.startDragOffset,
      isWon: isWon ?? this.isWon,
    );
  }
}
