import 'dart:async';

/// Fold state enum
enum FoldState {
  flat,
  folded,
  halfOpen,
  unknown,
}

/// Fold state service for detecting foldable device state changes
///
/// This service provides a framework for fold state detection. To enable
/// actual fold detection on Android, you need to implement native platform
/// code using MethodChannel. See README for implementation details.
class FoldStateService {
  final _foldStateController = StreamController<FoldState>.broadcast();
  FoldState _currentState = FoldState.unknown;

  /// Stream of fold state changes
  Stream<FoldState> get foldStateStream => _foldStateController.stream;

  /// Current fold state
  FoldState get currentState => _currentState;

  /// Manual fold state setter for testing or custom implementations
  /// Use this to update fold state from your native platform code
  void updateFoldState(FoldState state) {
    if (state != _currentState) {
      _currentState = state;
      _foldStateController.add(state);
    }
  }

  /// Check if device is currently folded
  bool get isFolded => _currentState == FoldState.folded;

  /// Check if device is currently flat
  bool get isFlat => _currentState == FoldState.flat;

  /// Check if device is currently half open
  bool get isHalfOpen => _currentState == FoldState.halfOpen;

  /// Dispose resources
  void dispose() {
    _foldStateController.close();
  }
}
