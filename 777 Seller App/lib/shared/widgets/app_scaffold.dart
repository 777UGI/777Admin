import 'package:flutter/material.dart';
import '../../core/env_config.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final showTestBanner = EnvConfig.isTestnet;

    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Column(
          children: [
            if (showTestBanner)
              Container(
                width: double.infinity,
                color: const Color(0xFFF9AB00), // Amber warning banner
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                alignment: Alignment.center,
                child: const Text(
                  '⚠ TEST MODE - TESTNET ENV ONLY',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
