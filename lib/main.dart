import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'database/database_helper.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'screens/main_screen.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(callbackDispatcher);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  Color _getColor(Map<String, Color> colors, String key, Color fallback) {
    return colors[key] ?? fallback;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langAsync = ref.watch(languageProvider);
    final lang = langAsync.valueOrNull ?? 'en';
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? 'light';
    final colorsAsync = ref.watch(themeColorsProvider(themeMode));
    final colors = colorsAsync.valueOrNull ?? {};
    final isDark = themeMode == 'dark';
    final brightness = isDark ? Brightness.dark : Brightness.light;

    final primary = _getColor(colors, 'App Primary', Colors.deepPurple);
    final appText = _getColor(colors, 'App Text', isDark ? Colors.white : Colors.black);
    final secondaryText = _getColor(colors, 'App Secondary Text', isDark ? Colors.grey.shade400 : Colors.grey.shade700);
    final cardColor = _getColor(colors, 'App Card', isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final secondaryPrimary = _getColor(colors, 'App Secondary Primary', isDark ? const Color(0xFF4F378B) : const Color(0xFFEADDFF));
    final taskCardColor = _getColor(colors, 'App Task Card', isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5));
    final backgroundColor = _getColor(colors, 'App Background', isDark ? const Color(0xFF121212) : const Color(0xFFF8F8F8));
    final taskTextColor = _getColor(colors, 'App Task Text', isDark ? const Color(0xFFE6E1E5) : const Color(0xFF1A1A1A));

    final themeData = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
      ).copyWith(
        primary: primary,
        secondary: secondaryPrimary,
        surface: cardColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      cardTheme: CardThemeData(
        color: taskCardColor,
        elevation: 2,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: taskTextColor, fontSize: 16),
        bodyMedium: TextStyle(color: secondaryText, fontSize: 14),
        bodySmall: TextStyle(color: secondaryText, fontSize: 12),
        titleLarge: TextStyle(color: appText, fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: appText, fontSize: 16),
        titleSmall: TextStyle(color: secondaryText, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: appText,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'MyTodo',
      debugShowCheckedModeBanner: false,
      locale: Locale(lang),
      supportedLocales: const [
        Locale('en'), Locale('th'), Locale('lo'),
        Locale('zh'), Locale('vi'), Locale('id'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: themeData,
      darkTheme: themeData, // Same theme since colors are already mode-specific
      themeMode: ThemeMode.light, // Always use our custom theme
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _fadeIn;
  late Animation<double> _iconSlide;
  late Animation<double> _titleSlide;
  late Animation<double> _taglineSlide;
  late Animation<double> _pulseAnimation;
  bool _initComplete = false;
  double get _progress {
    if (_steps.isEmpty) return 0;
    final completed = _steps.where((s) => s.done).fold<int>(0, (sum, s) => sum + s.weight);
    return completed / _totalWeight;
  }

  int get _totalWeight => _steps.fold<int>(0, (sum, s) => sum + s.weight);
  String _initStatus = '';
  final List<_InitStep> _steps = [];

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeIn = CurvedAnimation(parent: _mainController, curve: Curves.easeIn);

    _iconSlide = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _titleSlide = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    _taglineSlide = Tween<double>(begin: 15, end: 0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.93, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _mainController.forward();
    _pulseController.repeat(reverse: true);

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _skipToMain();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      if (!mounted) return;
      setState(() {
        _steps.addAll([
          _InitStep('Database', Icons.storage, 25, false),
          _InitStep('Notifications', Icons.notifications_none, 25, false),
          _InitStep('Background service', Icons.schedule, 20, false),
          _InitStep('Auto deploy', Icons.autorenew, 15, false),
          _InitStep('Homework reminder', Icons.home, 15, false),
        ]);
        _initStatus = 'Initializing database...';
      });
      await DatabaseHelper.instance.database;
      if (mounted) setState(() => _steps[0].done = true);

      if (!mounted) return;
      setState(() => _initStatus = 'Starting notifications...');
      await NotificationService.init();
      if (mounted) setState(() => _steps[1].done = true);

      if (!mounted) return;
      setState(() => _initStatus = 'Scheduling background service...');
      await BackgroundService.init();
      if (mounted) setState(() => _steps[2].done = true);

      if (!mounted) return;
      setState(() => _initStatus = 'Setting up auto deploy...');
      await BackgroundService.scheduleAutoDeploy();
      if (mounted) setState(() => _steps[3].done = true);

      if (!mounted) return;
      setState(() => _initStatus = 'Setting up homework reminder...');
      await BackgroundService.scheduleHomeworkReminder();
      if (mounted) setState(() => _steps[4].done = true);

      if (!mounted) return;
      setState(() => _initComplete = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _initStatus = 'Error: $e');
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _initComplete = true);
      });
    }
  }

  void _skipToMain() {
    _mainController.stop();
    _pulseController.stop();
    _navigateToMain();
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _gradientColor() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return const Color(0xFFFFB74D);
    } else if (hour >= 12 && hour < 17) {
      return const Color(0xFF42A5F5);
    } else if (hour >= 17 && hour < 21) {
      return const Color(0xFFAB47BC);
    } else {
      return const Color(0xFF1A237E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientColor = _gradientColor();

    return GestureDetector(
      onTap: _initComplete ? _skipToMain : null,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                gradientColor,
                gradientColor.withAlpha(120),
                const Color(0xFF1A1A2E),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    ),
                    child: AnimatedBuilder(
                      animation: _iconSlide,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _iconSlide.value),
                        child: child,
                      ),
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withAlpha(40),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(55),
                          child: Image.asset(
                            'assets/app-icon.png',
                            width: 90,
                            height: 90,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedBuilder(
                    animation: _titleSlide,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _titleSlide.value),
                      child: child,
                    ),
                    child: const Text(
                      'MyTodo',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedBuilder(
                    animation: _taglineSlide,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _taglineSlide.value),
                      child: child,
                    ),
                    child: Text(
                      'Stay organized. Stay ahead.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha(180),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withAlpha(120),
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_steps.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: Column(
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: _progress),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            builder: (context, value, _) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: value,
                                  backgroundColor: Colors.white.withAlpha(40),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _progress >= 1.0
                                        ? Colors.greenAccent
                                        : Colors.white.withAlpha(200),
                                  ),
                                  minHeight: 6,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          ..._steps.map((step) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  step.done
                                      ? const _PulseIcon(
                                          icon: Icons.check_circle,
                                          color: Colors.greenAccent,
                                        )
                                      : Icon(
                                          Icons.circle_outlined,
                                          size: 18,
                                          color: Colors.white.withAlpha(120),
                                        ),
                                  const SizedBox(width: 10),
                                  Text(
                                    step.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: step.done
                                          ? Colors.white
                                          : Colors.white.withAlpha(160),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  if (_initStatus.isNotEmpty && !_initComplete && _steps.every((s) => s.done))
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _LoadingDots(color: Colors.white.withAlpha(180)),
                    ),
                  const SizedBox(height: 48),
                  if (_initComplete)
                    const _PulseOpacity(
                      child: Text(
                        'Tap to continue',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InitStep {
  final String label;
  final IconData icon;
  final int weight;
  bool done;
  _InitStep(this.label, this.icon, this.weight, this.done);
}

class _PulseIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _PulseIcon({required this.icon, required this.color});

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, _) => Transform.scale(
        scale: _scale.value,
        child: Icon(widget.icon, size: 18, color: widget.color),
      ),
    );
  }
}

class _PulseOpacity extends StatefulWidget {
  final Widget child;
  const _PulseOpacity({required this.child});

  @override
  State<_PulseOpacity> createState() => _PulseOpacityState();
}

class _PulseOpacityState extends State<_PulseOpacity>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

class _LoadingDots extends StatefulWidget {
  final Color color;
  const _LoadingDots({required this.color});

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final t = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = (t < 0.5) ? t * 2 : (1.0 - t) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withAlpha((opacity * 255).toInt()),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}