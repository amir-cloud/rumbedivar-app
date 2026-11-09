import 'package:flutter_test/flutter_test.dart';
import 'package:rumbedivar/core/page_transitions.dart';

void main() {
  setUp(() => PageTransitionTracker.instance.reset());

  test('first location is forward', () {
    PageTransitionTracker.instance.trackLocation('/splash');
    expect(PageTransitionTracker.instance.goingBack, isFalse);
  });

  test('moving somewhere new is forward', () {
    final tracker = PageTransitionTracker.instance;
    tracker.trackLocation('/login');
    tracker.trackLocation('/register');
    expect(tracker.goingBack, isFalse);
  });

  test('returning to the previous location is backward', () {
    final tracker = PageTransitionTracker.instance;
    tracker.trackLocation('/login');
    tracker.trackLocation('/register');
    tracker.trackLocation('/login');
    expect(tracker.goingBack, isTrue);
  });

  test('going forward again after a back is forward', () {
    final tracker = PageTransitionTracker.instance;
    tracker.trackLocation('/login');
    tracker.trackLocation('/register');
    tracker.trackLocation('/login');
    expect(tracker.goingBack, isTrue);
    tracker.trackLocation('/register');
    expect(tracker.goingBack, isFalse);
  });

  test('re-navigating to the same location stays forward', () {
    final tracker = PageTransitionTracker.instance;
    tracker.trackLocation('/home');
    tracker.trackLocation('/home');
    expect(tracker.goingBack, isFalse);
  });

  test('auth flow back (register -> login) reads backward', () {
    final tracker = PageTransitionTracker.instance;
    tracker.trackLocation('/splash');
    tracker.trackLocation('/login');
    tracker.trackLocation('/register');
    tracker.trackLocation('/login');
    expect(tracker.direction, PageTransitionDirection.backward);
  });

  test('tab tap left of active slides from the left', () {
    final tracker = PageTransitionTracker.instance;
    tracker.trackLocation('/home');
    tracker.setTabDirection(fromIndex: 2, toIndex: 1);
    tracker.trackLocation('/catalog');
    expect(tracker.direction, PageTransitionDirection.backward);
  });

  test('tab tap right of active slides from the right', () {
    final tracker = PageTransitionTracker.instance;
    tracker.trackLocation('/home');
    tracker.setTabDirection(fromIndex: 1, toIndex: 2);
    tracker.trackLocation('/search');
    expect(tracker.direction, PageTransitionDirection.forward);
  });

  test('tab override wins over history for one navigation', () {
    final tracker = PageTransitionTracker.instance;
    tracker.trackLocation('/a');
    tracker.trackLocation('/b');
    // History alone would read going back to /a as backward.
    tracker.setTabDirection(fromIndex: 0, toIndex: 1);
    tracker.trackLocation('/a');
    expect(tracker.direction, PageTransitionDirection.forward);
    // Override is consumed: history logic resumes afterwards.
    tracker.trackLocation('/b');
    expect(tracker.direction, PageTransitionDirection.forward);
  });

  test('tapping the active tab stays forward', () {
    final tracker = PageTransitionTracker.instance;
    tracker.trackLocation('/home');
    tracker.setTabDirection(fromIndex: 1, toIndex: 1);
    tracker.trackLocation('/home');
    expect(tracker.direction, PageTransitionDirection.forward);
  });
}
