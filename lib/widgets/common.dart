import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 프리미엄 카드 - 부드러운 음영 + 큰 라운드
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? shadow;
  final Gradient? gradient;
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.color,
    this.border,
    this.shadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.card) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: shadow ?? AppShadows.card,
        border: border ?? Border.all(color: AppColors.hairline, width: 1),
      ),
      child: child,
    );
  }
}

/// 그라데이션 프라이머리 버튼.
/// [gold]는 어두운 배경 위의 대표 버튼에만 쓰고, [shimmer]를 켜면 빛이 천천히 지나간다.
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool gold;
  final bool shimmer;
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.gold = false,
    this.shimmer = false,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.shimmer) {
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3200),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    final icon = widget.icon;
    final gold = widget.gold;
    final radius = BorderRadius.circular(AppRadius.button);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: widget.onPressed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gold ? AppGradients.gold : AppGradients.primaryBtn,
            borderRadius: radius,
            boxShadow: gold ? AppShadows.gold : AppShadows.elevated,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 17),
            alignment: Alignment.center,
            decoration: _ctrl == null
                ? null
                : _ShimmerDecoration(animation: _ctrl!, radius: radius),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      size: 18,
                      color: gold ? AppColors.primary : Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: AppTheme.sans(
                    size: 15.5,
                    weight: FontWeight.w700,
                    color: gold ? AppColors.primary : Colors.white,
                    height: 1,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 버튼 위를 천천히 지나가는 빛. 애니메이션 값이 바뀔 때만 다시 그린다.
class _ShimmerDecoration extends Decoration {
  final Animation<double> animation;
  final BorderRadius radius;
  const _ShimmerDecoration({required this.animation, required this.radius});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _ShimmerPainter(animation, radius, onChanged);
}

class _ShimmerPainter extends BoxPainter {
  final Animation<double> animation;
  final BorderRadius radius;
  _ShimmerPainter(this.animation, this.radius, VoidCallback? onChanged)
      : super(onChanged) {
    if (onChanged != null) animation.addListener(onChanged);
  }

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;
    final rect = offset & size;
    // 전체 주기의 앞 45% 동안만 빛이 지나가고 나머지는 쉰다.
    final t = (animation.value / 0.45).clamp(0.0, 1.0);
    if (t >= 1.0) return;
    final band = size.width * 0.35;
    final x = rect.left - band + (size.width + band * 2) * t;
    final shader = LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: 0.32),
        Colors.white.withValues(alpha: 0),
      ],
    ).createShader(Rect.fromLTWH(x - band / 2, rect.top, band, size.height));
    canvas.save();
    canvas.clipRRect(radius.toRRect(rect));
    canvas.drawRect(rect, Paint()..shader = shader);
    canvas.restore();
  }

  @override
  void dispose() {
    if (onChanged != null) animation.removeListener(onChanged!);
    super.dispose();
  }
}

/// 처음 나타날 때 살짝 떠오르며 등장한다. [delay]로 순서를 줄 수 있다.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  static const _run = Duration(milliseconds: 420);
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    final total = _run + widget.delay;
    _ctrl = AnimationController(vsync: this, duration: total);
    final begin = widget.delay.inMilliseconds / total.inMilliseconds;
    _anim = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(begin, 1.0, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(_anim),
        child: widget.child,
      ),
    );
  }
}

/// 아웃라인 보조 버튼
class SoftOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const SoftOutlineButton({super.key, required this.label, this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.muted, width: 1.5),
          ),
          child: Text(label,
              style: AppTheme.sans(
                  size: 15,
                  weight: FontWeight.w600,
                  color: AppColors.mutedForeground,
                  height: 1)),
        ),
      ),
    );
  }
}

/// 얇은 금색 그라데이션 라인
class GoldHairline extends StatelessWidget {
  final double width;
  const GoldHairline({super.key, this.width = 44});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 2.5,
      decoration: BoxDecoration(
        gradient: AppGradients.gold,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// 작은 eyebrow 라벨
class Eyebrow extends StatelessWidget {
  final String text;
  const Eyebrow(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTheme.sans(
        size: 11.5,
        weight: FontWeight.w700,
        color: AppColors.gold,
        letterSpacing: 2.5,
        height: 1,
      ),
    );
  }
}

/// 섹션 제목 (eyebrow + 명조 타이틀)
class SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(eyebrow),
        const SizedBox(height: 10),
        Text(title, style: AppTheme.serif(size: 22, height: 1.35)),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!,
              style: AppTheme.sans(
                  size: 14, color: AppColors.mutedForeground)),
        ],
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final double size;
  const SectionTitle(this.text, {super.key, this.size = 20});
  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTheme.serif(size: size, height: 1.35));
  }
}

class BodyText extends StatelessWidget {
  final String text;
  final Color? color;
  final double size;
  final FontWeight weight;
  final TextAlign align;
  const BodyText(
    this.text, {
    super.key,
    this.color,
    this.size = 15,
    this.weight = FontWeight.w400,
    this.align = TextAlign.start,
  });
  @override
  Widget build(BuildContext context) {
    return Text(text,
        textAlign: align,
        style: AppTheme.sans(size: size, weight: weight, color: color));
  }
}

class ComingSoonBadge extends StatelessWidget {
  const ComingSoonBadge({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('COMING SOON',
          style: AppTheme.sans(
              size: 9.5,
              weight: FontWeight.w700,
              color: AppColors.gold,
              letterSpacing: 1.5,
              height: 1)),
    );
  }
}

class MutedLabel extends StatelessWidget {
  final String text;
  const MutedLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTheme.sans(
            size: 13, weight: FontWeight.w500, color: AppColors.mutedForeground));
  }
}

/// 페이지 그라데이션 배경 래퍼
class PageBackground extends StatelessWidget {
  final Widget child;
  const PageBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.page),
      child: child,
    );
  }
}
