import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/route_point.dart';
import '../services/app_state.dart';
import '../services/geocoding_service.dart';

class RouteSearchBar extends StatefulWidget {
  const RouteSearchBar({super.key});

  @override
  State<RouteSearchBar> createState() => _RouteSearchBarState();
}

class _RouteSearchBarState extends State<RouteSearchBar> {
  final _geocoding = GeocodingService();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _fromFocus = FocusNode();
  final _toFocus = FocusNode();

  Timer? _debounce;
  List<SearchResult> _fromResults = [];
  List<SearchResult> _toResults = [];
  List<SearchResult> _recentSearches = [];
  bool _showFromResults = false;
  bool _showToResults = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _fromFocus.addListener(() {
      if (!_fromFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showFromResults = false);
        });
      }
    });
    _toFocus.addListener(() {
      if (!_toFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showToResults = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('recent_searches') ?? [];
    setState(() {
      _recentSearches = raw
          .map((s) =>
              SearchResult.fromJson(json.decode(s) as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> _addRecentSearch(SearchResult result) async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.removeWhere((r) => r.name == result.name);
    _recentSearches.insert(0, result);
    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.sublist(0, 5);
    }
    final raw =
        _recentSearches.map((r) => json.encode(r.toJson())).toList();
    await prefs.setStringList('recent_searches', raw);
  }

  void _onFromChanged(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        _fromResults = _recentSearches;
        _showFromResults = _recentSearches.isNotEmpty;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await _geocoding.searchAddress(query);
      if (mounted) {
        setState(() {
          _fromResults = results;
          _showFromResults = results.isNotEmpty;
        });
      }
    });
  }

  void _onToChanged(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        _toResults = _recentSearches;
        _showToResults = _recentSearches.isNotEmpty;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await _geocoding.searchAddress(query);
      if (mounted) {
        setState(() {
          _toResults = results;
          _showToResults = results.isNotEmpty;
        });
      }
    });
  }

  void _selectFromResult(SearchResult result) {
    _fromController.text = _shortName(result.name);
    setState(() => _showFromResults = false);
    _fromFocus.unfocus();
    _addRecentSearch(result);
    final state = context.read<AppState>();
    state.setStartPoint(result.latLng);
  }

  void _selectToResult(SearchResult result) {
    _toController.text = _shortName(result.name);
    setState(() => _showToResults = false);
    _toFocus.unfocus();
    _addRecentSearch(result);
    final state = context.read<AppState>();
    state.setEndPoint(result.latLng);
  }

  void _useMyLocation() {
    final state = context.read<AppState>();
    if (state.currentLocation != null) {
      _fromController.text = 'My Location';
      state.setStartPoint(state.currentLocation!);
    } else {
      state.fetchCurrentLocation().then((_) {
        if (state.currentLocation != null) {
          _fromController.text = 'My Location';
          state.setStartPoint(state.currentLocation!);
        }
      });
    }
  }

  void _swapStartEnd() {
    final state = context.read<AppState>();
    final tmpText = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = tmpText;
    state.swapStartEnd();
  }

  String _shortName(String name) {
    final parts = name.split(',');
    return parts.length > 2
        ? '${parts[0].trim()}, ${parts[1].trim()}'
        : name;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search bar with glassmorphism
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: kNavyDark.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 16,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // From field
                    Row(
                      children: [
                        const SizedBox(width: 14),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: kAccentGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: kAccentGreen.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _fromController,
                            focusNode: _fromFocus,
                            onChanged: _onFromChanged,
                            onTap: () {
                              if (_fromController.text.isEmpty) {
                                setState(() {
                                  _fromResults = _recentSearches;
                                  _showFromResults =
                                      _recentSearches.isNotEmpty;
                                });
                              }
                            },
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Start location',
                              hintStyle: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.35),
                                  fontSize: 14),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_fromController.text.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        _fromController.clear();
                                        setState(
                                            () => _showFromResults = false);
                                      },
                                      child: const Icon(Icons.close,
                                          size: 18, color: Colors.white38),
                                    ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: _useMyLocation,
                                    child: Icon(Icons.my_location,
                                        size: 18, color: kAccentBlue),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Divider with swap button
                    Row(
                      children: [
                        const SizedBox(width: 34),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        GestureDetector(
                          onTap: _swapStartEnd,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.swap_vert,
                                size: 20, color: Colors.white54),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                    // To field
                    Row(
                      children: [
                        const SizedBox(width: 14),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: kAccentBlue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: kAccentBlue.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _toController,
                            focusNode: _toFocus,
                            onChanged: _onToChanged,
                            onTap: () {
                              if (_toController.text.isEmpty) {
                                setState(() {
                                  _toResults = _recentSearches;
                                  _showToResults =
                                      _recentSearches.isNotEmpty;
                                });
                              }
                            },
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Destination',
                              hintStyle: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.35),
                                  fontSize: 14),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              suffixIcon: _toController.text.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _toController.clear();
                                        setState(
                                            () => _showToResults = false);
                                      },
                                      child: const Icon(Icons.close,
                                          size: 18, color: Colors.white38),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Route type selector
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Row(
                        children: [
                          _routeTypeButton(
                            icon: Icons.pedal_bike,
                            label: 'Bike',
                            type: RouteType.bike,
                            current: state.routeType,
                          ),
                          const SizedBox(width: 6),
                          _routeTypeButton(
                            icon: Icons.electric_bike,
                            label: 'eBike',
                            type: RouteType.ebike,
                            current: state.routeType,
                          ),
                          const SizedBox(width: 6),
                          _routeTypeButton(
                            icon: Icons.terrain,
                            label: 'MTB',
                            type: RouteType.mountain,
                            current: state.routeType,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // From results dropdown
        if (_showFromResults && _fromResults.isNotEmpty)
          _buildResultsList(_fromResults, _selectFromResult),
        // To results dropdown
        if (_showToResults && _toResults.isNotEmpty)
          _buildResultsList(_toResults, _selectToResult),
      ],
    );
  }

  Widget _routeTypeButton({
    required IconData icon,
    required String label,
    required RouteType type,
    required RouteType current,
  }) {
    final selected = type == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<AppState>().setRouteType(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? kAccentGreen.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? kAccentGreen.withValues(alpha: 0.6)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? kAccentGreen : Colors.white54),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? kAccentGreen : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(
      List<SearchResult> results, void Function(SearchResult) onSelect) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 0),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: kNavyMid.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
              blurRadius: 12,
              color: Colors.black.withValues(alpha: 0.4)),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: results.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, indent: 40, color: Colors.white.withValues(alpha: 0.06)),
        itemBuilder: (context, index) {
          final result = results[index];
          return ListTile(
            dense: true,
            leading: Icon(Icons.place, size: 18, color: kAccentGreen.withValues(alpha: 0.6)),
            title: Text(
              _shortName(result.name),
              style: const TextStyle(fontSize: 13, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              result.name,
              style:
                  TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => onSelect(result),
          );
        },
      ),
    );
  }
}
