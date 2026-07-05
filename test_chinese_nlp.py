#!/usr/bin/env python3
"""
Plan-Reminder 中文 NLP 解析器 - 功能验证测试
将 Dart 代码中的正则和逻辑翻译为 Python，验证解析准确性。
"""

import re
from datetime import datetime, timedelta
from dataclasses import dataclass

# ============================================================
# Chinese mappings (identical to Dart version)
# ============================================================

WEEKDAY_MAP_ZH = {
    '周一': 0, '星期一': 0,
    '周二': 1, '星期二': 1,
    '周三': 2, '星期三': 2,
    '周四': 3, '星期四': 3,
    '周五': 4, '星期五': 4,
    '周六': 5, '星期六': 5,
    '周日': 6, '星期天': 6, '周天': 6,
}

WEEK_OFFSET_ZH = {
    '下': 1, '下个': 1,
    '这': 0, '这个': 0, '本': 0,
    '上': -1, '上个': -1,
}

RELATIVE_DAY_ZH = {
    '今天': 0, '今日': 0,
    '明天': 1, '明日': 1,
    '后天': 2,
    '大后天': 3,
    '昨天': -1, '昨日': -1,
    '前天': -2,
}

CN_DIGIT_MAP = {
    '零': 0, '〇': 0,
    '一': 1, '二': 2, '三': 3, '四': 4, '五': 5,
    '六': 6, '七': 7, '八': 8, '九': 9, '十': 10,
}

# ============================================================
# Regex patterns (identical to Dart version)
# ============================================================

WEEKDAY_ZH_REGEX = re.compile(
    r'(下|下个|这|这个|本|上|上个)?\s*(周[一二三四五六日天]|星期[一二三四五六日天])'
)

DATE_ZH_REGEX = re.compile(
    r'(\d{4})\s*年\s*(\d{1,2})\s*月\s*(\d{1,2})\s*[日号]|'
    r'(\d{1,2})\s*月\s*(\d{1,2})\s*[日号]'
)

DATE_ZH_CN_REGEX = re.compile(
    r'(二[〇零一二三四五六七八九]{3})\s*年\s*'
    r'([一二三四五六七八九十]{1,2})\s*月\s*'
    r'([一二三四五六七八九十廿卅]{1,3})\s*[日号]|'
    r'([一二三四五六七八九十]{1,2})\s*月\s*'
    r'([一二三四五六七八九十廿卅]{1,3})\s*[日号]'
)

TIME_ZH_REGEX = re.compile(
    r'(上午|下午|晚上|中午|凌晨|早晨|傍晚|夜里)?\s*'
    r'(\d{1,2})\s*[点時]\s*'
    r'(?:(\d{1,2})\s*分)?'
    r'(半)?'
)

TIME_ZH_CN_REGEX = re.compile(
    r'(上午|下午|晚上|中午|凌晨|早晨|傍晚|夜里)?\s*'
    r'([一二三四五六七八九十]{1,2})\s*[点時]\s*'
    r'(?:([一二三四五六七八九十]{1,2})\s*分)?'
    r'(半)?'
)

TIME_ZH_24_REGEX = re.compile(
    r'(\d{1,2})\s*[时時]'
    r'(?:(\d{1,2})\s*分)?'
)

RELATIVE_TIME_ZH_REGEX = re.compile(
    r'(\d+|半)\s*(?:个?\s*)?'
    r'(小时|分钟|分钟|分|钟头)\s*[后内以]'
)

LOCATION_ZH_REGEX = re.compile(
    r'(?:在|于|去|到|地点[：:]?\s*|位置[：:]?\s*)'
    r'([\u4e00-\u9fff_a-zA-Z0-9（）()\-.·\s]{2,}'
    r'(?:教室|教学楼|实验楼|办公楼|会议室|办公室|大厅|广场|餐厅|食堂|图书馆|体育馆|'
    r'实验室|中心|报告厅|礼堂|场馆|房间|大楼|大厦|公寓|宿舍|校区|学院|'
    r'银行|医院|酒店|饭店|商场|超市|公园|地铁站|车站|机场|'
    r'厅|堂|馆|室|所|处|部|店|院|园|楼|层)'
    r'[\u4e00-\u9fff_a-zA-Z0-9（）()\-.·\d\s]*)'
)

LOCATION_ZH_SIMPLE_REGEX = re.compile(
    r'(?:在|于)\s*([\u4e00-\u9fff_a-zA-Z0-9]{2,20})'
)

# ============================================================
# Helper functions
# ============================================================

def cn_num_to_int(s: str) -> int | None:
    """Convert Chinese numeral string to int."""
    if not s:
        return None
    try:
        return int(s)
    except ValueError:
        pass

    if s == '十':
        return 10
    if s == '廿':
        return 20
    if s == '卅':
        return 30

    # Pattern: X十Y
    tens_match = re.match(r'^([一二三四五六七八九])?十([一二三四五六七八九])?$', s)
    if tens_match:
        tens = tens_match.group(1) or ''
        ones = tens_match.group(2) or ''
        result = 0
        if tens:
            result += CN_DIGIT_MAP.get(tens, 0) * 10
        else:
            result += 10
        if ones:
            result += CN_DIGIT_MAP.get(ones, 0)
        return result

    return CN_DIGIT_MAP.get(s)


def is_chinese_input(text: str) -> bool:
    cjk_count = sum(1 for c in text if '\u4e00' <= c <= '\u9fff')
    return cjk_count >= 2 or any('\u4e00' <= c <= '\u9fff' for c in text)


def resolve_offset_weekday(from_date: datetime, target_weekday: int, week_offset: int) -> datetime:
    raw_diff = target_weekday - from_date.weekday()
    if week_offset >= 1:  # 下周
        diff = raw_diff + 7 if raw_diff <= 0 else raw_diff
    elif week_offset <= -1:  # 上周
        diff = raw_diff - 7 if raw_diff >= 0 else raw_diff
    else:  # 本周
        diff = raw_diff
    return from_date + timedelta(days=diff)


# ============================================================
# Test cases
# ============================================================

@dataclass
class TestCase:
    name: str
    input_text: str
    expected_title: str | None = None
    expected_date_delta: int | None = None  # days from today
    expected_time: str | None = None  # "HH:MM"
    expected_location: str | None = None
    should_fail: bool = False

    def __repr__(self):
        return f"Test({self.name})"


def run_tests():
    now = datetime(2026, 6, 1, 14, 30)  # Monday (0=Mon in Python)
    today = now.replace(hour=0, minute=0, second=0, microsecond=0)

    tests = [
        # ── Relative days ──
        TestCase("今天", "今天下午开会", expected_title="下午开会", expected_date_delta=0),
        TestCase("明天", "明天去图书馆", expected_title="去图书馆", expected_date_delta=1),
        TestCase("后天", "后天交作业", expected_title="交作业", expected_date_delta=2),
        TestCase("大后天", "大后天考试", expected_title="考试", expected_date_delta=3),
        TestCase("昨天", "昨天的会议纪要", expected_title="会议纪要", expected_date_delta=-1),

        # ── Chinese weekday ──
        TestCase("下周三", "下周三下午3点班会", expected_title="班会", expected_date_delta=2, expected_time="15:00"),

        # ── Chinese month-day ──
        TestCase("6月15日", "6月15日毕业典礼", expected_title="毕业典礼"),
        TestCase("6月5号", "6月5号交论文", expected_title="交论文"),
        TestCase("2026年8月1日", "2026年8月1日开学", expected_title="开学"),

        # ── Chinese numeric date ──
        TestCase("X年X月X日", "2026年12月25日圣诞节", expected_title="圣诞节"),

        # ── Chinese 上午/下午 time ──
        TestCase("上午9点", "明天上午9点开会", expected_title="开会", expected_date_delta=1, expected_time="09:00"),
        TestCase("下午3点", "下午3点去银行", expected_title="去银行", expected_time="15:00"),
        TestCase("晚上8点", "今晚晚上8点吃饭", expected_title="吃饭", expected_date_delta=0, expected_time="20:00"),
        TestCase("上午10点半", "明天上午10点半上课", expected_time="10:30"),
        TestCase("下午4点30分", "下午4点30分面试", expected_time="16:30"),
        TestCase("中午12点", "中午12点午饭", expected_time="12:00"),
        TestCase("凌晨2点", "凌晨2点还有一节课", expected_time="02:00"),

        # ── Chinese 24h time ──
        TestCase("14时", "14时开会", expected_time="14:00"),
        TestCase("14时30分", "14时30分集合", expected_time="14:30"),

        # ── "点" without period (default to afternoon) ──
        TestCase("3点", "明天3点去图书馆", expected_date_delta=1),

        # ── Relative time ──
        TestCase("半小时后", "半小时后开会", expected_title="开会"),

        # ── Location ──
        TestCase("在教室", "明天上午9点在A201教室上课", expected_title="上课", expected_location="A201教室"),
        TestCase("在教学楼", "下午2点在教学楼B101开会", expected_title="开会", expected_location="教学楼B101"),
        TestCase("在图书馆", "周三在图书馆自习", expected_title="自习", expected_location="图书馆"),

        # ── SMS/notification style ──
        TestCase("银行短信", "【招商银行】您的信用卡账单于6月15日到期，请及时还款",
                 expected_title="您的信用卡账单到期，请及时还款"),
        TestCase("快递通知", "【顺丰快递】您有一个快递将于明天下午送达",
                 expected_title="快递将于送达", expected_date_delta=1),
        TestCase("学校通知", "【教务处】本学期期末考试定于2026年6月20日上午9点在东区教学楼举行",
                 expected_title="本学期期末考试定于举行"),
        TestCase("微信通知", "明天下午3点开组会，在实验室201",
                 expected_title="开组会", expected_date_delta=1, expected_time="15:00", expected_location="实验室201"),

        # ── Mixed Chinese-English ──
        TestCase("中英混合", "明天和John在Coffee Shop见面",
                 expected_title="和John见面", expected_date_delta=1),

        # ── Full sentence from notification ──
        TestCase("完整日程", "6月18日下午2点半在图书馆三楼会议室，参加毕业设计答辩",
                 expected_title="参加毕业设计答辩", expected_time="14:30", expected_location="图书馆三楼会议室"),
    ]

    passed = 0
    failed = 0
    results = []

    for tc in tests:
        try:
            title, date_obj, location = parse_chinese(tc.input_text, now)

            ok = True
            details = []

            # Check title
            if tc.expected_title and tc.expected_title not in title:
                ok = False
                details.append(f"title: got '{title}', expected containing '{tc.expected_title}'")

            # Check date
            if tc.expected_date_delta is not None:
                expected_date = today + timedelta(days=tc.expected_date_delta)
                if date_obj.date() != expected_date.date():
                    ok = False
                    details.append(f"date: got {date_obj.date()}, expected {expected_date.date()}")

            # Check time
            if tc.expected_time:
                actual_time = date_obj.strftime("%H:%M")
                if actual_time != tc.expected_time:
                    ok = False
                    details.append(f"time: got {actual_time}, expected {tc.expected_time}")

            # Check location
            if tc.expected_location:
                if not location or tc.expected_location not in location:
                    ok = False
                    details.append(f"location: got '{location}', expected containing '{tc.expected_location}'")

            if ok:
                passed += 1
                status = "✅"
            else:
                failed += 1
                status = "❌"

            result_line = f"{status} {tc.name}: [{tc.input_text[:40]}...]"
            if ok:
                result_line += f" → '{title}' @ {date_obj.strftime('%m/%d %H:%M')}"
                if location:
                    result_line += f" @ {location}"
            else:
                result_line += f" → '{title}' @ {date_obj.strftime('%m/%d %H:%M')}"
                if location:
                    result_line += f" @ {location}"
                result_line += f"  |  ISSUES: {'; '.join(details)}"

            results.append(result_line)

        except Exception as e:
            if tc.should_fail:
                passed += 1
                results.append(f"✅ {tc.name}: correctly failed - {e}")
            else:
                failed += 1
                results.append(f"❌ {tc.name}: UNEXPECTED ERROR - {e}")

    # Print results
    print("=" * 80)
    print("  Plan-Reminder 中文 NLP 解析器 测试报告")
    print(f"  测试时间: {now.strftime('%Y-%m-%d %H:%M')} (今为周一)")
    print("=" * 80)
    for r in results:
        print(f"  {r}")
    print("=" * 80)
    print(f"  通过: {passed}/{passed + failed}  ({passed * 100 // (passed + failed)}%)")
    print("=" * 80)


# ============================================================
# Simplified Chinese NLP Parser (Python version of Dart logic)
# ============================================================

def parse_chinese(text: str, now: datetime) -> tuple[str, datetime, str | None]:
    """
    Simplified Chinese NLP parser.
    Returns (title, datetime, location).
    """
    today = now.replace(hour=0, minute=0, second=0, microsecond=0)

    # ── Extract date ──
    matched_phrases = []
    resolved_date = None
    has_explicit_date = False

    # Relative days (sorted longest first to avoid partial matches)
    sorted_keywords = sorted(RELATIVE_DAY_ZH.keys(), key=len, reverse=True)
    for keyword in sorted_keywords:
        if keyword in text:
            delta = RELATIVE_DAY_ZH[keyword]
            resolved_date = today + timedelta(days=delta)
            matched_phrases.append(keyword)
            has_explicit_date = True
            break

    # Weekday
    if resolved_date is None:
        m = WEEKDAY_ZH_REGEX.search(text)
        if m:
            prefix = m.group(1) or ''
            day_word = m.group(2) or ''
            weekday = WEEKDAY_MAP_ZH.get(day_word)
            if weekday is not None:
                week_offset = WEEK_OFFSET_ZH.get(prefix, 0)
                resolved_date = resolve_offset_weekday(today, weekday, week_offset)
                matched_phrases.append(m.group(0))
                has_explicit_date = True

    # Month-day numeric
    if resolved_date is None:
        m = DATE_ZH_REGEX.search(text)
        if m:
            if m.group(1):  # X年X月X日
                year = int(m.group(1))
                month = int(m.group(2))
                day = int(m.group(3))
                try:
                    resolved_date = datetime(year, month, day)
                    matched_phrases.append(m.group(0))
                    has_explicit_date = True
                except ValueError:
                    pass
            elif m.group(4):  # X月X日
                month = int(m.group(4))
                day = int(m.group(5))
                try:
                    d = datetime(now.year, month, day)
                    if d < today:
                        d = datetime(now.year + 1, month, day)
                    resolved_date = d
                    matched_phrases.append(m.group(0))
                    has_explicit_date = True
                except ValueError:
                    pass

    # Chinese numeral date
    if resolved_date is None:
        m = DATE_ZH_CN_REGEX.search(text)
        if m:
            if m.group(1):
                year = cn_num_to_int(m.group(1))
                month = cn_num_to_int(m.group(2))
                day = cn_num_to_int(m.group(3))
            elif m.group(4):
                year = now.year
                month = cn_num_to_int(m.group(4))
                day = cn_num_to_int(m.group(5))
            else:
                year = month = day = None
            if year and month and day:
                try:
                    resolved_date = datetime(year, month, day)
                    matched_phrases.append(m.group(0))
                    has_explicit_date = True
                except ValueError:
                    pass

    base_date = resolved_date or today

    # ── Extract time ──
    hour = None
    minute = 0
    has_explicit_time = False

    m = TIME_ZH_REGEX.search(text)
    if m:
        period = m.group(1) or ''
        hour_raw = m.group(2)
        minute_raw = m.group(3)
        is_half = bool(m.group(4))
        try:
            h = int(hour_raw)
            m_val = 30 if is_half else (int(minute_raw) if minute_raw else 0)
            # 下午 adjust
            if any(p in period for p in ['下午', '傍晚', '晚上', '夜里']):
                if h < 12:
                    h += 12
                if h == 12 and '晚上' in period:
                    h = 0
            elif '中午' in period:
                if 1 <= h <= 11:
                    h = 12
            elif any(p in period for p in ['凌晨', '早晨']):
                if h == 12:
                    h = 0
            hour = h % 24
            minute = m_val
            matched_phrases.append(m.group(0))
            has_explicit_time = True
        except (ValueError, IndexError):
            pass

    # Chinese numeral time
    if not has_explicit_time:
        m = TIME_ZH_CN_REGEX.search(text)
        if m:
            period = m.group(1) or ''
            h_raw = m.group(2) or ''
            m_raw = m.group(3)
            is_half = bool(m.group(4))
            h = cn_num_to_int(h_raw)
            if h is not None and 0 <= h <= 23:
                m_val = 30 if is_half else (cn_num_to_int(m_raw) if m_raw else 0)
                if any(p in period for p in ['下午', '傍晚', '晚上', '夜里']):
                    if h < 12: h += 12
                elif '中午' in period:
                    if 1 <= h <= 11: h = 12
                elif any(p in period for p in ['凌晨', '早晨']):
                    if h == 12: h = 0
                hour = h % 24
                minute = m_val or 0
                matched_phrases.append(m.group(0))
                has_explicit_time = True

    # 24h time
    if not has_explicit_time:
        m = TIME_ZH_24_REGEX.search(text)
        if m and not re.search(r'[上下中午凌晨早傍]', text):
            try:
                h = int(m.group(1))
                m_val = int(m.group(2)) if m.group(2) else 0
                if 0 <= h <= 23:
                    hour = h
                    minute = m_val
                    matched_phrases.append(m.group(0))
                    has_explicit_time = True
            except (ValueError, IndexError):
                pass

    # Relative time
    if not has_explicit_time:
        m = RELATIVE_TIME_ZH_REGEX.search(text)
        if m:
            amount_str = m.group(1)
            unit = m.group(2)
            if '分' in unit:
                amount = 30 if amount_str == '半' else (int(amount_str) if amount_str.isdigit() else 1)
                future = now + timedelta(minutes=amount)
            else:
                amount = 0.5 if amount_str == '半' else (int(amount_str) if amount_str.isdigit() else 1)
                future = now + timedelta(minutes=int(amount * 60))
            hour = future.hour
            minute = future.minute
            matched_phrases.append(m.group(0))
            has_explicit_time = True

    # Default time
    if not has_explicit_time:
        next_hour = now + timedelta(hours=1)
        hour = next_hour.hour
        minute = 0

    date_time = datetime(base_date.year, base_date.month, base_date.day, hour or 0, minute)

    # ── Extract location ──
    location = None
    m = LOCATION_ZH_REGEX.search(text)
    if m:
        loc = m.group(1).strip()
        if loc and not re.search(r'[今天明日後后大前昨周一二三四五六日天点時分秒半上中下晚早凌晨里]|\d{1,2}[点時分秒]', loc):
            location = loc
            matched_phrases.append(m.group(0))
    if location is None:
        m = LOCATION_ZH_SIMPLE_REGEX.search(text)
        if m:
            loc = m.group(1).strip()
            if loc and len(loc) >= 2 and not re.search(r'[\d一二三四五六七八九十点時分秒半上中下午晚凌晨早]+', loc):
                location = loc
                matched_phrases.append(m.group(0))

    # ── Extract title ──
    title = ' ' + text + ' '
    # Remove matched phrases (longest first)
    for phrase in sorted(set(matched_phrases), key=len, reverse=True):
        title = title.replace(phrase, ' ')
    # Remove 【】brackets (notification source headers)
    title = re.sub(r'【[^】]*】', ' ', title)
    # Remove notification noise prefixes
    title = re.sub(r'(?:顺丰|中通|圆通|韵达|EMS|京东)?快递[：:]?\s*', ' ', title)
    title = re.sub(r'(?:招商|工商|建设|农业|中国|交通|浦发|中信)?银行[：:]?\s*', ' ', title)
    title = re.sub(r'(?:教务|学生|后勤|财务|信息)处[：:]?\s*', ' ', title)
    # Remove common stop words
    title = re.sub(r'[在於于去到的了您请]', ' ', title)
    # Remove 将/定于/于/将于 etc.
    title = re.sub(r'(?:将|定|拟)\s*[于於在]', ' ', title)
    # Collapse whitespace
    title = re.sub(r'\s+', ' ', title).strip()
    title = re.sub(r'^[\-,.:;，。：；！？、\s]+|[\-,.:;，。：；！？、\s]+$', '', title)

    if not title:
        title = text

    return title, date_time, location


if __name__ == '__main__':
    run_tests()
