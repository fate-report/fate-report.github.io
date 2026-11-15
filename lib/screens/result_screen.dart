import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

import '../content/copy.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../models/models.dart';
import '../services/ai_service.dart';
import '../compat/compat_engine.dart';
import 'capture_helper.dart';

class ResultScreen extends StatefulWidget {
  final AnalysisCategory category;
  final UserProfile user;
  final PartnerProfile? partner;
  final String userQuestion;
  const ResultScreen({
    super.key,
    required this.category,
    required this.user,
    this.partner,
    required this.userQuestion,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _loading = true;
  AiException? _error;
  AnalysisResult? _general;
  CompatResult? _compat;
  final GlobalKey _captureKey = GlobalKey();

  bool get _isCompat => widget.category == AnalysisCategory.compatibility;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isCompat) {
        final calendarClear = widget.user.calendarType != 'unknown' &&
            (widget.partner?.partnerCalendarType ?? 'unknown') != 'unknown';
        final comp = CompatEngine.compute(
          me: widget.user.toSaju(),
          partner: widget.partner!.toSaju(),
          calendarClear: calendarClear,
        );
        final result = await AiService.generateCompatibility(
          user: widget.user,
          partner: widget.partner!,
          comp: comp,
          userQuestion: widget.userQuestion,
        );
        if (!mounted) return;
        setState(() {
          _compat = result;
          _loading = false;
        });
      } else {
        final result = await AiService.generateAnalysis(
          user: widget.user,
          category: widget.category,
          userQuestion: widget.userQuestion,
        );
        if (!mounted) return;
        setState(() {
          _general = result;
          _loading = false;
        });
      }
    } on AiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AiException(AiErrorType.unknown, e.toString());
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = categoryList
        .firstWhere((c) => c.category == widget.category)
        .plainName;
    return Scaffold(
      body: PageBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              size: 18, color: AppColors.primary),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        Expanded(
                          child: Text(title,
                              textAlign: TextAlign.center,
                              style: AppTheme.serif(
                                  size: 16,
                                  weight: FontWeight.w600,
                                  letterSpacing: 1)),
                        ),
                        SizedBox(
                          width: 44,
                          child: (!_loading && _error == null)
                              ? IconButton(
                                  tooltip: '이미지로 저장',
                                  icon: const Icon(Icons.ios_share,
                                      size: 20, color: AppColors.gold),
                                  onPressed: _capture,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _loading
                        ? const _LoadingView()
                        : _error != null
                            ? _ErrorView(error: _error!, onRetry: _run)
                            : _buildResult(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        RepaintBoundary(
          key: _captureKey,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(gradient: AppGradients.page),
            child: _isCompat ? _compatCards() : _generalCards(),
          ),
        ),
        const SizedBox(height: 20),
        GradientButton(
          label: '결과 이미지로 저장 (공유용)',
          icon: Icons.download,
          gold: true,
          onPressed: _capture,
        ),
      ],
    );
  }

  Widget _generalCards() {
    final r = _general!;
    return Column(
      children: [
        _keyResultCard(r.resultTitle, r.keyPoint, r.resultSummary),
        const SizedBox(height: 12),
        _confidenceBadge(r.confidenceStatus),
        const SizedBox(height: 12),
        if (r.goodPoints.isNotEmpty)
          _listCard('좋은 점', r.goodPoints, AppColors.goodBg,
              AppColors.signalGreen, Icons.eco_outlined),
        if (r.goodPoints.isNotEmpty) const SizedBox(height: 12),
        if (r.riskPoints.isNotEmpty)
          _listCard('조심할 점', r.riskPoints, AppColors.riskBg,
              AppColors.gold, Icons.warning_amber_rounded),
        if (r.riskPoints.isNotEmpty) const SizedBox(height: 12),
        _actionCard(r.actionItems),
        const SizedBox(height: 12),
        _noticeCard(r.warningMessage),
      ],
    );
  }

  Widget _compatCards() {
    final r = _compat!;
    if (!r.compatibilityAvailable) {
      return Column(
        children: [
          _holdCard(r.holdReason ?? '판정 보류'),
          const SizedBox(height: 12),
          _keyResultCard('판정 보류', '지금은 확정하지 않았습니다', r.finalJudgment),
          const SizedBox(height: 12),
          _actionCard(r.actionItems),
          const SizedBox(height: 12),
          _noticeCard(AppCopy.compatNotice),
        ],
      );
    }
    return Column(
      children: [
        _scoreCard(r),
        const SizedBox(height: 12),
        _detailScoresCard(r),
        const SizedBox(height: 12),
        if (r.goodParts.isNotEmpty)
          _listCard('잘 맞는 부분', r.goodParts, AppColors.goodBg,
              AppColors.signalGreen, Icons.favorite_outline),
        if (r.goodParts.isNotEmpty) const SizedBox(height: 12),
        if (r.riskParts.isNotEmpty)
          _listCard('조심할 부분', r.riskParts, AppColors.riskBg,
              AppColors.gold, Icons.warning_amber_rounded),
        if (r.riskParts.isNotEmpty) const SizedBox(height: 12),
        _keyResultCard('최종 판단', '', r.finalJudgment),
        const SizedBox(height: 12),
        _actionCard(r.actionItems),
        const SizedBox(height: 12),
        _noticeCard(AppCopy.compatNotice),
      ],
    );
  }

  Widget _keyResultCard(String title, String key, String summary) {
    return SoftCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoldHairline(width: 32),
          const SizedBox(height: 14),
          Text(title,
              style: GoogleFonts.notoSerifKr(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                height: 1.4,
              )),
          if (key.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(key,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                  height: 1.5,
                )),
          ],
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 14),
            BodyText(summary, size: 15),
          ],
        ],
      ),
    );
  }

  Widget _confidenceBadge(ConfidenceStatus s) {
    late String text;
    late Color color;
    late IconData icon;
    switch (s) {
      case ConfidenceStatus.ok:
        text = '명식 신뢰도: 충분';
        color = AppColors.signalGreen;
        icon = Icons.verified_outlined;
        break;
      case ConfidenceStatus.partial:
        text = '명식 신뢰도: 부분 (출생시간 일부 제외)';
        color = AppColors.gold;
        icon = Icons.info_outline;
        break;
      case ConfidenceStatus.hold:
        text = '판정 보류: 정보 부족';
        color = AppColors.signalGray;
        icon = Icons.help_outline;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(text,
              style: GoogleFonts.notoSansKr(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              )),
        ],
      ),
    );
  }

  Widget _listCard(String title, List<String> items, Color bg, Color accent,
      IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration:
                            BoxDecoration(color: accent, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: BodyText(t, size: 14.5)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _actionCard(List<String> items) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('지금 할 일',
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text('${e.key + 1}',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: BodyText(e.value, size: 14.5)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _noticeCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.noticeBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: BodyText(text, size: 12, color: AppColors.mutedForeground),
    );
  }

  Widget _scoreCard(CompatResult r) {
    final color = _signalColor(r.signalColor);
    final label = _signalLabel(r.signalColor);
    final desc = _signalDesc(r.signalColor);
    return SoftCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: r.compatibilityScore / 100,
                    strokeWidth: 12,
                    backgroundColor: AppColors.muted,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${r.compatibilityScore}',
                        style: GoogleFonts.notoSerifKr(
                          fontSize: 46,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          height: 1,
                        )),
                    Text('/ 100',
                        style: GoogleFonts.notoSansKr(
                            fontSize: 13,
                            color: AppColors.mutedForeground)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(label,
                        style: GoogleFonts.notoSerifKr(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        )),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: BodyText(desc,
                      size: 13, align: TextAlign.center,
                      color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailScoresCard(CompatResult r) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('세부 점수',
              style: GoogleFonts.notoSerifKr(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              )),
          const SizedBox(height: 16),
          ...r.detailedScores.entries.map((e) {
            final max = r.maxScores[e.key] ?? 1;
            final ratio = e.value / max;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_scoreLabel(e.key),
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          )),
                      Text('${e.value} / $max',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13,
                            color: AppColors.mutedForeground,
                          )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 7,
                      backgroundColor: AppColors.muted,
                      valueColor: AlwaysStoppedAnimation(
                        ratio >= 0.7
                            ? AppColors.signalGreen
                            : ratio >= 0.4
                                ? AppColors.gold
                                : AppColors.signalRed,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _holdCard(String reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.signalGray.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.signalGray.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.pause_circle_outline,
              size: 40, color: AppColors.signalGray),
          const SizedBox(height: 12),
          Text('궁합 판정 보류',
              style: GoogleFonts.notoSerifKr(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              )),
          const SizedBox(height: 8),
          BodyText(reason,
              align: TextAlign.center,
              size: 14,
              color: AppColors.mutedForeground),
        ],
      ),
    );
  }

  Color _signalColor(String c) {
    switch (c) {
      case 'green':
        return AppColors.signalGreen;
      case 'yellow':
        return AppColors.signalYellow;
      case 'red':
        return AppColors.signalRed;
      default:
        return AppColors.signalGray;
    }
  }

  String _signalLabel(String c) {
    switch (c) {
      case 'green':
        return '초록불 · 잘 맞는 편';
      case 'yellow':
        return '노란불 · 관리가 필요';
      case 'red':
        return '빨간불 · 노력이 필요';
      default:
        return '판정 보류';
    }
  }

  String _signalDesc(String c) {
    switch (c) {
      case 'green':
        return AppCopy.signalGreenDesc;
      case 'yellow':
        return AppCopy.signalYellowDesc;
      case 'red':
        return AppCopy.signalRedDesc;
      default:
        return AppCopy.signalGrayDesc;
    }
  }

  String _scoreLabel(String key) {
    switch (key) {
      case '정보신뢰도':
        return '명식 정보 신뢰도';
      case '핵심자리':
        return '핵심 자리 궁합';
      case '오행보완':
        return '오행 보완성';
      case '충형해':
        return '충·형·해 리스크';
      case '현실안정':
        return '현실 안정성';
      default:
        return key;
    }
  }

  Future<void> _capture() async {
    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final fileName =
          'fate_report_${DateTime.now().millisecondsSinceEpoch}.png';
      await CaptureHelper.savePng(pngBytes, fileName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결과 이미지를 저장했어요.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 저장에 실패했어요.')),
      );
    }
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppColors.gold),
              ),
            ),
            const SizedBox(height: 24),
            Text(AppCopy.loadingMessage,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                )),
            const SizedBox(height: 8),
            BodyText('잠시만 기다려주세요.',
                size: 13.5, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final AiException error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SoftCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_empty,
                  size: 40, color: AppColors.gold),
              const SizedBox(height: 16),
              Text('잠시만요',
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  )),
              const SizedBox(height: 10),
              BodyText(error.userMessage,
                  align: TextAlign.center,
                  size: 14.5,
                  color: AppColors.mutedForeground),
              const SizedBox(height: 20),
              GradientButton(label: '다시 시도', onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}
