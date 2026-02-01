import 'dart:async';

import '../../utils/app_logger.dart';
import '../models/sync_message.dart';

/// Error types that can occur in the peer service
enum PeerErrorType { connectionFailed, peerDisconnected, dataChannelError, serverError, timeout, unknown }

/// Represents an error in the peer service
class PeerError {
  final PeerErrorType type;
  final String message;
  final dynamic originalError;

  const PeerError({required this.type, required this.message, this.originalError});

  @override
  String toString() => 'PeerError($type): $message';
}

/// STUB: Watch Together is not available on Windows ARM64.
///
/// This is a stub implementation that throws [UnsupportedError] for all operations.
/// The flutter_webrtc package does not have ARM64 Windows binaries.
///
/// To restore full functionality, use an x64 build or wait for ARM64 support.
class WatchTogetherPeerService {
  // Stream controllers (empty, never emit)
  final _peerConnectedController = StreamController<String>.broadcast();
  final _peerDisconnectedController = StreamController<String>.broadcast();
  final _messageReceivedController = StreamController<SyncMessage>.broadcast();
  final _errorController = StreamController<PeerError>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  Stream<String> get onPeerConnected => _peerConnectedController.stream;
  Stream<String> get onPeerDisconnected => _peerDisconnectedController.stream;
  Stream<SyncMessage> get onMessageReceived => _messageReceivedController.stream;
  Stream<PeerError> get onError => _errorController.stream;
  Stream<bool> get onConnectionStateChanged => _connectionStateController.stream;

  String? get sessionId => null;
  String? get myPeerId => null;
  bool get isHost => false;
  bool get isConnected => false;
  List<String> get connectedPeers => [];

  static const String _unsupportedMessage =
      'Watch Together is not available on Windows ARM64. '
      'The flutter_webrtc package does not have ARM64 Windows binaries.';

  /// Creates a new session - NOT SUPPORTED on ARM64
  Future<String> createSession() async {
    appLogger.w('WatchTogetherPeerService.createSession() called on unsupported platform');
    _errorController.add(const PeerError(type: PeerErrorType.unknown, message: _unsupportedMessage));
    throw UnsupportedError(_unsupportedMessage);
  }

  /// Joins an existing session - NOT SUPPORTED on ARM64
  Future<void> joinSession(String sessionId) async {
    appLogger.w('WatchTogetherPeerService.joinSession() called on unsupported platform');
    _errorController.add(const PeerError(type: PeerErrorType.unknown, message: _unsupportedMessage));
    throw UnsupportedError(_unsupportedMessage);
  }

  /// Broadcast a message to all connected peers - NOT SUPPORTED on ARM64
  void broadcast(SyncMessage message) {
    appLogger.w('WatchTogetherPeerService.broadcast() called on unsupported platform');
    // No-op since we never have connections
  }

  /// Send a message to a specific peer - NOT SUPPORTED on ARM64
  void sendTo(String peerId, SyncMessage message) {
    appLogger.w('WatchTogetherPeerService.sendTo() called on unsupported platform');
    // No-op since we never have connections
  }

  /// Send a sync message (legacy method) - NOT SUPPORTED on ARM64
  void sendMessage(SyncMessage message) {
    appLogger.w('WatchTogetherPeerService.sendMessage() called on unsupported platform');
    // No-op since we never have connections
  }

  /// Disconnect from all peers and close the session
  Future<void> disconnect() async {
    appLogger.d('WatchTogetherPeerService.disconnect() called (no-op on ARM64)');
    // No-op since we're never connected
  }

  /// Leave the current session (alias for disconnect)
  Future<void> leaveSession() async {
    await disconnect();
  }

  /// Dispose resources
  void dispose() {
    _peerConnectedController.close();
    _peerDisconnectedController.close();
    _messageReceivedController.close();
    _errorController.close();
    _connectionStateController.close();
  }
}
