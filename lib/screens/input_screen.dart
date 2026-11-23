import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/copy.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../manseryeok/ganzhi.dart';
import '../manseryeok/saju_calculator.dart';
import '../manseryeok/saju_explainer.dart';
import '../manseryeok/birth_place.dart';
import '../manseryeok/lunar_converter.dart';
import 'result_screen.dart';

/// 입력 화면: 기본정보 → 명식확인(K04/K08 게이트 & 직접 수정 지원) → 질문 (3단계)
class InputScreen extends StatefulWidget {
  final AnalysisCategory category;
  const InputScreen({super.key, required this.category});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  int _step = 0;
  late final UserProfile _user;
  late final PartnerProfile _partner;
  final TextEditingController _questionCtrl = TextEditingController();

  /// '연애·속마음(love)' 카테고리에서 상대방 정보 함께 입력 여부 (솔로/상대 생일 미상 지원)
  bool _includePartnerInLove = true;

  bool get _categoryAllowsPartner =>
      categoryList.firstWhere((c) => c.category == widget.category).needsPartner;

  bool get _effectiveNeedsPartner {
    if (widget.category == AnalysisCategory.compatibility) return true;
    if (widget.category == AnalysisCategory.love) return _includePartnerInLove;
    return false;
  }

  @override
  void initState() {
    super.initState();
    AppState? appState;
    try {
      appState = Provider.of<AppState>(context, listen: false);
    } catch (_) {}
    _user = appState?.user ?? UserProfile();
    _partner = appState?.partner ?? PartnerProfile();
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    super.dispose();
  }

  static int _maxValidDay(int year, int month, String calendarType) {
    if (calendarType == 'lunar' || calendarType == 'lunar_leap') {
      return LunarConverter.maxDaysInLunarMonth(
        year,
        month,
        isLeapMonth: calendarType == 'lunar_leap',
      );
    }
    return DateTime(year, month + 1, 0).day;
  }

  static DateTime _clampDateForCalendar(DateTime dt, String calendarType) {
    final maxD = _maxValidDay(dt.year, dt.month, calendarType);
    final d = dt.day > maxD ? maxD : dt.day;
    return DateTime(dt.year, dt.month, d);
  }

  /// '09:30', '9:30', '0930', '930', '14시 30분', '14시' 등 다양한 시간 입력 포맷을 안전하게 파싱
  static (int, int)? _parseTime(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;

    int? h;
    int? m;

    if (s.contains(':')) {
      final parts = s.split(':');
      if (parts.length != 2) return null;
      h = int.tryParse(parts[0].trim());
      m = int.tryParse(parts[1].trim());
    } else if (RegExp(r'^\d{3,4}$').hasMatch(s)) {
      if (s.length == 3) {
        h = int.tryParse(s.substring(0, 1));
        m = int.tryParse(s.substring(1, 3));
      } else {
        h = int.tryParse(s.substring(0, 2));
        m = int.tryParse(s.substring(2, 4));
      }
    } else {
      final match = RegExp(r'^(\d{1,2})\s*시(?:\s*(\d{1,2})\s*분?)?$').firstMatch(s);
      if (match != null) {
        h = int.tryParse(match.group(1)!);
        m = match.group(2) != null ? int.tryParse(match.group(2)!) : 0;
      } else {
        final onlyHour = int.tryParse(s);
        if (onlyHour != null) {
          h = onlyHour;
          m = 0;
        }
      }
    }

    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return (h, m);
  }

  static bool _hasInvalidTimeInput(String? raw, bool timeUnknown) {
    if (timeUnknown || raw == null || raw.trim().isEmpty) return false;
    return _parseTime(raw) == null;
  }

  void _next() {
    if (_step == 0) {
      // 달력 기준에 맞춰 일자 클램핑 보정
      if (_user.birthDate != null) {
        _user.birthDate =
            _clampDateForCalendar(_user.birthDate!, _user.calendarType);
      }
      if (_partner.partnerBirthDate != null) {
        _partner.partnerBirthDate = _clampDateForCalendar(
          _partner.partnerBirthDate!,
          _partner.partnerCalendarType,
        );
      }

      // 명식 계산 (K04 대운 및 K05/K08 경계 감지 포함)
      if (_user.birthDate != null && !_user.manualOverride) {
        final t = _user.birthTimeUnknown ? null : _parseTime(_user.birthTime);
        if (t != null) {
          _user.birthTime =
              '${t.$1.toString().padLeft(2, '0')}:${t.$2.toString().padLeft(2, '0')}';
        }
        final r = SajuCalculator.calculate(
          year: _user.birthDate!.year,
          month: _user.birthDate!.month,
          day: _user.birthDate!.day,
          hour: t?.$1,
          minute: t?.$2,
          placeName: _user.birthPlace,
          applyLocalTime: _user.applyLocalTime,
          gender: _user.gender,
          calendarType: _user.calendarType,
        );
        _user.applySaju(r);
      }
      if (_effectiveNeedsPartner &&
          _partner.partnerBirthDate != null &&
          !_partner.partnerManualOverride) {
        final pt = _partner.partnerBirthTimeUnknown
            ? null
            : _parseTime(_partner.partnerBirthTime);
        if (pt != null) {
          _partner.partnerBirthTime =
              '${pt.$1.toString().padLeft(2, '0')}:${pt.$2.toString().padLeft(2, '0')}';
        }
        final r = SajuCalculator.calculate(
          year: _partner.partnerBirthDate!.year,
          month: _partner.partnerBirthDate!.month,
          day: _partner.partnerBirthDate!.day,
          hour: pt?.$1,
          minute: pt?.$2,
          placeName: _partner.partnerBirthPlace,
          applyLocalTime: _partner.partnerApplyLocalTime,
          gender: _partner.partnerGender,
          calendarType: _partner.partnerCalendarType,
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
          partner: _effectiveNeedsPartner ? _partner : null,
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

  bool get _canProceed {
    if (_step == 0) {
      final meOk = _user.birthDate != null &&
          !_hasInvalidTimeInput(_user.birthTime, _user.birthTimeUnknown);
      final pOk = !_effectiveNeedsPartner ||
          (_partner.partnerBirthDate != null &&
              !_hasInvalidTimeInput(
                _partner.partnerBirthTime,
                _partner.partnerBirthTimeUnknown,
              ));
      return meOk && pOk;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final title = categoryList
        .firstWhere((c) => c.category == widget.category)
        .plainName;
    final steps = ['기본정보', '사주 확인', '질문'];
    return Scaffold(
      body: PageBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  _TopBar(title: title, onBack: _back),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(steps.length, (i) {
                            final active = i <= _step;
                            return Expanded(
                              child: Container(
                                height: 3.5,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color:
                                      active ? AppColors.gold : AppColors.muted,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_step + 1} / ${steps.length} · ${steps[_step]}',
                          style: AppTheme.sans(
                            size: 12,
                            weight: FontWeight.w500,
                            color: AppColors.mutedForeground,
                            height: 1,
                          ),
                        ),
                      ],
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
                    child: _step == 0
                        ? Opacity(
                            opacity: _canProceed ? 1.0 : 0.45,
                            child: GradientButton(
                              label: '내 사주 계산하기',
                              icon: Icons.auto_awesome,
                              gold: false,
                              onPressed: _canProceed ? _next : null,
                            ),
                          )
                        : Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SoftOutlineButton(
                                    label: '이전', onPressed: _back),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 4,
                                child: GradientButton(
                                  label: _step == 1
                                      ? '맞아요, 다음으로'
                                      : '리포트 받기',
                                  icon: _step == 2 ? Icons.auto_awesome : null,
                                  gold: false,
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
          category: widget.category,
          user: _user,
          partner: _categoryAllowsPartner ? _partner : null,
          includePartnerInLove: _includePartnerInLove,
          onIncludePartnerChanged: (v) {
            setState(() => _includePartnerInLove = v);
          },
          onChanged: () => setState(() {}),
        );
      case 1:
        return _StepConfirm(
          user: _user,
          partner: _effectiveNeedsPartner ? _partner : null,
          onChanged: () => setState(() {}),
        );
      default:
        return _StepQuestion(
            category: widget.category, controller: _questionCtrl);
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
  final AnalysisCategory category;
  final UserProfile user;
  final PartnerProfile? partner;
  final bool includePartnerInLove;
  final ValueChanged<bool> onIncludePartnerChanged;
  final VoidCallback onChanged;

  const _StepBasicInfo({
    required this.category,
    required this.user,
    required this.partner,
    required this.includePartnerInLove,
    required this.onIncludePartnerChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final showPartnerToggle = category == AnalysisCategory.love;
    final showPartnerForm = partner != null &&
        (category == AnalysisCategory.compatibility ||
            (category == AnalysisCategory.love && includePartnerInLove));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('내 정보',
            style: AppTheme.serif(
                size: 20, weight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 14),
        _PersonForm(
          label: '',
          name: user.userName,
          gender: user.gender,
          date: user.birthDate,
          calendar: user.calendarType,
          time: user.birthTime,
          timeUnknown: user.birthTimeUnknown,
          place: user.birthPlace,
          applyLocalTime: user.applyLocalTime,
          onName: (v) {
            user.userName = v;
            onChanged();
          },
          onGender: (v) {
            user.gender = v;
            user.manualOverride = false;
            onChanged();
          },
          onDate: (v) {
            user.birthDate = v;
            user.manualOverride = false;
            onChanged();
          },
          onCalendar: (v) {
            user.calendarType = v;
            if (user.birthDate != null) {
              user.birthDate =
                  _InputScreenState._clampDateForCalendar(user.birthDate!, v);
            }
            user.manualOverride = false;
            onChanged();
          },
          onTime: (v) {
            user.birthTime = v;
            user.manualOverride = false;
            onChanged();
          },
          onTimeUnknown: (v) {
            user.birthTimeUnknown = v;
            user.manualOverride = false;
            onChanged();
          },
          onPlace: (v) {
            user.birthPlace = v;
            user.manualOverride = false;
            onChanged();
          },
          onApplyLocalTime: (v) {
            user.applyLocalTime = v;
            user.manualOverride = false;
            onChanged();
          },
        ),
        if (showPartnerToggle) ...[
          const SizedBox(height: 16),
          SoftCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('상대방 정보 입력 여부',
                    style: AppTheme.sans(
                        size: 13,
                        weight: FontWeight.w700,
                        color: AppColors.primary)),
                const SizedBox(height: 10),
                _Choice(
                  options: const {
                    'with_partner': '상대방과 함께 분석',
                    'solo': '솔로 · 내 연애운만 보기',
                  },
                  value: includePartnerInLove ? 'with_partner' : 'solo',
                  onChanged: (v) =>
                      onIncludePartnerChanged(v == 'with_partner'),
                ),
              ],
            ),
          ),
        ],
        if (showPartnerForm) ...[
          const SizedBox(height: 22),
          Text('상대방 정보',
              style: AppTheme.serif(
                  size: 20, weight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 14),
          _RelationSelector(
            value: partner!.relationStatus,
            onChanged: (v) {
              partner!.relationStatus = v;
              onChanged();
            },
          ),
          const SizedBox(height: 16),
          _PersonForm(
            label: '',
            name: partner!.partnerName,
            gender: partner!.partnerGender,
            date: partner!.partnerBirthDate,
            calendar: partner!.partnerCalendarType,
            time: partner!.partnerBirthTime,
            timeUnknown: partner!.partnerBirthTimeUnknown,
            place: partner!.partnerBirthPlace,
            applyLocalTime: partner!.partnerApplyLocalTime,
            onName: (v) {
              partner!.partnerName = v;
              onChanged();
            },
            onGender: (v) {
              partner!.partnerGender = v;
              partner!.partnerManualOverride = false;
              onChanged();
            },
            onDate: (v) {
              partner!.partnerBirthDate = v;
              partner!.partnerManualOverride = false;
              onChanged();
            },
            onCalendar: (v) {
              partner!.partnerCalendarType = v;
              if (partner!.partnerBirthDate != null) {
                partner!.partnerBirthDate =
                    _InputScreenState._clampDateForCalendar(
                  partner!.partnerBirthDate!,
                  v,
                );
              }
              partner!.partnerManualOverride = false;
              onChanged();
            },
            onTime: (v) {
              partner!.partnerBirthTime = v;
              partner!.partnerManualOverride = false;
              onChanged();
            },
            onTimeUnknown: (v) {
              partner!.partnerBirthTimeUnknown = v;
              partner!.partnerManualOverride = false;
              onChanged();
            },
            onPlace: (v) {
              partner!.partnerBirthPlace = v;
              partner!.partnerManualOverride = false;
              onChanged();
            },
            onApplyLocalTime: (v) {
              partner!.partnerApplyLocalTime = v;
              partner!.partnerManualOverride = false;
              onChanged();
            },
          ),
        ],
      ],
    );
  }
}

class _PersonForm extends StatefulWidget {
  final String label;
  final String name;
  final String gender;
  final DateTime? date;
  final String calendar;
  final String? time;
  final bool timeUnknown;
  final String? place;
  final bool applyLocalTime;
  final ValueChanged<String> onName;
  final ValueChanged<String> onGender;
  final ValueChanged<DateTime> onDate;
  final ValueChanged<String> onCalendar;
  final ValueChanged<String?> onTime;
  final ValueChanged<bool> onTimeUnknown;
  final ValueChanged<String?> onPlace;
  final ValueChanged<bool> onApplyLocalTime;

  const _PersonForm({
    required this.label,
    required this.name,
    required this.gender,
    required this.date,
    required this.calendar,
    required this.time,
    required this.timeUnknown,
    required this.place,
    required this.applyLocalTime,
    required this.onName,
    required this.onGender,
    required this.onDate,
    required this.onCalendar,
    required this.onTime,
    required this.onTimeUnknown,
    required this.onPlace,
    required this.onApplyLocalTime,
  });

  @override
  State<_PersonForm> createState() => _PersonFormState();
}

class _PersonFormState extends State<_PersonForm> {
  late final TextEditingController _nameCtrl;

  /// 선택 항목(이름·출생지역·시간 보정)을 펼쳤는지 여부.
  bool _showMore = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.name);
    // 이미 입력해 둔 값이 있으면 숨기지 않는다.
    _showMore = widget.name.trim().isNotEmpty ||
        (widget.place?.trim().isNotEmpty ?? false);
  }

  @override
  void didUpdateWidget(covariant _PersonForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.name != _nameCtrl.text) {
      _nameCtrl.value = TextEditingValue(
        text: widget.name,
        selection: TextSelection.collapsed(offset: widget.name.length),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// 양력 및 음력(평달·윤달, 음력 2월 29·30일 포함)을 모두 정확히 선택할 수 있는 만세력 전용 연·월·일 다이얼로그
  Future<void> _showManseryeokDatePicker(BuildContext context) async {
    final nowKst = SajuCalculator.nowKst();
    int selYear = widget.date?.year ?? 1998;
    int selMonth = widget.date?.month ?? 5;
    int selDay = widget.date?.day ?? 15;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final maxDay = _InputScreenState._maxValidDay(
            selYear,
            selMonth,
            widget.calendar,
          );
          if (selDay > maxDay) selDay = maxDay;

          final leapMonthInYear = LunarConverter.leapMonthOfYear(selYear);
          final isLunar =
              widget.calendar == 'lunar' || widget.calendar == 'lunar_leap';
          final calLabel = switch (widget.calendar) {
            'lunar' => '음력(평달)',
            'lunar_leap' => '음력(윤달)',
            _ => '양력',
          };

          // 변환 미리보기
          String previewText = '';
          if (isLunar) {
            final conv = LunarConverter.toSolar(
              selYear,
              selMonth,
              selDay,
              isLeapMonth: widget.calendar == 'lunar_leap',
            );
            if (conv != null) {
              previewText =
                  '→ 양력 ${conv.solarDate.year}년 ${conv.solarDate.month}월 ${conv.solarDate.day}일 (${maxDay == 30 ? "대월 30일" : "소월 29일"})';
            }
          }

          return AlertDialog(
            title: Text(
              '생년월일 선택 ($calLabel)',
              style: AppTheme.serif(size: 16, weight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<int>(
                        initialValue: selYear,
                        decoration: _dec('연도'),
                        items: List.generate(
                          nowKst.year - 1920 + 1,
                          (i) => 1920 + i,
                        ).reversed.map((y) {
                          return DropdownMenuItem(
                            value: y,
                            child: Text('$y년', style: AppTheme.sans(size: 13.5)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => selYear = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int>(
                        initialValue: selMonth,
                        decoration: _dec('월'),
                        items: List.generate(12, (i) => i + 1).map((m) {
                          final isLeapM = isLunar && leapMonthInYear == m;
                          return DropdownMenuItem(
                            value: m,
                            child: Text(
                              isLeapM ? '$m월(윤)' : '$m월',
                              style: AppTheme.sans(size: 13.5),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => selMonth = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int>(
                        key: ValueKey('day_${selYear}_${selMonth}_$maxDay'),
                        initialValue: selDay,
                        decoration: _dec('일'),
                        items: List.generate(maxDay, (i) => i + 1).map((d) {
                          return DropdownMenuItem(
                            value: d,
                            child: Text('$d일', style: AppTheme.sans(size: 13.5)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => selDay = v);
                        },
                      ),
                    ),
                  ],
                ),
                if (previewText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    previewText,
                    style: AppTheme.sans(
                      size: 12,
                      weight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ],
                if (widget.calendar == 'lunar_leap' &&
                    leapMonthInYear != selMonth) ...[
                  const SizedBox(height: 8),
                  Text(
                    '※ $selYear년의 윤달은 ${leapMonthInYear != null ? "윤$leapMonthInYear월" : "없음"}이므로 $selMonth월은 평달 기준으로 자동 변환됩니다.',
                    style: AppTheme.sans(
                      size: 11.5,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onDate(DateTime(selYear, selMonth, selDay));
                  Navigator.of(ctx).pop();
                },
                child: const Text('선택 완료'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatSolarOffset(int minutes) =>
      minutes >= 0 ? '+$minutes분' : '$minutes분';

  Future<void> _showAnimatedTimePicker(BuildContext context) async {
    final parsed = _InputScreenState._parseTime(widget.time);
    final initHour = parsed?.$1 ?? 12;
    final initMin = parsed?.$2 ?? 0;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '출생시간 선택 닫기',
      barrierColor: Colors.black.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, anim, secondaryAnim) => _BirthTimePickerDialog(
        initialHour24: initHour,
        initialMinute: initMin,
        hasExistingValue: parsed != null,
        placeName: widget.place,
        birthDate: widget.date,
        applyLocalTime: widget.applyLocalTime,
        onClear: () => widget.onTime(null),
        onConfirm: (h24, m) {
          final hh = h24.toString().padLeft(2, '0');
          final mm = m.toString().padLeft(2, '0');
          widget.onTime('$hh:$mm');
        },
      ),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  String _formatDisplayTime(String? rawTime) {
    final parsed = _InputScreenState._parseTime(rawTime);
    if (parsed == null) return '출생시간을 선택하세요 (오전/오후 · 시 · 분)';
    final h24 = parsed.$1;
    final m = parsed.$2;
    final period = h24 < 12 ? '오전' : '오후';
    final h12 = (h24 % 12 == 0) ? 12 : (h24 % 12);
    final mm = m.toString().padLeft(2, '0');
    final preview = SajuExplainer.describeSijin(
      hour24: h24,
      minute: m,
      placeName: widget.place,
      birthDate: widget.date,
      applyLocalTime: widget.applyLocalTime,
    );
    return '$period $h12시 $mm분 · ${preview.sijinLabel}';
  }

  void _showBirthPlacePicker(BuildContext context) {
    String query = '';
    String selectedGroup = '전체';
    final currentSelected = findBirthPlace(widget.place);

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final filtered = birthPlaces.where((p) {
            final groupMatch =
                selectedGroup == '전체' || p.group == selectedGroup;
            return groupMatch && p.matchesQuery(query);
          }).toList();

          return AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            contentPadding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
            actionsPadding: const EdgeInsets.fromLTRB(12, 0, 16, 12),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    '출생지역 선택',
                    style: AppTheme.serif(size: 16, weight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${filtered.length}개 지역',
                  style: AppTheme.sans(
                    size: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: _dec(
                      '시·군 검색 (예: 용인, 천안, 마산, 분당)',
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 18,
                        color: AppColors.gold,
                      ),
                    ),
                    onChanged: (v) => setDialogState(() => query = v),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: birthPlaceGroups.map((g) {
                        final active = g == selectedGroup;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () =>
                                setDialogState(() => selectedGroup = g),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.muted,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                g,
                                style: AppTheme.sans(
                                  size: 12,
                                  weight: active
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: active
                                      ? Colors.white
                                      : AppColors.mutedForeground,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '일치하는 시·군이 없습니다.\n인근 시·군 이름으로 검색해 보세요.',
                                  textAlign: TextAlign.center,
                                  style: AppTheme.sans(
                                    size: 13,
                                    color: AppColors.mutedForeground,
                                    height: 1.5,
                                  ),
                                ),
                                if (selectedGroup != '전체') ...[
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => setDialogState(
                                        () => selectedGroup = '전체'),
                                    child: const Text('전체 지역에서 다시 찾기'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (listCtx, idx) => const Divider(
                              height: 1,
                              color: AppColors.muted,
                            ),
                            itemBuilder: (listCtx, i) {
                              final p = filtered[i];
                              final isSelected =
                                  currentSelected?.name == p.name;
                              final offsetMin = trueSolarOffsetMinutes(
                                p.name,
                                birthDate: widget.date,
                              ).round();
                              return InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  widget.onPlace(p.name);
                                  Navigator.of(ctx).pop();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                            .withValues(alpha: 0.08)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.muted,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          p.region,
                                          style: AppTheme.sans(
                                            size: 11,
                                            weight: FontWeight.w600,
                                            color: AppColors.mutedForeground,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          p.name,
                                          style: AppTheme.sans(
                                            size: 14,
                                            weight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '진태양시 ${_formatSolarOffset(offsetMin)}',
                                        style: AppTheme.sans(
                                          size: 11.5,
                                          color: AppColors.mutedForeground,
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: AppColors.gold,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              if (widget.place != null)
                TextButton(
                  onPressed: () {
                    widget.onPlace(null);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('선택 해제'),
                ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('닫기'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: AppTheme.sans(
          size: 13,
          weight: FontWeight.w700,
          color: AppColors.primary,
          height: 1.2,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isLunar =
        widget.calendar == 'lunar' || widget.calendar == 'lunar_leap';
    final invalidTime = _InputScreenState._hasInvalidTimeInput(
      widget.time,
      widget.timeUnknown,
    );

    String dateLabel = '생년월일을 선택하세요';
    if (widget.date != null) {
      final d = widget.date!;
      final calTag = switch (widget.calendar) {
        'lunar' => '음력 평달',
        'lunar_leap' => '음력 윤달',
        _ => '양력',
      };
      dateLabel = '${d.year}년 ${d.month}월 ${d.day}일 ($calTag)';
    }

    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label.isNotEmpty) ...[
            Text(widget.label,
                style: AppTheme.serif(size: 16, weight: FontWeight.w700)),
            const SizedBox(height: 14),
          ],
          _fieldLabel('성별'),
          const SizedBox(height: 8),
          _Choice(
            options: const {'male': '남성', 'female': '여성'},
            value: widget.gender,
            onChanged: widget.onGender,
          ),
          const SizedBox(height: 16),
          _fieldLabel('생년월일'),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showManseryeokDatePicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppColors.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: AppTheme.sans(
                          size: 14,
                          color: widget.date == null
                              ? AppColors.mutedForeground
                              : AppColors.primary,
                          height: 1.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _fieldLabel('양력 / 음력'),
          const SizedBox(height: 8),
          _Choice(
            options: const {
              'solar': '양력',
              'lunar': '음력(평달)',
              'lunar_leap': '음력(윤달)',
            },
            value: widget.calendar,
            onChanged: widget.onCalendar,
          ),
          if (isLunar) ...[
            const SizedBox(height: 8),
            Text(
              '※ 한국천문연구원 표준 만세력 기준으로 음력(평달·윤달)을 양력으로 정밀 변환합니다.',
              style: AppTheme.sans(
                size: 11.5,
                color: AppColors.mutedForeground,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _fieldLabel('출생시간'),
          const SizedBox(height: 8),
          Opacity(
            opacity: widget.timeUnknown ? 0.45 : 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.timeUnknown
                  ? null
                  : () => _showAnimatedTimePicker(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_outlined,
                      size: 18,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        layoutBuilder: (currentChild, previousChildren) =>
                            Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        ),
                        child: Text(
                          widget.timeUnknown
                              ? '시간은 빼고 분석해요'
                              : _formatDisplayTime(widget.time),
                          key: ValueKey(
                            '${widget.timeUnknown}_${widget.time}_${widget.place}_${widget.applyLocalTime}',
                          ),
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.sans(
                            size: 14,
                            color: (!widget.timeUnknown &&
                                    _InputScreenState._parseTime(widget.time) !=
                                        null)
                                ? AppColors.primary
                                : AppColors.mutedForeground,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.mutedForeground,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (invalidTime) ...[
            const SizedBox(height: 6),
            Text(
              '※ 출생시간을 다시 선택하거나 [출생시간 모름]을 체크해 주세요.',
              style: AppTheme.sans(
                size: 11.5,
                weight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
          ],
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => widget.onTimeUnknown(!widget.timeUnknown),
            child: Row(
              children: [
                Checkbox(
                  value: widget.timeUnknown,
                  activeColor: AppColors.gold,
                  side: const BorderSide(
                      color: AppColors.mutedForeground, width: 1.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  visualDensity: VisualDensity.compact,
                  onChanged: (v) => widget.onTimeUnknown(v ?? false),
                ),
                Expanded(
                  child: Text('태어난 시간을 몰라요 (시간 빼고 분석)',
                      style: AppTheme.sans(
                          size: 12.5,
                          color: AppColors.mutedForeground,
                          height: 1.3)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // 선택 항목은 접어 두고, 원하는 사람만 펼쳐서 입력한다.
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _showMore = !_showMore),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(_showMore ? Icons.remove : Icons.add,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('더 정확하게 보기 · 이름, 태어난 지역 (선택)',
                        style: AppTheme.sans(
                            size: 13,
                            weight: FontWeight.w600,
                            color: AppColors.accent,
                            height: 1.3)),
                  ),
                ],
              ),
            ),
          ),
          if (_showMore) ...[
          const SizedBox(height: 8),
          _fieldLabel('이름 / 닉네임'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: _dec('예: 홍길동'),
            onChanged: widget.onName,
          ),
          const SizedBox(height: 16),
          _fieldLabel('출생지역'),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final selectedPlace = findBirthPlace(widget.place);
              final rawPlace = widget.place?.trim() ?? '';
              String placeLabel = '출생지역 선택 (전국 161개 시·군 검색)';
              if (selectedPlace != null) {
                final displayTitle = (selectedPlace.region ==
                            selectedPlace.name ||
                        selectedPlace.name
                            .startsWith('${selectedPlace.region} '))
                    ? selectedPlace.name
                    : '${selectedPlace.region} · ${selectedPlace.name}';
                final offsetMin = trueSolarOffsetMinutes(
                  selectedPlace.name,
                  birthDate: widget.date,
                ).round();
                placeLabel =
                    '$displayTitle (시간 보정 ${_formatSolarOffset(offsetMin)})';
              } else if (rawPlace.isNotEmpty) {
                placeLabel = rawPlace;
              }
              final hasPlace = rawPlace.isNotEmpty;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showBirthPlacePicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          placeLabel,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.sans(
                            size: 14,
                            color: hasPlace
                                ? AppColors.primary
                                : AppColors.mutedForeground,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.mutedForeground,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => widget.onApplyLocalTime(!widget.applyLocalTime),
            child: Row(
              children: [
                Checkbox(
                  value: widget.applyLocalTime,
                  activeColor: AppColors.gold,
                  side: const BorderSide(
                      color: AppColors.mutedForeground, width: 1.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  visualDensity: VisualDensity.compact,
                  onChanged: (v) => widget.onApplyLocalTime(v ?? true),
                ),
                Expanded(
                  child: Text('태어난 지역에 맞춰 시간 보정',
                      style: AppTheme.sans(
                          size: 12.5,
                          color: AppColors.mutedForeground,
                          height: 1.3)),
                ),
              ],
            ),
          ),
          ],
        ],
      ),
    );
  }

  InputDecoration _dec(String hint, {Widget? prefixIcon}) => InputDecoration(
        hintText: hint,
        hintStyle:
            AppTheme.sans(size: 13.5, color: AppColors.mutedForeground),
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: AppColors.muted,
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((e) {
        final active = e.key == value;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(e.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.muted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              e.value,
              style: AppTheme.sans(
                size: 13.5,
                weight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? Colors.white : AppColors.mutedForeground,
                height: 1,
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
    const options = ['썸·호감', '연애 중', '권태기', '이별 후', '재회 고민', '부부·결혼 준비'];
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

// ── 2단계: 명식 확인 (K04 Session Lock + K08 경계 안내 + 수동 명식 수정 우회로) ──
class _StepConfirm extends StatelessWidget {
  final UserProfile user;
  final PartnerProfile? partner;
  final VoidCallback onChanged;
  const _StepConfirm({
    required this.user,
    required this.partner,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final mySaju = user.toSaju();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('이 값이 맞나요?',
            style: AppTheme.serif(
                size: 21, weight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 6),
        Text(
          '만세력으로 자동 계산한 사주입니다. 다르면 직접 고칠 수 있어요.',
          style: AppTheme.sans(size: 13.5, color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 16),
        _PillarConfirmCard(
          title: '내 사주 (${user.userName.isEmpty ? "본인" : user.userName})',
          personName: user.userName,
          saju: mySaju,
          onEdit: () => _showEditDialog(
            context: context,
            label: '내 사주 직접 고치기',
            initialY: user.yearPillar ?? '',
            initialM: user.monthPillar ?? '',
            initialD: user.dayPillar ?? '',
            initialH: user.hourPillar ?? '',
            hourUnknown: user.birthTimeUnknown,
            onSave: (y, m, d, h) {
              final recalc = SajuCalculator.recalculateWithManualPillars(
                yearPillar: y,
                monthPillar: m,
                dayPillar: d,
                hourPillar: h.isEmpty ? null : h,
                gender: user.gender,
                birthDate: user.birthDate,
                calendarType: user.calendarType,
              );
              user.applySaju(recalc, isManual: true);
              user.birthTimeUnknown = h.isEmpty;
              onChanged();
            },
          ),
        ),
        if (partner != null) ...[
          const SizedBox(height: 14),
          _PillarConfirmCard(
            title:
                '상대의 사주 (${partner!.partnerName.isEmpty ? "상대" : partner!.partnerName})',
            personName: partner!.partnerName,
            saju: partner!.toSaju(),
            onEdit: () => _showEditDialog(
              context: context,
              label: '상대 사주 직접 고치기',
              initialY: partner!.partnerYearPillar ?? '',
              initialM: partner!.partnerMonthPillar ?? '',
              initialD: partner!.partnerDayPillar ?? '',
              initialH: partner!.partnerHourPillar ?? '',
              hourUnknown: partner!.partnerBirthTimeUnknown,
              onSave: (y, m, d, h) {
                final recalc = SajuCalculator.recalculateWithManualPillars(
                  yearPillar: y,
                  monthPillar: m,
                  dayPillar: d,
                  hourPillar: h.isEmpty ? null : h,
                  gender: partner!.partnerGender,
                  birthDate: partner!.partnerBirthDate,
                  calendarType: partner!.partnerCalendarType,
                );
                partner!.applySaju(recalc, isManual: true);
                partner!.partnerBirthTimeUnknown = h.isEmpty;
                onChanged();
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showEditDialog({
    required BuildContext context,
    required String label,
    required String initialY,
    required String initialM,
    required String initialD,
    required String initialH,
    required bool hourUnknown,
    required void Function(String y, String m, String d, String h) onSave,
  }) async {
    final yCtrl = TextEditingController(text: initialY);
    final mCtrl = TextEditingController(text: initialM);
    final dCtrl = TextEditingController(text: initialD);
    final hCtrl = TextEditingController(text: hourUnknown ? '' : initialH);
    String? errorMsg;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(label,
              style: AppTheme.serif(size: 16, weight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '60갑자에 존재하는 한글 2글자 간지(예: 갑자, 병인, 무오)로 입력하세요.\n시간 미상이면 시주를 비워두세요.',
                  style: AppTheme.sans(
                      size: 12, color: AppColors.mutedForeground),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: yCtrl,
                  decoration: const InputDecoration(labelText: '년주 (예: 경진)'),
                ),
                TextField(
                  controller: mCtrl,
                  decoration: const InputDecoration(labelText: '월주 (예: 무인)'),
                ),
                TextField(
                  controller: dCtrl,
                  decoration: const InputDecoration(labelText: '일주 (예: 갑오)'),
                ),
                TextField(
                  controller: hCtrl,
                  decoration:
                      const InputDecoration(labelText: '시주 (선택, 비우면 시간 미상)'),
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorMsg!,
                    style: AppTheme.sans(
                        size: 12,
                        weight: FontWeight.w600,
                        color: Colors.redAccent),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final y = yCtrl.text.trim();
                final m = mCtrl.text.trim();
                final d = dCtrl.text.trim();
                final h = hCtrl.text.trim();
                if (!isValidGanzhiPillar(y)) {
                  setDialogState(
                      () => errorMsg = '년주("$y")가 유효한 60갑자 한글 2글자가 아닙니다.');
                  return;
                }
                if (!isValidGanzhiPillar(m)) {
                  setDialogState(
                      () => errorMsg = '월주("$m")가 유효한 60갑자 한글 2글자가 아닙니다.');
                  return;
                }
                if (!isValidGanzhiPillar(d)) {
                  setDialogState(
                      () => errorMsg = '일주("$d")가 유효한 60갑자 한글 2글자가 아닙니다.');
                  return;
                }
                if (h.isNotEmpty && !isValidGanzhiPillar(h)) {
                  setDialogState(() => errorMsg =
                      '시주("$h")가 유효한 60갑자 한글 2글자가 아닙니다. (모르면 비워두세요)');
                  return;
                }
                onSave(y, m, d, h);
                Navigator.of(ctx).pop();
              },
              child: const Text('저장하기'),
            ),
          ],
        ),
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
        Text('무엇이 가장 궁금하신가요?',
            style: AppTheme.serif(
                size: 21, weight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 6),
        Text(
          '구체적으로 적을수록 질문에 꼭 맞춘 현실적인 답을 드릴 수 있어요. (선택)',
          style: AppTheme.sans(size: 13.5, color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 16),
        SoftCard(
          padding: const EdgeInsets.all(14),
          child: TextField(
            controller: controller,
            maxLines: 5,
            style: AppTheme.serif(
              size: 16,
              weight: FontWeight.w600,
              color: AppColors.primary,
              height: 1.55,
            ),
            decoration: InputDecoration(
              hintText: '고민을 자유롭게 적어주세요.',
              hintStyle: AppTheme.sans(
                size: 14,
                color: AppColors.mutedForeground,
                height: 1.5,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(6),
            ),
          ),
        ),
        const SizedBox(height: 14),
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
                  color: AppColors.muted.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.45), width: 1),
                ),
                child: Text(ex,
                    style: AppTheme.sans(
                        size: 13,
                        color: AppColors.primary,
                        weight: FontWeight.w500,
                        height: 1.3)),
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
        return [
          '내 타고난 강점과 올해 2026년 흐름이 궁금해요.',
          '올해(2026)랑 내년(2027) 중 언제가 이직·도전에 더 유리할까요?',
          '내 사주에 맞는 일하는 방식과 재물 관리 전략을 알려주세요.',
        ];
      case AnalysisCategory.love:
        return [
          '그 사람이 저를 어떻게 생각할까요? 지금 다가가는 게 맞을까요?',
          '연애할 때 제 자존심도 지키면서 편안하게 만나는 소통법이 궁금해요.',
          '나에게 정말 잘 맞는 배우자·연인의 정서적 결은 어떤 사람인가요?',
        ];
      case AnalysisCategory.pattern:
        return [
          '왜 중요한 순간마다 비슷한 피로감과 관계 패턴을 반복할까요?',
          '내 멘탈 소모를 줄이고 에너지를 제대로 쓰는 현실 해법을 알려주세요.',
        ];
      case AnalysisCategory.compatibility:
        return [
          '우리 두 사람 궁합 점수와 서로 끌리는 점, 조심할 갈등 포인트가 궁금해요.',
          '이 사람과 오래 안정적으로 만나려면 어떤 대화 규칙이 필요할까요?',
        ];
    }
  }
}

/// 애니메이션 3단 드럼 휠 출생시간 선택 다이얼로그 (실시간 12시진·진태양시 프리뷰)
class _BirthTimePickerDialog extends StatefulWidget {
  final int initialHour24;
  final int initialMinute;
  final bool hasExistingValue;
  final String? placeName;
  final DateTime? birthDate;
  final bool applyLocalTime;
  final VoidCallback onClear;
  final void Function(int hour24, int minute) onConfirm;

  const _BirthTimePickerDialog({
    required this.initialHour24,
    required this.initialMinute,
    required this.hasExistingValue,
    required this.placeName,
    required this.birthDate,
    required this.applyLocalTime,
    required this.onClear,
    required this.onConfirm,
  });

  @override
  State<_BirthTimePickerDialog> createState() => _BirthTimePickerDialogState();
}

class _BirthTimePickerDialogState extends State<_BirthTimePickerDialog> {
  late int _periodIdx; // 0: 오전, 1: 오후
  late int _hour12Idx; // 0..11 -> 1시..12시
  late int _minuteIdx; // 0..59 -> 00분..59분

  late final FixedExtentScrollController _periodCtrl;
  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minuteCtrl;

  @override
  void initState() {
    super.initState();
    _periodIdx = widget.initialHour24 < 12 ? 0 : 1;
    final h12 = (widget.initialHour24 % 12 == 0)
        ? 12
        : (widget.initialHour24 % 12);
    _hour12Idx = h12 - 1;
    _minuteIdx = widget.initialMinute.clamp(0, 59);

    _periodCtrl = FixedExtentScrollController(initialItem: _periodIdx);
    _hourCtrl = FixedExtentScrollController(initialItem: _hour12Idx);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minuteIdx);
  }

  @override
  void dispose() {
    _periodCtrl.dispose();
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  int get _hour24 {
    final h12 = _hour12Idx + 1;
    if (_periodIdx == 0) {
      return h12 == 12 ? 0 : h12;
    }
    return h12 == 12 ? 12 : h12 + 12;
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required int selectedIndex,
    required String Function(int index) labelBuilder,
    required ValueChanged<int> onChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 42,
      diameterRatio: 1.45,
      perspective: 0.003,
      magnification: 1.12,
      useMagnifier: true,
      overAndUnderCenterOpacity: 0.36,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (ctx, idx) {
          final isSelected = idx == selectedIndex;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              controller.animateToItem(
                idx,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
              );
            },
            child: Center(
              child: Text(
                labelBuilder(idx),
                style: AppTheme.sans(
                  size: 16,
                  weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.mutedForeground,
                  height: 1.1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h24 = _hour24;
    final hh = h24.toString().padLeft(2, '0');
    final mm = _minuteIdx.toString().padLeft(2, '0');
    final preview = SajuExplainer.describeSijin(
      hour24: h24,
      minute: _minuteIdx,
      placeName: widget.placeName,
      birthDate: widget.birthDate,
      applyLocalTime: widget.applyLocalTime,
    );

    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 16, 14),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '출생시간 선택',
              style: AppTheme.serif(size: 16, weight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$hh:$mm',
              style: AppTheme.sans(
                size: 12.5,
                weight: FontWeight.w700,
                color: AppColors.goldLight,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 실시간 12시진 + 진태양시 애니메이션 프리뷰 배너
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.38),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.14),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Column(
                  key: ValueKey('${preview.sijinLabel}_${preview.note}'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          preview.sijinLabel,
                          style: AppTheme.serif(
                            size: 14,
                            weight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      preview.note,
                      style: AppTheme.sans(
                        size: 11.5,
                        color: AppColors.mutedForeground,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // 컬럼 헤더
            Row(
              children: [
                Expanded(
                  child: Text(
                    '오전/오후',
                    textAlign: TextAlign.center,
                    style: AppTheme.sans(
                      size: 11.5,
                      weight: FontWeight.w600,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '시',
                    textAlign: TextAlign.center,
                    style: AppTheme.sans(
                      size: 11.5,
                      weight: FontWeight.w600,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '분',
                    textAlign: TextAlign.center,
                    style: AppTheme.sans(
                      size: 11.5,
                      weight: FontWeight.w600,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // 3단 드럼 휠 피커
            SizedBox(
              height: 176,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 중앙 선택 하이라이트 바
                  IgnorePointer(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.muted.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.45),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildWheel(
                          controller: _periodCtrl,
                          itemCount: 2,
                          selectedIndex: _periodIdx,
                          labelBuilder: (i) => i == 0 ? '오전' : '오후',
                          onChanged: (i) => setState(() => _periodIdx = i),
                        ),
                      ),
                      Expanded(
                        child: _buildWheel(
                          controller: _hourCtrl,
                          itemCount: 12,
                          selectedIndex: _hour12Idx,
                          labelBuilder: (i) => '${i + 1}시',
                          onChanged: (i) => setState(() => _hour12Idx = i),
                        ),
                      ),
                      Expanded(
                        child: _buildWheel(
                          controller: _minuteCtrl,
                          itemCount: 60,
                          selectedIndex: _minuteIdx,
                          labelBuilder: (i) =>
                              '${i.toString().padLeft(2, '0')}분',
                          onChanged: (i) => setState(() => _minuteIdx = i),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '위아래로 드래그하거나 숫자를 눌러 부드럽게 선택하세요',
              style: AppTheme.sans(
                size: 11,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.hasExistingValue)
          TextButton(
            onPressed: () {
              widget.onClear();
              Navigator.of(context).pop();
            },
            child: const Text('초기화'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(_hour24, _minuteIdx);
            Navigator.of(context).pop();
          },
          child: const Text('선택 완료'),
        ),
      ],
    );
  }
}

/// STEP 2 명식 확인 카드 — 4주 팩트 + 대화체 초보자 쉬운 해설 + 접힘식 전체 대운표
class _PillarConfirmCard extends StatefulWidget {
  final String title;
  final String personName;
  final SajuResult saju;
  final VoidCallback onEdit;

  const _PillarConfirmCard({
    required this.title,
    required this.personName,
    required this.saju,
    required this.onEdit,
  });

  @override
  State<_PillarConfirmCard> createState() => _PillarConfirmCardState();
}

class _PillarConfirmCardState extends State<_PillarConfirmCard> {
  bool _showDetails = false;

  static const Map<String, Color> _elementColors = {
    '목': Color(0xFF5A8F69),
    '화': Color(0xFFC96B59),
    '토': Color(0xFFC9A646),
    '금': Color(0xFF7B8499),
    '수': Color(0xFF3E6C93),
  };

  @override
  Widget build(BuildContext context) {
    final saju = widget.saju;
    final easy = SajuExplainer.explain(saju, userName: widget.personName);

    final items = [
      ('년주', saju.yearPillar, saju.yearPillarHanja),
      ('월주', saju.monthPillar, saju.monthPillarHanja),
      ('일주', saju.dayPillar, saju.dayPillarHanja),
      (
        '시주',
        saju.hourUnknown ? '—' : (saju.hourPillar ?? '—'),
        saju.hourUnknown ? '' : (saju.hourPillarHanja ?? '')
      ),
    ];

    final infoLines = <String>[
      if (saju.hourUnknown) '출생시간을 몰라 시주는 계산에서 제외했습니다 (3주 6글자 기준 분석).',
      ...saju.boundaryWarnings,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SoftCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 헤더 + 수정 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTheme.serif(
                        size: 16,
                        weight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: widget.onEdit,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: AppColors.gold,
                    ),
                    label: Text(
                      '수정',
                      style: AppTheme.sans(
                        size: 13,
                        weight: FontWeight.w600,
                        color: AppColors.gold,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. 4주(년·월·일·시주) 팩트 카드
              Row(
                children: items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final e = entry.value;
                  final isDay = idx == 2;
                  return Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 4,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDay ? AppColors.primary : AppColors.muted,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            e.$1,
                            style: AppTheme.sans(
                              size: 11,
                              color: isDay
                                  ? Colors.white70
                                  : AppColors.mutedForeground,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            e.$2,
                            style: AppTheme.serif(
                              size: 19,
                              weight: FontWeight.w700,
                              color: isDay
                                  ? AppColors.goldLight
                                  : AppColors.primary,
                              height: 1.2,
                            ),
                          ),
                          if (e.$3.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              e.$3,
                              style: AppTheme.sans(
                                size: 11,
                                color: isDay
                                    ? AppColors.goldLight
                                        .withValues(alpha: 0.75)
                                    : AppColors.mutedForeground,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // 3. 쉽게 풀어 읽는 나의 명식 (대화체 해설)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3-1) 나를 상징하는 기운 (일간)
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 15,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '나를 상징하는 기운',
                          style: AppTheme.sans(
                            size: 12,
                            weight: FontWeight.w700,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              easy.dayMasterBadge,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.sans(
                                size: 11.5,
                                weight: FontWeight.w700,
                                color: AppColors.goldLight,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      easy.dayMasterStory,
                      style: AppTheme.sans(
                        size: 13.2,
                        color: AppColors.primary,
                        height: 1.55,
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: AppColors.muted),
                    ),

                    // 3-2) 오행 밸런스 (4주 8글자 / 시주 미상 시 3주 6글자)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '내 사주의 5가지 기운',
                          style: AppTheme.sans(
                            size: 12,
                            weight: FontWeight.w700,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                        Text(
                          easy.elementScopeLabel,
                          style: AppTheme.sans(
                            size: 11,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: easy.elementCounts.entries.map((entry) {
                        final key = entry.key;
                        final count = entry.value;
                        final ratio = easy.totalChars > 0
                            ? (count / easy.totalChars)
                            : 0.0;
                        final barColor =
                            _elementColors[key] ?? AppColors.primary;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      key,
                                      style: AppTheme.sans(
                                        size: 11.5,
                                        weight: FontWeight.w700,
                                        color: count == 0
                                            ? AppColors.mutedForeground
                                            : barColor,
                                      ),
                                    ),
                                    Text(
                                      '$count',
                                      style: AppTheme.sans(
                                        size: 11.5,
                                        weight: FontWeight.w700,
                                        color: count == 0
                                            ? AppColors.mutedForeground
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  height: 6,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.muted,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0, end: ratio),
                                    duration:
                                        const Duration(milliseconds: 450),
                                    curve: Curves.easeOutCubic,
                                    builder: (ctx, val, child) =>
                                        FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: val.clamp(0.0, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: barColor,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      easy.elementStory,
                      style: AppTheme.sans(
                        size: 12.8,
                        color: AppColors.primary,
                        height: 1.55,
                      ),
                    ),

                    // 3-3) 현재 10년 대운 쉬운 풀이
                    if (easy.currentDaeunBadge != null &&
                        easy.currentDaeunStory != null) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: AppColors.muted),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.timeline_rounded,
                            size: 15,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '지금 지나가는 10년 흐름 · ${easy.currentDaeunBadge}',
                              style: AppTheme.sans(
                                size: 12,
                                weight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        easy.currentDaeunStory!,
                        style: AppTheme.sans(
                          size: 12.8,
                          color: AppColors.primary,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 4. 접힘식 전체 대운 흐름 · 만세력 상세 보기
              if (saju.daeunSummary.isNotEmpty) ...[
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _showDetails = !_showDetails),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          easy.daeunDirectionLabel.isEmpty
                              ? '전체 대운 흐름 · 만세력 상세 보기'
                              : '전체 대운 흐름 보기 (${easy.daeunDirectionLabel})',
                          style: AppTheme.sans(
                            size: 12,
                            weight: FontWeight.w600,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                        AnimatedRotation(
                          turns: _showDetails ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 220),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (easy.daeunTimeline.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: easy.daeunTimeline.map((item) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: item.isCurrent
                                      ? AppColors.primary
                                      : AppColors.muted,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${item.pillar}(${item.hanja})',
                                      style: AppTheme.sans(
                                        size: 12,
                                        weight: FontWeight.w700,
                                        color: item.isCurrent
                                            ? AppColors.goldLight
                                            : AppColors.primary,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.isCurrent
                                          ? '${item.ageRange} · 현재'
                                          : item.ageRange,
                                      style: AppTheme.sans(
                                        size: 10.5,
                                        color: item.isCurrent
                                            ? Colors.white70
                                            : AppColors.mutedForeground,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          '• 원문 대운표: ${saju.daeunSummary}',
                          style: AppTheme.sans(
                            size: 11.2,
                            color: AppColors.mutedForeground,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: _showDetails
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 240),
                ),
              ],
            ],
          ),
        ),
        if (infoLines.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.noticeBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.info_outline,
                    size: 17,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: infoLines
                        .map(
                          (w) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              w,
                              style: AppTheme.sans(
                                size: 12,
                                color: AppColors.mutedForeground,
                                height: 1.45,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
