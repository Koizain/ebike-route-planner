import 'dart:math';
import 'package:flutter/material.dart';
import '../models/route_point.dart';

class ElevationChart extends StatelessWidget {
  final ElevationProfile profile;
  final double? trackingProgressKm;

  const ElevationChart({
    super.key,
    required this.profile,
    this.trackingProgressKm,
  });

  @override
  Widget build(BuildContext context) {
    if (profile.elevations.length < 2) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.terrain, size: 18, color: Color(0xFF00E676)),
            const SizedBox(width: 8),
            const Text(
              'Elevation Profile',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Text(
              '${profile.distances.last.toStringAsFixed(1)} km',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: CustomPaint(
            size: Size.infinite,
            painter: _ElevationPainter(
              profile: profile,
              trackingProgressKm: trackingProgressKm,
            ),
          ),
        ),
        const SizedBox(height: 4),
        _buildAxisLabels(),
      ],
    );
  }

  Widget _buildAxisLabels() {
    final maxDist = profile.distances.last;
    final labels = <double>[];
    if (maxDist <= 5) {
      for (double d = 0; d <= maxDist; d += 1) {
        labels.add(d);
      }
    } else if (maxDist <= 20) {
      for (double d = 0; d <= maxDist; d += 5) {
        labels.add(d);
      }
    } else {
      for (double d = 0; d <= maxDist; d += 10) {
        labels.add(d);
      }
    }
    if (labels.isEmpty || labels.last < maxDist * 0.9) {
      labels.add(maxDist);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels
          .map((d) => Text(
                '${d.toStringAsFixed(d == d.roundToDouble() ? 0 : 1)} km',
                style: const TextStyle(fontSize: 10, color: Colors.white38),
              ))
          .toList(),
    );
  }
}

class _ElevationPainter extends CustomPainter {
  final ElevationProfile profile;
  final double? trackingProgressKm;

  _ElevationPainter({required this.profile, this.trackingProgressKm});

  @override
  void paint(Canvas canvas, Size size) {
    if (profile.elevations.length < 2) return;

    final elevations = profile.elevations;
    final distances = profile.distances;
    final maxDist = distances.last;
    final minElev = elevations.reduce(min) - 5;
    final maxElev = elevations.reduce(max) + 5;
    final elevRange = maxElev - minElev;
    if (elevRange == 0 || maxDist == 0) return;

    final padding = const EdgeInsets.only(left: 30, right: 8, top: 8, bottom: 4);
    final chartW = size.width - padding.left - padding.right;
    final chartH = size.height - padding.top - padding.bottom;

    double toX(double dist) => padding.left + (dist / maxDist) * chartW;
    double toY(double elev) =>
        padding.top + chartH - ((elev - minElev) / elevRange) * chartH;

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;

    final gridCount = 4;
    for (int i = 0; i <= gridCount; i++) {
      final y = padding.top + (chartH / gridCount) * i;
      canvas.drawLine(Offset(padding.left, y), Offset(size.width - padding.right, y), gridPaint);

      final elev = maxElev - (elevRange / gridCount) * i;
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${elev.toStringAsFixed(0)}m',
          style: const TextStyle(fontSize: 9, color: Colors.white38),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    // Build path
    final path = Path();
    path.moveTo(toX(distances[0]), toY(elevations[0]));
    for (int i = 1; i < elevations.length; i++) {
      path.lineTo(toX(distances[i]), toY(elevations[i]));
    }

    // Fill path
    final fillPath = Path.from(path);
    fillPath.lineTo(toX(distances.last), padding.top + chartH);
    fillPath.lineTo(toX(distances.first), padding.top + chartH);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00E676).withValues(alpha: 0.4),
          const Color(0xFF00E676).withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, padding.top, size.width, chartH));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = const Color(0xFF00E676)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // Tracking position marker
    if (trackingProgressKm != null && trackingProgressKm! > 0) {
      final progress = trackingProgressKm!.clamp(0.0, maxDist);
      int idx = 0;
      for (int i = 0; i < distances.length - 1; i++) {
        if (distances[i + 1] >= progress) {
          idx = i;
          break;
        }
      }
      final t = (distances[idx + 1] - distances[idx]) > 0
          ? (progress - distances[idx]) / (distances[idx + 1] - distances[idx])
          : 0.0;
      final elev = elevations[idx] + (elevations[idx + 1] - elevations[idx]) * t;
      final cx = toX(progress);
      final cy = toY(elev);

      canvas.drawCircle(
        Offset(cx, cy),
        5,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        3.5,
        Paint()..color = const Color(0xFF00E676),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ElevationPainter oldDelegate) =>
      oldDelegate.profile != profile ||
      oldDelegate.trackingProgressKm != trackingProgressKm;
}
