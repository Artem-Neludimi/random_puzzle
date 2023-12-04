import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

class Game extends StatelessWidget {
  const Game({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GameCubit()..load(),
      child: const Scaffold(
        body: _Body(),
        floatingActionButton: _Floating(),
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

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select((GameCubit cubit) => cubit.state.isLoading);
    final imageBytes = context.select((GameCubit cubit) => cubit.state.imageBytes);

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16.0),
      child: isLoading
          ? const CircularProgressIndicator()
          : Image.memory(
              imageBytes!,
              fit: BoxFit.cover,
            ),
    );
  }
}

class GameCubit extends Cubit<GameState> {
  GameCubit() : super(GameState(isLoading: true));

  Future<void> load() async {
    final response = await http.get(Uri.parse('https://random.imagecdn.app/800/640'));
    emit(state.copyWith(
      imageBytes: response.bodyBytes,
      isLoading: false,
    ));
  }

  Future<void> refresh() async {
    emit(state.copyWith(isLoading: true));
    await load();
  }
}

class GameState {
  GameState({
    required this.isLoading,
    this.imageBytes,
  });

  final bool isLoading;
  final Uint8List? imageBytes;

  GameState copyWith({
    bool? isLoading,
    Uint8List? imageBytes,
  }) {
    return GameState(
      isLoading: isLoading ?? this.isLoading,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }
}
