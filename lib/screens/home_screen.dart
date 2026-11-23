import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/copy.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../services/app_state.dart';
import 'input_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _HeroSection()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _CategorySection(),
                        const SizedBox(height: 36),
                        const _TrustSection(),
                        const SizedBox(height: 16),
                        const _FaqSection(),
                        const SizedBox(height: 24),
                        _FooterNotice(),
                        const SizedBox(height: 20),
                        Center(
                          child: Text('Fate Report',
                              style: AppTheme.serif(
                                  size: 14,
                                  color: AppColors.mutedForeground,
                                  letterSpacing: 3)),
                        ),
                      ],
                    ),
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

// ─────────────── 히어로 (풀블리드 달밤 이미지 + 자연스러운 크림 페이드) ───────────────
class _HeroSection extends StatelessWidget {
  static const _softShadow = [
    Shadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 2)),
    Shadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final screenH = MediaQuery.of(context).size.height;
    final heroH = screenH.clamp(640.0, 780.0);

    return SizedBox(
      height: heroH,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/hero_premium.jpg',
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.15),
            errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(gradient: AppGradients.night)),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.35],
                  colors: [Color(0x4D000000), Colors.transparent],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.40, 0.62, 0.86, 1.0],
                  colors: [
                    Colors.transparent,
                    Color(0x8C10152A),
                    Color(0x8C10152A),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.82, 0.91, 0.97, 1.0],
                  colors: [
                    Colors.transparent,
                    const Color(0xFFFDF9F2).withValues(alpha: 0.35),
                    const Color(0xFFFDF9F2).withValues(alpha: 0.88),
                    const Color(0xFFFDF9F2),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, topInset + 20, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                            color: AppColors.goldLight.withValues(alpha: 0.6),
                            width: 1.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.nightlight_round,
                          size: 18, color: AppColors.goldLight),
                    ),
                    const SizedBox(width: 11),
                    Text('FATE REPORT',
                        style: AppTheme.sans(
                            size: 13,
                            weight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.92),
                            letterSpacing: 3.5)
                          .copyWith(shadows: _softShadow)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: AppColors.goldLight,
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 7),
                      Text('AI 사주 · 궁합 리포트',
                          style: AppTheme.sans(
                              size: 11.5,
                              weight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                              height: 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('지금의 고민에,',
                    style: AppTheme.serif(
                        size: 31,
                        color: Colors.white,
                        weight: FontWeight.w600,
                        height: 1.35,
                        letterSpacing: -0.6)
                      .copyWith(shadows: _softShadow)),
                Text('사주가 답합니다',
                    style: AppTheme.serif(
                        size: 31,
                        color: AppColors.goldLight,
                        weight: FontWeight.w600,
                        height: 1.35,
                        letterSpacing: -0.6)
                      .copyWith(shadows: _softShadow)),
                const SizedBox(height: 14),
                Text(
                  AppCopy.homeSubHeadline,
                  style: AppTheme.sans(
                      size: 14.5,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.6)
                    .copyWith(shadows: _softShadow),
                ),
                const SizedBox(height: 26),
                GradientButton(
                  label: AppCopy.homeCtaLabel,
                  icon: Icons.auto_awesome,
                  gold: true,
                  shimmer: true,
                  onPressed: () {
                    context
                        .read<AppState>()
                        .selectCategory(AnalysisCategory.basic);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          const InputScreen(category: AnalysisCategory.basic),
                    ));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── 카테고리 ───────────────
class _CategorySection extends StatelessWidget {
  const _CategorySection();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          eyebrow: 'YOUR QUESTION',
          title: '지금 어떤 고민이신가요?',
          subtitle: '고민을 고르면 거기에 맞춰 답합니다.',
        ),
        const SizedBox(height: 18),
        ...List.generate(categoryList.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FadeSlideIn(
              delay: Duration(milliseconds: 70 * i),
              child: _CategoryCard(info: categoryList[i], index: i),
            ),
          );
        }),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryInfo info;
  final int index;
  const _CategoryCard({required this.info, required this.index});

  static const _icons = [
    Icons.favorite_outline,
    Icons.chat_bubble_outline,
    Icons.autorenew,
    Icons.auto_awesome_outlined,
  ];

  IconData get _icon {
    switch (info.category) {
      case AnalysisCategory.compatibility:
        return _icons[0];
      case AnalysisCategory.love:
        return _icons[1];
      case AnalysisCategory.pattern:
        return _icons[2];
      case AnalysisCategory.basic:
        return _icons[3];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        splashColor: AppColors.gold.withValues(alpha: 0.06),
        highlightColor: AppColors.gold.withValues(alpha: 0.04),
        onTap: () {
          context.read<AppState>().selectCategory(info.category);
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => InputScreen(category: info.category),
          ));
        },
        child: SoftCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
          child: Row(
            children: [
              Icon(_icon, size: 22, color: AppColors.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.plainName,
                        style: AppTheme.sans(
                            size: 11,
                            weight: FontWeight.w700,
                            color: AppColors.accentSoft,
                            letterSpacing: 0.4,
                            height: 1)),
                    const SizedBox(height: 7),
                    Text(info.questionTitle,
                        style: AppTheme.serif(
                            size: 16.5,
                            weight: FontWeight.w600,
                            height: 1.35,
                            letterSpacing: -0.3)),
                    const SizedBox(height: 5),
                    Text(info.desc,
                        style: AppTheme.sans(
                            size: 12.5,
                            color: AppColors.mutedForeground,
                            height: 1.45)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  size: 22, color: AppColors.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────── 신뢰 카드 ───────────────
class _TrustSection extends StatelessWidget {
  const _TrustSection();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
            eyebrow: 'WHY TRUST US', title: '믿을 수 있는 이유'),
        const SizedBox(height: 16),
        // 카드 여러 장 대신 한 장에 세 줄로 담아 홈을 짧게 유지한다.
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < AppCopy.trustCards.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.hairline),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('0${i + 1}',
                            style: AppTheme.serif(
                                size: 13,
                                weight: FontWeight.w600,
                                color: AppColors.gold,
                                height: 1.3)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppCopy.trustCards[i].title,
                                style: AppTheme.sans(
                                    size: 14.5,
                                    weight: FontWeight.w700,
                                    color: AppColors.primary,
                                    height: 1.3)),
                            const SizedBox(height: 3),
                            BodyText(AppCopy.trustCards[i].desc,
                                size: 13, color: AppColors.mutedForeground),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────── FAQ ───────────────
/// 평소에는 한 줄로 접혀 있고, 누르면 질문 목록이 펼쳐진다.
class _FaqSection extends StatefulWidget {
  const _FaqSection();
  @override
  State<_FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<_FaqSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => setState(() => _open = !_open),
          child: SoftCard(
            shadow: const [],
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text('자주 묻는 질문',
                      style: AppTheme.sans(
                          size: 14.5,
                          weight: FontWeight.w700,
                          color: AppColors.primary,
                          height: 1.3)),
                ),
                Icon(
                    _open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: AppColors.mutedForeground),
              ],
            ),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 10),
          ...AppCopy.faqs.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FaqTile(item: f),
              )),
        ],
      ],
    );
  }
}

class _FaqTile extends StatefulWidget {
  final FaqItem item;
  const _FaqTile({required this.item});
  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool open = false;
  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 16),
          onExpansionChanged: (v) => setState(() => open = v),
          iconColor: AppColors.gold,
          collapsedIconColor: AppColors.mutedForeground,
          title: Text(widget.item.q,
              style: AppTheme.sans(
                  size: 14.5,
                  weight: FontWeight.w600,
                  color: AppColors.primary,
                  height: 1.4)),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: BodyText(widget.item.a,
                  size: 13.5, color: AppColors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.noticeBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              size: 15, color: AppColors.mutedForeground),
          const SizedBox(width: 10),
          Expanded(
            child: BodyText(AppCopy.commonNotice,
                size: 12, color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}
