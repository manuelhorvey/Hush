import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_state.dart';
import '../../domain/entities/device_identity.dart';
import '../../domain/repositories/device_repository.dart';
import 'auth_state_provider.dart';

/// State holder for device identity management.
class DeviceIdentityState {
  final List<DeviceIdentity> devices;
  final bool loading;
  final String? error;

  const DeviceIdentityState({
    this.devices = const [],
    this.loading = false,
    this.error,
  });

  DeviceIdentityState copyWith({
    List<DeviceIdentity>? devices,
    bool? loading,
    String? error,
  }) {
    return DeviceIdentityState(
      devices: devices ?? this.devices,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

/// Notifier for device identity management.
class DeviceIdentityNotifier extends Notifier<DeviceIdentityState> {
  @override
  DeviceIdentityState build() => const DeviceIdentityState();

  DeviceRepository get _repo => ref.read(deviceRepositoryProvider);

  /// Load all devices for the current user.
  Future<void> loadDevices() async {
    final token = _getToken();
    if (token == null) return;

    state = state.copyWith(loading: true);
    try {
      final devices = await _repo.listDevices(token: token);
      state = state.copyWith(devices: devices, loading: false, error: null);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Unable to load devices. Please try again.',
      );
    }
  }

  /// Register the current device.
  Future<DeviceIdentity> registerDevice({
    required String deviceName,
    required String publicKey,
  }) async {
    final token = _getToken();
    if (token == null) throw Exception('Not authenticated');

    state = state.copyWith(loading: true);
    try {
      final device = await _repo.registerDevice(
        token: token,
        deviceName: deviceName,
        publicKey: publicKey,
      );
      state = state.copyWith(
        devices: [device, ...state.devices],
        loading: false,
        error: null,
      );
      return device;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Unable to register device. Please try again.',
      );
      rethrow;
    }
  }

  /// Store the exchange key for the current device.
  Future<void> storeExchangeKey(String x25519PublicKey) async {
    final token = _getToken();
    if (token == null) throw Exception('Not authenticated');

    await _repo.storeExchangeKey(token: token, x25519PublicKey: x25519PublicKey);
  }

  /// Remove a device by ID.
  Future<void> removeDevice(String deviceId) async {
    final token = _getToken();
    if (token == null) throw Exception('Not authenticated');

    try {
      await _repo.removeDevice(token: token, deviceId: deviceId);
      state = state.copyWith(
        devices: state.devices.where((d) => d.deviceId != deviceId).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Unable to remove device. Please try again.',
      );
    }
  }

  String? _getToken() {
    final authState = ref.read(domainAuthStateProvider);
    if (authState is AuthAuthenticated) return authState.token;
    return null;
  }
}

final deviceIdentityProvider =
    NotifierProvider<DeviceIdentityNotifier, DeviceIdentityState>(
  DeviceIdentityNotifier.new,
);
