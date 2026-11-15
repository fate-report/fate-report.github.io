import 'package:flutter/material.dart';

import '../content/copy.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../models/models.dart';
import '../manseryeok/saju_calculator.dart';
import '../manseryeok/birth_place.dart';
import 'result_screen.dart';

/// 입력 화면: 기본정보 → 명식확인 → 질문 (3단계)
class InputScreen extends StatefulWidget {
  final AnalysisCategory category;
  const InputScreen({super.key, required this.category});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  int _step = 0;
  final UserProfile _user = UserProfile();
  final PartnerProfile _partner = PartnerProfile();
  final TextEditingController _questionCtrl = TextEditingController();

  bool get _needsPartner =>
      categoryList.firstWhere((c) => c.category == widget.category).needsPartner;

  @override
  void dispose() {
    _questionCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      // 명식 계산
      if (_user.birthDate != null) {
        final t = _parseTime(_user.birthTime);
        final r = SajuCalculator.calculate(
          year: _user.birthDate!.year,
          month: _user.birthDate!.month,
          day: _user.birthDate!.day,
          hour: _user.birthTimeUnknown ? null : t?.$1,
          minute: _user.birthTimeUnknown ? null : t?.$2,
          placeName: _user.birthPlace,
          applyLocalTime: _user.applyLocalTime,
        );
        _user.applySaju(r);
      }
      if (_needsPartner && _partner.partnerBirthDate != null) {
        final t = _parseTime(_partner.partnerBirthTime);
        final r = SajuCalculator.calculate(
          year: _partner.partnerBirthDate!.year,
          month: _partner.partnerBirthDate!.month,
          day: _partner.partnerBirthDate!.day,
          hour: _partner.partnerBirthTimeUnknown ? null : t?.$1,
          minute: _partner.partnerBirthTimeUnknown ? null : t?.$2,
          placeName: _partner.partnerBirthPlace,
          applyLocalTime: true,
        );
        _partner.applySaju(r);
      }
    }
    if (_step < 2) {
      setState(() => _step++);
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResultScreen(
          category: widget.category,
          user: _user,
          partner: _needsPartner ? _partner : null,
          userQuestion: _questionCtrl.text.trim(),
        ),
      ));
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  (int, int)? _parseTime(String? hhmm) {
    if (hhmm == null || !hhmm.contains(':')) return null;
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return (h, m);
  }

  bool get _canProceed {
    if (_step == 0) {
      final meOk = _user.birthDate != null;
      final pOk = !_needsPartner || _partner.partnerBirthDate != null;
      return meOk && pOk;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final title = categoryList
        .firstWhere((c) => c.category == widget.category)
        .plainName;
    final steps = ['기본정보', '명식확인', '질문'];
    return Scaffold(
      body: PageBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  _TopBar(title: title, onBack: _back),
                  // 진행 바
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
                    child: Row(
                      children: List.generate(steps.length, (i) {
                        final active = i <= _step;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              children: [
                                Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? AppColors.gold
                                        : AppColors.muted,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text('${i + 1} / ${steps.length} · ${steps[i]}',
                                    style: AppTheme.sans(
                                        size: 10,
                                        color: active
                                            ? AppColors.accent
                                            : AppColors.mutedForeground,
                                        weight: FontWeight.w600,
                                        height: 1)),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                      child: _buildStep(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: SoftOutlineButton(
                              label: '이전', onPressed: _back),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: GradientButton(
                            label: _step < 2 ? '다음' : '리포트 받기',
                            icon: _step < 2 ? null : Icons.auto_awesome,
                            gold: _step == 2,
                            onPressed: _canProceed ? _next : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _StepBasicInfo(
          user: _user,
          partner: _needsPartner ? _partner : null,
          onChanged: () => setState(() {}),
        );
      case 1:
        return _StepConfirm(user: _user, partner: _needsPartner ? _partner : null);
      default:
        return _StepQuestion(category: widget.category, controller: _questionCtrl);
    }
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _TopBar({required this.title, required this.onBack});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 18, color: AppColors.primary),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(title,
                textAlign: TextAlign.center,
                style: AppTheme.serif(
                    size: 16, weight: FontWeight.w600, letterSpacing: 1)),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

// ── 1단계: 기본정보 ──
class _StepBasicInfo extends StatelessWidget {
  final UserProfile user;
  final PartnerProfile? partner;
  final VoidCallback onChanged;
  const _StepBasicInfo(
      {required this.user, required this.partner, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
            eyebrow: 'STEP 1', title: '기본 정보를 입력해주세요'),
        const SizedBox(height: 16),
        _PersonForm(
          label: '나',
          name: user.userName,
          gender: user.gender,
          date: user.birthDate,
          calendar: user.calendarType,
          time: user.birthTime,
          timeUnknown: user.birthTimeUnknown,
          place: user.birthPlace,
          onName: (v) { user.userName = v; onChanged(); },
          onGender: (v) { user.gender = v; onChanged(); },
          onDate: (v) { user.birthDate = v; onChanged(); },
          onCalendar: (v) { user.calendarType = v; onChanged(); },
          onTime: (v) { user.birthTime = v; onChanged(); },
          onTimeUnknown: (v) { user.birthTimeUnknown = v; onChanged(); },
          onPlace: (v) { user.birthPlace = v; onChanged(); },
        ),
        if (partner != null) ...[
          const SizedBox(height: 20),
          _RelationSelector(
            value: partner!.relationStatus,
            onChanged: (v) { partner!.relationStatus = v; onChanged(); },
          ),
          const SizedBox(height: 16),
          _PersonForm(
            label: '상대',
            name: partner!.partnerName,
            gender: partner!.partnerGender,
            date: partner!.partnerBirthDate,
            calendar: partner!.partnerCalendarType,
            time: partner!.partnerBirthTime,
            timeUnknown: partner!.partnerBirthTimeUnknown,
            place: partner!.partnerBirthPlace,
            onName: (v) { partner!.partnerName = v; onChanged(); },
            onGender: (v) { partner!.partnerGender = v; onChanged(); },
            onDate: (v) { partner!.partnerBirthDate = v; onChanged(); },
            onCalendar: (v) { partner!.partnerCalendarType = v; onChanged(); },
            onTime: (v) { partner!.partnerBirthTime = v; onChanged(); },
            onTimeUnknown: (v) { partner!.partnerBirthTimeUnknown = v; onChanged(); },
            onPlace: (v) { partner!.partnerBirthPlace = v; onChanged(); },
          ),
        ],
      ],
    );
  }
}

class _PersonForm extends StatelessWidget {
  final String label;
  final String name;
  final String gender;
  final DateTime? date;
  final String calendar;
  final String? time;
  final bool timeUnknown;
  final String? place;
  final ValueChanged<String> onName;
  final ValueChanged<String> onGender;
  final ValueChanged<DateTime> onDate;
  final ValueChanged<String> onCalendar;
  final ValueChanged<String?> onTime;
  final ValueChanged<bool> onTimeUnknown;
  final ValueChanged<String?> onPlace;

  const _PersonForm({
    required this.label,
    required this.name,
    required this.gender,
    required this.date,
    required this.calendar,
    required this.time,
    required this.timeUnknown,
    required this.place,
    required this.onName,
    required this.onGender,
    required this.onDate,
    required this.onCalendar,
    required this.onTime,
    required this.onTimeUnknown,
    required this.onPlace,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTheme.serif(size: 16, weight: FontWeight.w700)),
          const SizedBox(height: 14),
          TextField(
            decoration: _dec('이름 / 닉네임 (선택)'),
            onChanged: onName,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Choice(
                  options: const {'female': '여성', 'male': '남성'},
                  value: gender,
                  onChanged: onGender,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Choice(
            options: const {'solar': '양력', 'lunar': '음력'},
            value: calendar,
            onChanged: onCalendar,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime(1995, 1, 1),
                firstDate: DateTime(1920),
                lastDate: DateTime.now(),
              );
              if (picked != null) onDate(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Text(
                    date == null
                        ? '생년월일 선택'
                        : '${date!.year}년 ${date!.month}월 ${date!.day}일',
                    style: AppTheme.sans(
                        size: 14,
                        color: date == null
                            ? AppColors.mutedForeground
                            : AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Opacity(
                  opacity: timeUnknown ? 0.4 : 1,
                  child: TextField(
                    enabled: !timeUnknown,
                    decoration: _dec('출생시간 (예: 09:30)'),
                    keyboardType: TextInputType.datetime,
                    onChanged: (v) => onTime(v.isEmpty ? null : v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Checkbox(
                value: timeUnknown,
                activeColor: AppColors.accent,
                onChanged: (v) => onTimeUnknown(v ?? false),
              ),
              Text('출생시간 모름',
                  style: AppTheme.sans(size: 13, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: place,
            decoration: _dec('출생지 (진태양시 보정)'),
            items: birthPlaces
                .map((p) => DropdownMenuItem(
                      value: p.name,
                      child: Text(p.name,
                          style: AppTheme.sans(size: 14)),
                    ))
                .toList(),
            onChanged: (v) => onPlace(v),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            AppTheme.sans(size: 13.5, color: AppColors.mutedForeground),
        filled: true,
        fillColor: AppColors.muted.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}

class _Choice extends StatelessWidget {
  final Map<String, String> options;
  final String value;
  final ValueChanged<String> onChanged;
  const _Choice(
      {required this.options, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.entries.map((e) {
        final active = e.key == value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : AppColors.muted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active ? AppColors.accent : Colors.transparent,
                    width: 1.2,
                  ),
                ),
                child: Text(e.value,
                    style: AppTheme.sans(
                        size: 14,
                        weight: FontWeight.w600,
                        color: active
                            ? AppColors.accent
                            : AppColors.mutedForeground,
                        height: 1)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RelationSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _RelationSelector({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    const options = ['썸·호감', '연애 중', '권태기', '이별 후', '재회 고민'];
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('관계 상태',
              style: AppTheme.serif(size: 15, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((o) {
              final active = o == value;
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onChanged(o),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.accent.withValues(alpha: 0.12)
                        : AppColors.muted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? AppColors.accent : Colors.transparent,
                    ),
                  ),
                  child: Text(o,
                      style: AppTheme.sans(
                          size: 13,
                          weight: FontWeight.w600,
                          color: active
                              ? AppColors.accent
                              : AppColors.mutedForeground,
                          height: 1)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── 2단계: 명식 확인 ──
class _StepConfirm extends StatelessWidget {
  final UserProfile user;
  final PartnerProfile? partner;
  const _StepConfirm({required this.user, required this.partner});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          eyebrow: 'STEP 2',
          title: '계산된 명식을 확인하세요',
          subtitle: '아래 명식(사주)은 입력 정보로 자동 계산되었습니다.',
        ),
        const SizedBox(height: 16),
        _pillarCard('나의 명식', user.toSaju().yearPillar, user.monthPillar,
            user.dayPillar, user.hourPillar, user.dayMaster, user.birthTimeUnknown),
        if (partner != null) ...[
          const SizedBox(height: 14),
          _pillarCard(
              '상대의 명식',
              partner!.partnerYearPillar,
              partner!.partnerMonthPillar,
              partner!.partnerDayPillar,
              partner!.partnerHourPillar,
              partner!.partnerDayMaster,
              partner!.partnerBirthTimeUnknown),
        ],
      ],
    );
  }

  Widget _pillarCard(String title, String? y, String? m, String? d, String? h,
      String? master, bool hourUnknown) {
    final items = [
      ('년주', y),
      ('월주', m),
      ('일주', d),
      ('시주', hourUnknown ? '—' : h),
    ];
    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: AppTheme.serif(size: 16, weight: FontWeight.w700)),
              if (master != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('일간 $master',
                      style: AppTheme.sans(
                          size: 12,
                          weight: FontWeight.w700,
                          color: AppColors.accent,
                          height: 1)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: items.map((e) {
              return Expanded(
                child: Column(
                  children: [
                    Text(e.$1,
                        style: AppTheme.sans(
                            size: 11,
                            color: AppColors.mutedForeground,
                            height: 1)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.muted.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(e.$2 ?? '—',
                          style: AppTheme.serif(
                              size: 18, weight: FontWeight.w700)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (hourUnknown) ...[
            const SizedBox(height: 12),
            Text('※ 출생시간을 몰라 시주는 판정에서 제외됩니다.',
                style: AppTheme.sans(
                    size: 11.5, color: AppColors.mutedForeground)),
          ],
        ],
      ),
    );
  }
}

// ── 3단계: 질문 ──
class _StepQuestion extends StatelessWidget {
  final AnalysisCategory category;
  final TextEditingController controller;
  const _StepQuestion({required this.category, required this.controller});

  @override
  Widget build(BuildContext context) {
    final examples = _examples(category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          eyebrow: 'STEP 3',
          title: '무엇이 가장 궁금하신가요?',
          subtitle: '구체적으로 적을수록 더 현실적인 답을 드릴 수 있어요. (선택)',
        ),
        const SizedBox(height: 16),
        SoftCard(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: controller,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: '고민을 자유롭게 적어주세요.',
              hintStyle:
                  AppTheme.sans(size: 14, color: AppColors.mutedForeground),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: examples.map((ex) {
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => controller.text = ex,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.muted, width: 1.2),
                ),
                child: Text(ex,
                    style: AppTheme.sans(
                        size: 12.5,
                        color: AppColors.accent,
                        weight: FontWeight.w500,
                        height: 1)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<String> _examples(AnalysisCategory c) {
    switch (c) {
      case AnalysisCategory.basic:
        return ['제 강점과 약점이 궁금해요.', '올해 제가 집중해야 할 건 뭘까요?'];
      case AnalysisCategory.love:
        return ['그 사람이 저를 어떻게 생각할까요?', '지금 고백해도 될까요?'];
      case AnalysisCategory.pattern:
        return ['왜 비슷한 실수를 반복할까요?', '관계에서 제 패턴이 궁금해요.'];
      case AnalysisCategory.compatibility:
        return ['이 사람과 계속 만나도 될까요?', '우리 궁합의 약점은 뭔가요?'];
    }
  }
}
