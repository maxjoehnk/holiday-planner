import 'dart:async';

import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/models.dart';

const Duration debounceDuration = Duration(milliseconds: 500);

class LocationSearch extends StatefulWidget {
  final Function(LocationEntry) onSelect;

  const LocationSearch({super.key, required this.onSelect});

  @override
  State<LocationSearch> createState() => _LocationSearchState();
}

class _LocationSearchState extends State<LocationSearch> {
  String? _queryInFlight;
  late Iterable<LocationEntry> _options = [];
  late final _Debounceable<Iterable<LocationEntry>?, String> _debouncedSearch;
  bool _isLoading = false;
  String? _errorMessage;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _debouncedSearch = _debounce(_search);
  }

  @override
  void dispose() {
    // Cancel any in-flight queries to prevent setState after dispose
    _queryInFlight = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<LocationEntry>(
          onSelected: (value) {
            if (mounted) {
              setState(() {
                _errorMessage = null;
              });
            }
            widget.onSelect(value);
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Material(
              elevation: 0,
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surface,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: _buildOptionsView(context, onSelected, options),
              ),
            );
          },
          optionsBuilder: (value) async {
            if (value.text.isEmpty) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = null;
                });
              }
              return const Iterable<LocationEntry>.empty();
            }
            
            if (value.text != _lastQuery) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                  _lastQuery = value.text;
                });
              }
            }
            
            var options = await _debouncedSearch(value.text);
            
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            
            if (options == null) {
              return _options;
            }
            _options = options;
            return options;
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: "Search Location",
                hintText: "Enter city or country name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              onFieldSubmitted: (String value) => onFieldSubmitted(),
            );
          },
          displayStringForOption: (option) => "${option.name}, ${option.country}",
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: colorScheme.onErrorContainer,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionsView(
    BuildContext context,
    Function(LocationEntry) onSelected,
    Iterable<LocationEntry> options,
  ) {
    var colorScheme = Theme.of(context).colorScheme;
    var textTheme = Theme.of(context).textTheme;
    
    if (_isLoading) {
      return Container(
        height: 100,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Searching locations...",
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    
    if (options.isEmpty && _lastQuery.isNotEmpty && !_isLoading) {
      return Container(
        height: 100,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 32,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              "No locations found",
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Try a different search term",
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      itemCount: options.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        var option = options.elementAt(index);
        return InkWell(
          onTap: () => onSelected(option),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on,
                    size: 16,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.country,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Iterable<LocationEntry>?> _search(String query) async {
    _queryInFlight = query;
    
    try {
      var locations = await searchLocations(query: query);

      if (_queryInFlight != query) {
        return null;
      }

      // Clear any previous error on successful search
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }

      return locations;
    } catch (e) {
      if (_queryInFlight != query) {
        return null;
      }

      // Report error back to user
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to search locations: ${e.toString()}";
        });
      }

      // Return empty results on error
      return const Iterable<LocationEntry>.empty();
    }
  }
}

typedef _Debounceable<S, T> = Future<S?> Function(T parameter);

/// Returns a new function that is a debounced version of the given function.
///
/// This means that the original function will be called only after no calls
/// have been made for the given Duration.
_Debounceable<S, T> _debounce<S, T>(_Debounceable<S?, T> function) {
  _DebounceTimer? debounceTimer;

  return (T parameter) async {
    if (debounceTimer != null && !debounceTimer!.isCompleted) {
      debounceTimer!.cancel();
    }
    debounceTimer = _DebounceTimer();
    try {
      await debounceTimer!.future;
    } catch (error) {
      if (error is _CancelException) {
        return null;
      }
      rethrow;
    }
    return function(parameter);
  };
}

// A wrapper around Timer used for debouncing.
class _DebounceTimer {
  _DebounceTimer() {
    _timer = Timer(debounceDuration, _onComplete);
  }

  late final Timer _timer;
  final Completer<void> _completer = Completer<void>();

  void _onComplete() {
    _completer.complete();
  }

  Future<void> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;

  void cancel() {
    _timer.cancel();
    _completer.completeError(const _CancelException());
  }
}

// An exception indicating that the timer was canceled.
class _CancelException implements Exception {
  const _CancelException();
}
