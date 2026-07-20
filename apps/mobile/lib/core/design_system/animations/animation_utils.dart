import 'package:flutter/material.dart';
import 'animation_tokens.dart';

class AnimatedFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double begin;
  final int delayMs;

  const AnimatedFadeIn({
    super.key,
    required this.child,
    this.duration = MotionDurations.normal,
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
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: MotionCurves.decelerate,
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
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

class AnimatedSlideFade extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Offset offset;

  const AnimatedSlideFade({
    super.key,
    required this.child,
    this.duration = MotionDurations.normal,
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
      duration: widget.duration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: MotionCurves.decelerate,
    );
    _slideAnimation = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: MotionCurves.decelerate,
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
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

class StaggeredListAnimation extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Duration itemDuration;
  final int baseDelayMs;

  const StaggeredListAnimation({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemDuration = MotionDurations.normal,
    this.baseDelayMs = 50,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
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
