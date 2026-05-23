import re

# Read file
with open(r'C:\Users\Chen\WorkBuddy\2026-05-23-task-2\baby-feed-tracker.html', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add calendar icon CSS after .day-label definition
# First, find .day-label CSS and add new styles after it
calendar_css = '''
    /* Calendar Icon for History Date */
    .day-calendar {
      display: inline-flex;
      flex-direction: column;
      align-items: center;
      width: 48px;
      margin-right: 12px;
      flex-shrink: 0;
    }
    .day-calendar-month {
      background: var(--pink);
      color: white;
      font-size: 10px;
      font-weight: 700;
      letter-spacing: 0.5px;
      text-transform: uppercase;
      width: 100%;
      text-align: center;
      padding: 3px 0 2px;
      border-radius: 6px 6px 0 0;
    }
    .day-calendar-day {
      background: white;
      color: var(--text);
      font-size: 20px;
      font-weight: 700;
      width: 100%;
      text-align: center;
      padding: 4px 0 6px;
      border: 2px solid var(--pink);
      border-top: none;
      border-radius: 0 0 6px 6px;
      line-height: 1;
    }
    .day-label-row {
      display: flex;
      align-items: center;
      gap: 0;
    }
    .day-label-text {
      font-size: 15px;
      font-weight: 600;
      color: var(--text);
    }
    .day-label-text .today-badge {
      display: inline-block;
      background: var(--pink);
      color: white;
      font-size: 11px;
      padding: 1px 8px;
      border-radius: 10px;
      margin-right: 6px;
      font-weight: 600;
    }
'''

# Find .day-label CSS and insert calendar CSS after it
# The .day-label CSS is usually in the history section
day_label_pattern = r'(\.day-label\s*\{[^}]*\})'
match = re.search(day_label_pattern, content, re.DOTALL)
if match:
    # Insert calendar CSS after .day-label
    insert_pos = match.end()
    content = content[:insert_pos] + calendar_css + content[insert_pos:]
    print("Added calendar CSS after .day-label")
else:
    print("WARNING: .day-label not found, trying alternative approach")
    # Try to find a good place to insert CSS (before /* History */ comment)
    history_css_pattern = r'(/\*\s*History\s*\*/)'
    match2 = re.search(history_css_pattern, content)
    if match2:
        insert_pos = match2.start()
        content = content[:insert_pos] + calendar_css + '\n' + content[insert_pos:]
        print("Added calendar CSS before History section")
    else:
        print("ERROR: Could not find suitable place to insert CSS")

# 2. Modify renderHistory() to use calendar icon
# Find the day-label line and replace it with calendar icon HTML
old_day_label = '''    return `<div class="day-group">
      <div class="day-label">${isToday ? '今天 · ' : ''}${yr}年${parseInt(mo)}月${parseInt(dy)}日</div>`'''

# Month abbreviations
month_abbr = ['', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 
               'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC']

new_day_label = '''    const monthAbbr = ['','JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
    return `<div class="day-group">
      <div class="day-label-row">
        <div class="day-calendar">
          <div class="day-calendar-month">${monthAbbr[parseInt(mo)]}</div>
          <div class="day-calendar-day">${parseInt(dy)}</div>
        </div>
        <div class="day-label-text">${isToday ? '<span class="today-badge">今天</span>' : ''}${yr}年${parseInt(mo)}月${parseInt(dy)}日</div>
      </div>`'''

if old_day_label in content:
    content = content.replace(old_day_label, new_day_label)
    print("Modified renderHistory() to use calendar icon")
else:
    print("WARNING: Old day-label pattern not found, searching for alternative...")
    # Try to find the line with day-label
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if 'day-label' in line and '${yr}年' in line:
            print(f"Found at line {i}: {line.strip()}")
            break

# Write file
with open(r'C:\Users\Chen\WorkBuddy\2026-05-23-task-2\baby-feed-tracker.html', 'w', encoding='utf-8') as f:
    f.write(content)

print("\nDone! baby-feed-tracker.html updated with calendar icon")
