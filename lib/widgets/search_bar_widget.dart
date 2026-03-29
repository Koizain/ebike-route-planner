import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHigh
                .withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  blurRadius: 8,
                  color: Colors.black.withValues(alpha: 0.3)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // From field
              Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.circle_outlined,
                      size: 14, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _fromController,
                      focusNode: _fromFocus,
                      onChanged: _onFromChanged,
                      onTap: () {
                        if (_fromController.text.isEmpty) {
                          setState(() {
                            _fromResults = _recentSearches;
                            _showFromResults = _recentSearches.isNotEmpty;
                          });
                        }
                      },
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'From',
                        hintStyle: const TextStyle(
                            color: Colors.white38, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_fromController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _fromController.clear();
                                  setState(() => _showFromResults = false);
                                },
                                child: const Icon(Icons.close,
                                    size: 18, color: Colors.white38),
                              ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: _useMyLocation,
                              child: const Icon(Icons.my_location,
                                  size: 18, color: Colors.blue),
                            ),
                            const SizedBox(width: 8),
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
                      color: Colors.white12,
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
                  const SizedBox(width: 8),
                ],
              ),
              // To field
              Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.location_on,
                      size: 14, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _toController,
                      focusNode: _toFocus,
                      onChanged: _onToChanged,
                      onTap: () {
                        if (_toController.text.isEmpty) {
                          setState(() {
                            _toResults = _recentSearches;
                            _showToResults = _recentSearches.isNotEmpty;
                          });
                        }
                      },
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'To',
                        hintStyle: const TextStyle(
                            color: Colors.white38, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        suffixIcon: _toController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _toController.clear();
                                  setState(() => _showToResults = false);
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
            ],
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

  Widget _buildResultsList(
      List<SearchResult> results, void Function(SearchResult) onSelect) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 0),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHigh
            .withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              blurRadius: 8,
              color: Colors.black.withValues(alpha: 0.3)),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: results.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 40),
        itemBuilder: (context, index) {
          final result = results[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.place, size: 18, color: Colors.white38),
            title: Text(
              _shortName(result.name),
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              result.name,
              style:
                  const TextStyle(fontSize: 11, color: Colors.white30),
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
