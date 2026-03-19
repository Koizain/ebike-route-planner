class BatteryConfig {
  final double capacityWh;
  final double consumptionWhPerKm;

  const BatteryConfig({
    required this.capacityWh,
    required this.consumptionWhPerKm,
  });

  double get rangeKm => capacityWh / consumptionWhPerKm;

  BatteryConfig copyWith({double? capacityWh, double? consumptionWhPerKm}) {
    return BatteryConfig(
      capacityWh: capacityWh ?? this.capacityWh,
      consumptionWhPerKm: consumptionWhPerKm ?? this.consumptionWhPerKm,
    );
  }
}
