import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/copy.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../services/app_state.dart';
import 'input_screen.dart';
import 'capture_helper.dart';

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
                        const SizedBox(height: 40),
                        const _TrustSection(),
                        const SizedBox(height: 40),
                        const _ComingSoonSection(),
                        const SizedBox(height: 40),
                        const _FaqSection(),
                        const SizedBox(height: 28),
                        const _PromoStudioBanner(),
                        const SizedBox(height: 20),
                        _FooterNotice(),
                        const SizedBox(height: 20),
                        Center(
                          child: Text('Fate Report  ·  여백.zip',
                              style: AppTheme.serif(
                                  size: 14,
                                  color: AppColors.mutedForeground,
                                  letterSpacing: 2.5)),
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
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.52, 0.74, 0.90, 1.0],
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
                          ..copyWith(shadows: _softShadow)),
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
                Text('만세력 기준으로,',
                    style: AppTheme.serif(
                        size: 29,
                        color: Colors.white,
                        weight: FontWeight.w700,
                        height: 1.4,
                        letterSpacing: -0.3)
                      ..copyWith(shadows: _softShadow)),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('지금 고민을 풀어주는 ',
                        style: AppTheme.serif(
                            size: 29,
                            color: Colors.white,
                            weight: FontWeight.w700,
                            height: 1.4,
                            letterSpacing: -0.3)
                          ..copyWith(shadows: _softShadow)),
                    Text('사주 리포트',
                        style: AppTheme.serif(
                            size: 29,
                            color: AppColors.goldLight,
                            weight: FontWeight.w700,
                            height: 1.4,
                            letterSpacing: -0.3)
                          ..copyWith(shadows: _softShadow)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '좋은 말만 해주는 운세가 아니라,\n계산된 명식으로 오늘의 답을 드립니다.',
                  style: AppTheme.sans(
                      size: 14.5,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.7)
                    ..copyWith(shadows: _softShadow),
                ),
                const SizedBox(height: 26),
                GradientButton(
                  label: '내 사주 분석 시작하기',
                  icon: Icons.auto_awesome,
                  gold: true,
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
          subtitle: '고민을 고르면 그에 맞춘 리포트를 드립니다.',
        ),
        const SizedBox(height: 18),
        ...List.generate(categoryList.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _CategoryCard(info: categoryList[i], index: i),
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
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accentSoft.withValues(alpha: 0.16),
                      AppColors.gold.withValues(alpha: 0.14),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_icon, size: 24, color: AppColors.accent),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.questionTitle,
                        style: AppTheme.serif(size: 16.5, height: 1.35)),
                    const SizedBox(height: 6),
                    Text(info.desc,
                        style: AppTheme.sans(
                            size: 12.5,
                            color: AppColors.mutedForeground,
                            height: 1.45)),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(info.plainName,
                          style: AppTheme.sans(
                              size: 10.5,
                              weight: FontWeight.w700,
                              color: AppColors.accent,
                              letterSpacing: 0.3,
                              height: 1)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    size: 16, color: AppColors.primary),
              ),
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
            eyebrow: 'WHY TRUST US', title: '왜 믿을 만한가요?'),
        const SizedBox(height: 18),
        ...AppCopy.trustCards.asMap().entries.map((e) {
          final idx = e.key + 1;
          final card = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SoftCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.5)),
                      shape: BoxShape.circle,
                    ),
                    child: Text('$idx',
                        style: AppTheme.serif(
                            size: 13,
                            weight: FontWeight.w700,
                            color: AppColors.gold)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(card.title,
                            style: AppTheme.sans(
                                size: 15,
                                weight: FontWeight.w700,
                                color: AppColors.primary,
                                height: 1.3)),
                        const SizedBox(height: 4),
                        BodyText(card.desc,
                            size: 13.5, color: AppColors.mutedForeground),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────── 마스터 엔진 지원 분석 주제 (LIVE) ───────────────
class _ComingSoonSection extends StatelessWidget {
  const _ComingSoonSection();
  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: AppColors.backgroundAlt,
      shadow: const [],
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('마스터 엔진 심층 질문 주제',
                  style: AppTheme.serif(size: 17, weight: FontWeight.w700)),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'LIVE 탑재 완료',
                  style: AppTheme.sans(
                      size: 11,
                      weight: FontWeight.w700,
                      color: AppColors.accent,
                      height: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'STEP 3 질문 입력창이나 리포트 하단의 [이어서 물어보기] 채팅에서 아래 주제들을 바로 물어보실 수 있습니다.',
            style: AppTheme.sans(size: 12.5, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: comingSoonList
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.35),
                            width: 1.2),
                      ),
                      child: Text(t,
                          style: AppTheme.sans(
                              size: 12.5,
                              color: AppColors.primary,
                              weight: FontWeight.w600,
                              height: 1)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────── FAQ ───────────────
class _FaqSection extends StatelessWidget {
  const _FaqSection();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(eyebrow: 'FAQ', title: '자주 묻는 질문'),
        const SizedBox(height: 16),
        ...AppCopy.faqs.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FaqTile(item: f),
            )),
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

class _PromoStudioBanner extends StatelessWidget {
  const _PromoStudioBanner();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => CaptureHelper.openUrl('promo.html'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF261E1A), Color(0xFF181310)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.gold,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '여백.zip × FATE REPORT',
                    style: AppTheme.sans(
                      size: 11,
                      weight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '30초 인스타 감성 앱 시연 필름 · 영상 스튜디오 열기',
                    style: AppTheme.serif(
                      size: 14.5,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.open_in_new_rounded,
              color: AppColors.gold,
              size: 18,
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
