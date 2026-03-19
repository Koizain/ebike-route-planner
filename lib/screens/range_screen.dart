import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/battery_config.dart';

class RangeScreen extends StatefulWidget {
  const RangeScreen({super.key});

  @override
  State<RangeScreen> createState() => _RangeScreenState();
}

class _RangeScreenState extends State<RangeScreen> {
  late TextEditingController _capacityCtrl;
  late TextEditingController _consumptionCtrl;

  @override
  void initState() {
    super.initState();
    final config = context.read<AppState>().batteryConfig;
    _capacityCtrl = TextEditingController(text: config.capacityWh.toStringAsFixed(0));
    _consumptionCtrl = TextEditingController(text: config.consumptionWhPerKm.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _capacityCtrl.dispose();
    _consumptionCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final cap = double.tryParse(_capacityCtrl.text);
    final cons = double.tryParse(_consumptionCtrl.text);
    if (cap == null || cap <= 0 || cons == null || cons <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid positive numbers')),
      );
      return;
    }
    context.read<AppState>().updateBatteryConfig(
      BatteryConfig(capacityWh: cap, consumptionWhPerKm: cons),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Battery config saved!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final rangeKm = state.batteryConfig.rangeKm;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Range Estimator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Range summary card
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.battery_charging_full, size: 48, color: Colors.green),
                    const SizedBox(height: 8),
                    Text(
                      '${rangeKm.toStringAsFixed(1)} km',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Text('Estimated Range', style: TextStyle(color: Colors.white60)),
                    const SizedBox(height: 8),
                    Text(
                      'A range circle is shown on the map from your current location',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white38),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Inputs
            Text('Battery Settings', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildField(
              controller: _capacityCtrl,
              label: 'Battery Capacity (Wh)',
              hint: 'e.g. 500',
              icon: Icons.battery_full,
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _consumptionCtrl,
              label: 'Consumption (Wh/km)',
              hint: 'e.g. 15',
              icon: Icons.speed,
            ),
            const SizedBox(height: 8),
            Text(
              'Typical eBike: 10–20 Wh/km depending on terrain, speed, and assist level',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white38),
            ),
            const SizedBox(height: 32),
            // Presets
            Text('Quick Presets', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _preset(context, 'City (250Wh, 12Wh/km)', 250, 12),
                _preset(context, 'Commuter (400Wh, 15Wh/km)', 400, 15),
                _preset(context, 'MTB (625Wh, 20Wh/km)', 625, 20),
                _preset(context, 'Long Range (750Wh, 15Wh/km)', 750, 15),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save & Apply'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: (_) {
        // Live preview update
        final cap = double.tryParse(_capacityCtrl.text);
        final cons = double.tryParse(_consumptionCtrl.text);
        if (cap != null && cap > 0 && cons != null && cons > 0) {
          context.read<AppState>().updateBatteryConfig(
            BatteryConfig(capacityWh: cap, consumptionWhPerKm: cons),
          );
        }
      },
    );
  }

  Widget _preset(BuildContext context, String label, double cap, double cons) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        _capacityCtrl.text = cap.toStringAsFixed(0);
        _consumptionCtrl.text = cons.toStringAsFixed(0);
        context.read<AppState>().updateBatteryConfig(
          BatteryConfig(capacityWh: cap, consumptionWhPerKm: cons),
        );
      },
    );
  }
}
