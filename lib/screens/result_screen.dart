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
  CompatComputation? _compatComp;
  final GlobalKey _captureKey = GlobalKey();

  // 꼬리 질문(후속 대화) 상태
  final List<ChatTurn> _chatHistory = [];
  final TextEditingController _followUpCtrl = TextEditingController();
  bool _chatLoading = false;

  bool get _isCompat => widget.category == AnalysisCategory.compatibility;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    _followUpCtrl.dispose();
    super.dispose();
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
        _compatComp = comp;
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
          partner: widget.partner,
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

  Future<void> _askFollowUp(String rawQuestion) async {
    final q = rawQuestion.trim();
    if (q.isEmpty || _chatLoading) return;
    _followUpCtrl.clear();

    setState(() {
      _chatHistory.add(ChatTurn(role: 'user', text: q));
      _chatLoading = true;
    });

    try {
      final summaryContext = _isCompat
          ? (_compat?.finalJudgment ?? '')
          : (_general?.resultSummary ?? '');
      final reply = await AiService.generateFollowUp(
        user: widget.user,
        partner: widget.partner,
        comp: _compatComp,
        category: widget.category,
        initialBriefingSummary: summaryContext,
        history: _chatHistory.sublist(0, _chatHistory.length - 1),
        followUpQuestion: q,
      );
      if (!mounted) return;
      setState(() {
        _chatHistory.add(reply);
        _chatLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chatHistory.add(const ChatTurn(
          role: 'assistant',
          text: '답변을 불러오는 중 일시적인 문제가 발생했어요. 다시 한 번 질문해 주세요.',
        ));
        _chatLoading = false;
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
        const SizedBox(height: 16),
        GradientButton(
          label: '결과 이미지로 저장 (공유용)',
          icon: Icons.download,
          gold: true,
          onPressed: _capture,
        ),
        const SizedBox(height: 24),
        _followUpSection(),
      ],
    );
  }

  Widget _generalCards() {
    final r = _general!;
    return Column(
      children: [
        _keyResultCard(r.resultTitle, r.keyPoint, r.resultSummary),
        const SizedBox(height: 12),
        if (r.briefingBody.isNotEmpty) ...[
          _masterBriefingCard('마스터 심층 브리핑', r.briefingBody),
          const SizedBox(height: 12),
        ],
        if (r.goodPoints.isNotEmpty)
          _listCard('유리한 기회 · 강점 요인', r.goodPoints, AppColors.goodBg,
              AppColors.signalGreen, Icons.eco_outlined),
        if (r.goodPoints.isNotEmpty) const SizedBox(height: 12),
        if (r.riskPoints.isNotEmpty)
          _listCard('주의할 리스크 요인', r.riskPoints, AppColors.riskBg,
              AppColors.gold, Icons.warning_amber_rounded),
        if (r.riskPoints.isNotEmpty) const SizedBox(height: 12),
        _actionCard(r.actionItems),
        const SizedBox(height: 12),
        _auditFooterCard(r.auditFooter, r.confidenceStatus),
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
          _keyResultCard('판정 보류 (K08)', '지금은 점수를 확정하지 않았습니다', r.finalJudgment),
          const SizedBox(height: 12),
          if (r.briefingBody.isNotEmpty) ...[
            _masterBriefingCard('판정 보류 안내', r.briefingBody),
            const SizedBox(height: 12),
          ],
          _actionCard(r.actionItems),
          const SizedBox(height: 12),
          _auditFooterCard(r.auditFooter, ConfidenceStatus.hold),
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
        if (r.briefingBody.isNotEmpty) ...[
          _masterBriefingCard('마스터 궁합 브리핑 (K07-R3 · K09)', r.briefingBody),
          const SizedBox(height: 12),
        ],
        if (r.goodParts.isNotEmpty)
          _listCard('잘 맞는 시너지 요인', r.goodParts, AppColors.goodBg,
              AppColors.signalGreen, Icons.favorite_outline),
        if (r.goodParts.isNotEmpty) const SizedBox(height: 12),
        if (r.riskParts.isNotEmpty)
          _listCard('조심할 마찰 요인', r.riskParts, AppColors.riskBg,
              AppColors.gold, Icons.warning_amber_rounded),
        if (r.riskParts.isNotEmpty) const SizedBox(height: 12),
        _keyResultCard('최종 관계 운영 방향', '', r.finalJudgment),
        const SizedBox(height: 12),
        _actionCard(r.actionItems),
        const SizedBox(height: 12),
        _auditFooterCard(
          r.auditFooter,
          r.auditFooter.contains('HIGH')
              ? ConfidenceStatus.ok
              : ConfidenceStatus.partial,
        ),
        const SizedBox(height: 12),
        _noticeCard(AppCopy.compatNotice),
      ],
    );
  }

  /// 0절 투트랙(카톡형 이야기체 문단 / 비교·궁합 굵은 소제목) 마스터 브리핑 카드
  Widget _masterBriefingCard(String headerTitle, String bodyText) {
    final paragraphs = bodyText
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return SoftCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(headerTitle,
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...paragraphs.map((para) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _renderParagraph(para),
              )),
        ],
      ),
    );
  }

  Widget _renderParagraph(String para) {
    // [궁합 정량 요약: ...] 블록은 강조 박스로 렌더링
    if (para.startsWith('[궁합 정량 요약')) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.muted.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        ),
        child: Text(
          para,
          style: GoogleFonts.notoSansKr(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            height: 1.55,
          ),
        ),
      );
    }

    // **굵은 소제목**이 포함된 문단 처리
    final lines = para.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();
        if (trimmed.startsWith('**') && trimmed.endsWith('**') && trimmed.length > 4) {
          final cleanTitle = trimmed.replaceAll('**', '');
          return Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 6),
            child: Text(
              cleanTitle,
              style: GoogleFonts.notoSerifKr(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
                height: 1.4,
              ),
            ),
          );
        }
        final cleanLine = trimmed.replaceAll('**', '');
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: BodyText(cleanLine, size: 14.8),
        );
      }).toList(),
    );
  }

  /// 하네스 4 종료 태그 배지 ([적용 기준: K04, K09... | 확신도: HIGH])
  Widget _auditFooterCard(String footerText, ConfidenceStatus s) {
    late Color color;
    late IconData icon;
    switch (s) {
      case ConfidenceStatus.ok:
        color = AppColors.signalGreen;
        icon = Icons.verified_rounded;
        break;
      case ConfidenceStatus.partial:
        color = AppColors.gold;
        icon = Icons.fact_check_outlined;
        break;
      case ConfidenceStatus.hold:
        color = AppColors.signalGray;
        icon = Icons.help_outline_rounded;
        break;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              footerText,
              style: GoogleFonts.notoSansKr(
                fontSize: 12.8,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 하단 꼬리 질문(후속 대화) 섹션
  Widget _followUpSection() {
    final quickQuestions = _isCompat
        ? [
            '올해(2026)와 내년(2027) 우리 관계 흐름 비교해줘',
            '명리적으로 왜 이 점수가 나왔는지 자세히 설명해줘',
            '결론만 한 줄로 짧게 요약해줘',
            '우리가 다툴 때 바로 화해하는 대화법 알려줘',
          ]
        : [
            '올해(2026) vs 내년(2027) 흐름 비교해줘',
            '명리적으로 내 사주 구조를 자세히 설명해줘',
            '결론만 한 줄로 짧게 요약해줘',
            '내 사주에 맞는 돈·재물 관리 전략 알려줘',
          ];

    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.forum_outlined, size: 19, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(
                '이어서 물어보기 (꼬리 질문)',
                style: GoogleFonts.notoSerifKr(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '확정된 명식(K04)을 바탕으로 앞선 설명 반복 없이 궁금한 점만 콕 집어 이어 답해드려요.',
            style: AppTheme.sans(size: 12.5, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: quickQuestions.map((q) {
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _askFollowUp(q),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    q,
                    style: AppTheme.sans(
                      size: 12,
                      weight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_chatHistory.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            ..._chatHistory.map((turn) {
              final isUser = turn.role == 'user';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 380),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.accent.withValues(alpha: 0.12)
                          : AppColors.muted.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          turn.text,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13.8,
                            fontWeight:
                                isUser ? FontWeight.w600 : FontWeight.w400,
                            color: AppColors.primary,
                            height: 1.55,
                          ),
                        ),
                        if (turn.auditFooter != null &&
                            turn.auditFooter!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            turn.auditFooter!,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
          if (_chatLoading) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text('마스터 엔진이 K01~K10 기준으로 답변을 정리하고 있어요...',
                    style: AppTheme.sans(
                        size: 12, color: AppColors.mutedForeground)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _followUpCtrl,
                  onSubmitted: _askFollowUp,
                  decoration: InputDecoration(
                    hintText: '추가 질문을 입력하세요 (예: 올해 이직 운은 어때?)',
                    hintStyle: AppTheme.sans(
                        size: 13, color: AppColors.mutedForeground),
                    filled: true,
                    fillColor: AppColors.muted.withValues(alpha: 0.45),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _chatLoading
                    ? null
                    : () => _askFollowUp(_followUpCtrl.text),
                icon: const Icon(Icons.send_rounded, color: AppColors.accent),
              ),
            ],
          ),
        ],
      ),
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
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                height: 1.4,
              )),
          if (key.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(key,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                  height: 1.5,
                )),
          ],
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 14),
            BodyText(summary, size: 14.5),
          ],
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
                        decoration: BoxDecoration(
                            color: accent, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: BodyText(t, size: 14.2)),
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
              Text('지금 바로 해볼 현실 전략',
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
                    Expanded(child: BodyText(e.value, size: 14.2)),
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
                    Text('/ 100 (K07-R3)',
                        style: GoogleFonts.notoSansKr(
                            fontSize: 12, color: AppColors.mutedForeground)),
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
                      size: 13,
                      align: TextAlign.center,
                      color: AppColors.mutedForeground),
                ),
                if (r.boundaryShiftNotice != null &&
                    r.boundaryShiftNotice!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      r.boundaryShiftNotice!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
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
          Text('K07-R3 항목별 정량 채점표',
              style: GoogleFonts.notoSerifKr(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              )),
          const SizedBox(height: 16),
          ...r.detailedScores.entries.map((e) {
            final isHour = e.key == '시주 보정';
            final max = r.maxScores[e.key] ?? 1;
            final ratio = isHour
                ? ((e.value + 5) / 10.0).clamp(0.0, 1.0)
                : (e.value / max).clamp(0.0, 1.0);
            final scoreText = isHour
                ? '${e.value > 0 ? '+${e.value}' : e.value} (-5~+5)'
                : '${e.value} / $max';
            final formula = r.itemFormulas[e.key] ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          )),
                      Text(scoreText,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
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
                            : ratio >= 0.45
                                ? AppColors.gold
                                : AppColors.signalRed,
                      ),
                    ),
                  ),
                  if (formula.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      formula,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11.8,
                        color: AppColors.mutedForeground,
                        height: 1.4,
                      ),
                    ),
                  ],
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
          Text('궁합 판정 보류 (K08)',
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
        return '초록불 (80~100점) · 안정적 조화';
      case 'yellow':
        return '노란불 (50~79점) · 조율과 관리 필요';
      case 'red':
        return '빨간불 (0~49점) · 세심한 배려 필요';
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
            const SizedBox(
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
            BodyText('K01~K10 마스터 엔진과 4인 하네스가 명식을 정밀 검산 중입니다...',
                size: 13.5,
                align: TextAlign.center,
                color: AppColors.mutedForeground),
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
