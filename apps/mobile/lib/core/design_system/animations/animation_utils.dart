import 'package:flutter/material.dart';
import '../theme/motion.dart';

bool _reducedMotion(BuildContext context) =>
    MediaQuery.of(context).accessibleNavigation ||
    MediaQuery.of(context).disableAnimations;

Duration _resolveDuration(BuildContext context, Duration duration) {
  if (_reducedMotion(context)) return Duration.zero;
  return duration;
}

class AnimatedFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double begin;
  final int delayMs;

  const AnimatedFadeIn({
    super.key,
    required this.child,
    this.duration = HushMotion.normal,
    this.begin = 0.0,
    this.delayMs = 0,
  });

  @override
  State<AnimatedFadeIn> createState() => _AnimatedFadeInState();
}

class _AnimatedFadeInState extends State<AnimatedFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _resolveDuration(context, widget.duration),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: HushMotion.decelerate,
    );
    if (widget.delayMs > 0) {
      Future.delayed(Duration(milliseconds: widget.delayMs), _controller.forward);
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}

class AnimatedSlideFade extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Offset offset;

  const AnimatedSlideFade({
    super.key,
    required this.child,
    this.duration = HushMotion.normal,
    this.offset = const Offset(0, 12),
  });

  @override
  State<AnimatedSlideFade> createState() => _AnimatedSlideFadeState();
}

class _AnimatedSlideFadeState extends State<AnimatedSlideFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _resolveDuration(context, widget.duration),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: HushMotion.decelerate,
    );
    _slideAnimation = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: HushMotion.decelerate,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

class AnimatedScaleIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double begin;

  const AnimatedScaleIn({
    super.key,
    required this.child,
    this.duration = HushMotion.normal,
    this.begin = 0.85,
  });

  @override
  State<AnimatedScaleIn> createState() => _AnimatedScaleInState();
}

class _AnimatedScaleInState extends State<AnimatedScaleIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _resolveDuration(context, widget.duration),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: HushMotion.emphasize,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

class HushStaggeredAnimation extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Duration itemDuration;
  final Axis scrollDirection;

  const HushStaggeredAnimation({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemDuration = HushMotion.normal,
    this.scrollDirection = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: scrollDirection,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return AnimatedSlideFade(
          duration: itemDuration,
          offset: const Offset(0, 20),
          child: itemBuilder(context, index),
        );
      },
    );
  }
}
