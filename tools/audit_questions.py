"""Audit the embedded Knockout question bank (Python 3, no dependencies)."""
import ast
import re
import sys
from collections import Counter
from pathlib import Path

ENTRY = re.compile(r'\[\s*("(?:[^"\\\\]|\\\\.)*")\s*,\s*("(?:[^"\\\\]|\\\\.)*")\s*,\s*("(?:[^"\\\\]|\\\\.)*")\s*\]')

def audit(source):
    start = source.find('var questions: Array = [')
    if start < 0:
        raise ValueError('Missing questions array')
    end = source.find('\n\n', start)
    block = source[start:end if end >= 0 else len(source)]
    entries = [tuple(ast.literal_eval(value) for value in match.groups())
               for match in ENTRY.finditer(block)]
    if not entries:
        raise ValueError('No questions parsed')
    errors = []
    for index, fields in enumerate(entries, 1):
        if any(not field.strip() for field in fields):
            errors.append(f'Entry {index}: empty field')
    counts = Counter(question.strip().casefold() for _, question, _ in entries)
    errors.extend(f'Duplicate ({count}): {question}' for question, count in counts.items() if count > 1)
    return entries, errors

if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit('Usage: python tools/audit_questions.py Main.gd')
    try:
        entries, errors = audit(Path(sys.argv[1]).read_text(encoding='utf-8'))
    except (OSError, ValueError) as error:
        sys.exit(str(error))
    print(f'Questions: {len(entries)}')
    for category, count in sorted(Counter(row[0] for row in entries).items()):
        print(f'{category}: {count}')
    for error in errors:
        print('ERROR:', error)
    sys.exit(1 if errors else 0)
