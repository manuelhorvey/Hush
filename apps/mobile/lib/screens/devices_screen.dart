import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/identity_service.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  List<DeviceInfo>? _devices;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDevices());
  }

  Future<void> _loadDevices() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      final identity = context.read<IdentityService>();
      final devices = await identity.listDevices(token);
      if (mounted) setState(() => _devices = devices);
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to load devices.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Devices')),
      body: _error != null
          ? Center(child: Text(_error!))
          : _devices == null
              ? const Center(child: CircularProgressIndicator())
              : _devices!.isEmpty
                  ? const Center(child: Text('No devices registered.'))
                  : ListView.builder(
                      itemCount: _devices!.length,
                      itemBuilder: (context, i) {
                        final device = _devices![i];
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
