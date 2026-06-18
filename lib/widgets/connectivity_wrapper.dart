import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../pages/no_internet_screen.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription; // Updated for v5+

  @override
  void initState() {
    super.initState();
    _initConnectivity();

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e) {
      debugPrint('Couldn\'t check connectivity status: $e');
      return;
    }

    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
      
      bool isOnline = result.any((r) => r != ConnectivityResult.none);
      
      setState(() {
        _connectionStatus = isOnline ? ConnectivityResult.wifi : ConnectivityResult.none;
      });
  }
  
  Future<void> _manualCheck() async {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
  }

  @override
  Widget build(BuildContext context) {
    if (_connectionStatus == ConnectivityResult.none) {
      return NoInternetScreen(onRetry: _manualCheck);
    }
    return widget.child;
  }
}
