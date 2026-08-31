import 'package:go_router/go_router.dart';
import '../features/setup/presentation/setup_view.dart';
import '../features/booth/presentation/booth_view.dart';
import '../features/result/presentation/result_view.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SetupView(),
    ),
    GoRoute(
      path: '/booth',
      builder: (context, state) => const BoothView(),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) => const ResultView(),
    ),
  ],
);
