import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Which way the page stack is moving.
enum PageTransitionDirection { forward, backward }

/// Remembers where the user has been so every navigation â€” `go()`, `push()`
/// or `pop()` â€” animates in the right direction.
///
/// `go()` replaces the page stack instead of pushing onto it, so without
/// this every navigation (including going "back", e.g. product â†’ catalog,
/// register â†’ login, or switching shell tabs) slides in from the same side.
/// The tracker keeps a history of visited locations: moving somewhere new
/// is [PageTransitionDirection.forward], returning to the previously
/// visited location is [PageTransitionDirection.backward].
///
/// Wired up once per router via [watchRouterForDirection]; read (never
/// written) by [directionalSlidePage]. Auth pages, shell tabs and pushed
/// pages all share the one instance, so the whole app â€” auth flow
/// included â€” moves as a single consistent back-and-forth stack.
class PageTransitionTracker extends ChangeNotifier {
  PageTransitionTracker._();
  static final PageTransitionTracker instance = PageTransitionTracker._();

  static const int _maxHistory = 50;
  final List<String> _history = [];
  PageTransitionDirection _direction = PageTransitionDirection.forward;
  bool _overrideNext = false;

  PageTransitionDirection get direction => _direction;
  bool get goingBack => _direction == PageTransitionDirection.backward;

  /// One-shot direction for bottom-tab taps, expressed in visual order:
  /// tapping a tab left of the active one ([toIndex] < [fromIndex]) pulls
  /// the next page in from the left, tapping one to the right slides the
  /// page in from the right. Consumed by the next [trackLocation] call,
  /// which still updates the history so later back/forward detection keeps
  /// working.
  void setTabDirection({required int fromIndex, required int toIndex}) {
    _direction = toIndex < fromIndex
        ? PageTransitionDirection.backward
        : PageTransitionDirection.forward;
    _overrideNext = true;
    notifyListeners();
  }

  void trackLocation(String location) {
    final overridden = _overrideNext;
    _overrideNext = false;
    if (_history.isNotEmpty && _history.last == location) {
      // Re-navigating to the page we're already on: fresh forward motion.
      if (!overridden) _direction = PageTransitionDirection.forward;
    } else if (_history.length >= 2 &&
        _history[_history.length - 2] == location) {
      // Back to the previously visited location.
      _history.removeLast();
      if (!overridden) _direction = PageTransitionDirection.backward;
    } else {
      _history.add(location);
      if (_history.length > _maxHistory) {
        _history.removeRange(0, _history.length - _maxHistory);
      }
      if (!overridden) _direction = PageTransitionDirection.forward;
    }
    notifyListeners();
  }

  @visibleForTesting
  void reset() {
    _history.clear();
    _direction = PageTransitionDirection.forward;
  }
}

/// Connects [router] to [PageTransitionTracker.instance] so every location
/// change â€” `go()`, `push()`, `pop()` and redirects â€” updates the direction
/// before the new page builds its transition.
void watchRouterForDirection(GoRouter router) {
  void update() {
    PageTransitionTracker.instance.trackLocation(
      router.routerDelegate.currentConfiguration.uri.path,
    );
  }

  router.routerDelegate.addListener(update);
  update();
}

/// Back-and-forth page transition shared by every route.
///
/// Plain directional slide, nothing else: no blur, no zoom, no dimming â€”
/// the page underneath simply stays put.
///
/// * Forward: the new page slides in from [enterOffset] (default: right)
///   with a soft fade.
/// * Back (`go()` to the previous location, or a pop): the new page slides
///   in from the mirrored side.
///
/// Keep using [directionalSlidePage] for every route â€” auth pages included â€”
/// so the whole app moves as one consistent stack.
/// Smooth directional transition: fade + slight slide.
/// Handles both incoming and outgoing animations to avoid overlapping pages.
class PageTransitionDurations {
  static const Duration forward = Duration(milliseconds: 280);
  static const Duration reverse = Duration(milliseconds: 240);
}

/// Builds the app's standard directional page for go_router routes.
CustomTransitionPage<void> directionalSlidePage({
  required GoRouterState state,
  required Widget child,
  Offset enterOffset = const Offset(0.04, 0.0),
}) {
  final backward = PageTransitionTracker.instance.goingBack;
  final dx = enterOffset.dx.abs().clamp(0.03, 0.08);
  final enterBegin = backward ? Offset(-dx, 0.0) : Offset(dx, 0.0);

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: PageTransitionDurations.forward,
    reverseTransitionDuration: PageTransitionDurations.reverse,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final inCurve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final outCurve = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final slideIn = Tween<Offset>(begin: enterBegin, end: Offset.zero).animate(inCurve);
      final slideOut = Tween<Offset>(begin: Offset.zero, end: Offset(-enterBegin.dx * 0.7, 0))
          .animate(outCurve);
      final fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(outCurve);

      return FadeTransition(
        opacity: fadeOut,
        child: SlideTransition(
          position: slideOut,
          child: FadeTransition(
            opacity: inCurve,
            child: SlideTransition(
              position: slideIn,
              child: child,
            ),
          ),
        ),
      );
    },
  );
}