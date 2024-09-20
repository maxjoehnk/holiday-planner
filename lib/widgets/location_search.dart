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

  @override
  void initState() {
    super.initState();
    _debouncedSearch = _debounce(_search);
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<LocationEntry>(
      onSelected: (value) => widget.onSelect(value),
      optionsViewBuilder: (context, onSelected, options) {
        return Material(
          elevation: 4.0,
          child: ListView(
            children: options
                .map((option) => ListTile(
                      title: Text(option.name),
                      subtitle: Text(option.country),
                      onTap: () => onSelected(option),
                    ))
                .toList(),
          ),
        );
      },
      optionsBuilder: (value) async {
        var options = await _debouncedSearch(value.text);
        if (options == null) {
          return _options;
        }
        _options = options;
        return options;
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
              labelText: "Location",
              suffixIcon: Icon(Icons.search),
              border: OutlineInputBorder()),
          onSubmitted: (String value) => onFieldSubmitted(),
        );
      },
      displayStringForOption: (option) => option.name,
    );
  }

  Future<Iterable<LocationEntry>?> _search(String query) async {
    _queryInFlight = query;
    var locations = await searchLocations(query: query);

    if (_queryInFlight != query) {
      return null;
    }

    return locations;
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
