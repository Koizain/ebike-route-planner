import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/app_state.dart';
import '../models/battery_config.dart';

class _EBikePreset {
  final String name;
  final double capacityWh;
  final double consumptionWhPerKm;

  const _EBikePreset(this.name, this.capacityWh, this.consumptionWhPerKm);
}

const _presets = [
  _EBikePreset('City eBike (36V 10Ah)', 360, 12),
  _EBikePreset('Mountain eBike (36V 15Ah)', 540, 20),
  _EBikePreset('Speed eBike (48V 17.5Ah)', 840, 18),
];

class RangeScreen extends StatefulWidget {
  const RangeScreen({super.key});

  @override
  State<RangeScreen> createState() => _RangeScreenState();
}

class _RangeScreenState extends State<RangeScreen> {
  late TextEditingController _capacityCtrl;
  late TextEditingController _consumptionCtrl;
  String _selectedPreset = 'Custom';

  @override
  void initState() {
    super.initState();
    final config = context.read<AppState>().batteryConfig;
    _capacityCtrl =
        TextEditingController(text: config.capacityWh.toStringAsFixed(0));
    _consumptionCtrl = TextEditingController(
        text: config.consumptionWhPerKm.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _capacityCtrl.dispose();
    _consumptionCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(_EBikePreset preset) {
    setState(() {
      _selectedPreset = preset.name;
      _capacityCtrl.text = preset.capacityWh.toStringAsFixed(0);
      _consumptionCtrl.text = preset.consumptionWhPerKm.toStringAsFixed(0);
    });
    context.read<AppState>().updateBatteryConfig(
          BatteryConfig(
            capacityWh: preset.capacityWh,
            consumptionWhPerKm: preset.consumptionWhPerKm,
          ),
        );
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
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final rangeKm = state.batteryConfig.rangeKm;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.battery_charging_full,
                color: kNightAccent, size: 22),
            const SizedBox(width: 8),
            Text('BATTERY RANGE',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Range summary card
            Container(
              decoration: BoxDecoration(
                color: kNightCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kNightBorder),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 16,
                    color: kNightAccent.withValues(alpha: 0.08),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kNightAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.battery_charging_full,
                        size: 36, color: kNightAccent),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${rangeKm.toStringAsFixed(1)} km',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: kNightAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('ESTIMATED RANGE',
                      style: GoogleFonts.spaceGrotesk(
                        color: kNightTextDim,
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                      )),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kNightBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Range circle shown on map from your location',
                      style: GoogleFonts.spaceGrotesk(
                          color: kNightTextDim, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('EBIKE PRESET',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kNightCyan,
                    letterSpacing: 1.5)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedPreset,
              decoration: InputDecoration(
                filled: true,
                fillColor: kNightCard,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: kNightBorder)),
                prefixIcon:
                    const Icon(Icons.electric_bike, color: kNightAccent),
              ),
              dropdownColor: kNightCard,
              style: GoogleFonts.spaceGrotesk(color: kNightText, fontSize: 14),
              items: [
                ..._presets.map((p) => DropdownMenuItem(
                      value: p.name,
                      child: Text(p.name,
                          style: GoogleFonts.spaceGrotesk(fontSize: 14, color: kNightText)),
                    )),
                DropdownMenuItem(
                  value: 'Custom',
                  child: Text('Custom',
                      style: GoogleFonts.spaceGrotesk(fontSize: 14, color: kNightText)),
                ),
              ],
              onChanged: (val) {
                if (val == 'Custom') {
                  setState(() => _selectedPreset = 'Custom');
                } else {
                  final preset =
                      _presets.firstWhere((p) => p.name == val);
                  _applyPreset(preset);
                }
              },
            ),
            const SizedBox(height: 24),
            Text('BATTERY SETTINGS',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kNightCyan,
                    letterSpacing: 1.5)),
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
              'Typical eBike: 10-20 Wh/km depending on terrain, speed, and assist level',
              style: GoogleFonts.spaceGrotesk(
                  color: kNightTextDim, fontSize: 12),
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
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.spaceGrotesk(color: kNightText),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: kNightAccent),
        filled: true,
        fillColor: kNightCard,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kNightBorder)),
      ),
      onChanged: (_) {
        setState(() => _selectedPreset = 'Custom');
        final cap = double.tryParse(_capacityCtrl.text);
        final cons = double.tryParse(_consumptionCtrl.text);
        if (cap != null && cap > 0 && cons != null && cons > 0) {
          context.read<AppState>().updateBatteryConfig(
                BatteryConfig(
                    capacityWh: cap, consumptionWhPerKm: cons),
              );
        }
      },
    );
  }
}
