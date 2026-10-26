import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class AttendXApp extends ConsumerWidget {
  const AttendXApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'AttendX — Smart College Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // On wide desktop monitors, present the app in an authentic mobile device viewport
            if (constraints.maxWidth > 540) {
              return Container(
                color: const Color(0xFF060911),
                alignment: Alignment.center,
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 440,
                    maxHeight: 920,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3563E9).withOpacity(0.18),
                        blurRadius: 40,
                        spreadRadius: 6,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.7),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF2A3348).withOpacity(0.6),
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: child ?? const SizedBox(),
                ),
              );
            }
            // On mobile screens, display edge-to-edge
            return child ?? const SizedBox();
          },
        );
      },
    );
  }
}
