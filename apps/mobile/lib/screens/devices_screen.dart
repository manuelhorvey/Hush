import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/identity_service.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final _identity = IdentityService(
    api: ApiClient(baseUrl: 'http://$apiHost:8082'),
  );
  List<DeviceInfo>? _devices;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      final auth = AuthService(
        api: ApiClient(baseUrl: 'http://$apiHost:8081'),
      );
      final session = await auth.getSession();
      if (session == null) return;

      final devices = await _identity.listDevices(session.token);
      if (mounted) {
        setState(() {
          _devices = devices;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Failed to load devices.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Devices'),
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : _devices == null
              ? const Center(child: CircularProgressIndicator())
              : _devices!.isEmpty
                  ? const Center(child: Text('No devices registered.'))
                  : ListView.builder(
                      itemCount: _devices!.length,
                      itemBuilder: (context, index) {
                        final device = _devices![index];
                        return ListTile(
                          leading: const Icon(Icons.devices),
                          title: Text(device.deviceName),
                          subtitle: Text(
                            'Registered: ${device.createdAt}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
    );
  }
}
