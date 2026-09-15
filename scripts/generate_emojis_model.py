import requests
import sys
import re
from pathlib import Path
import json

URL = 'https://www.unicode.org/Public/17.0.0/emoji/emoji-test.txt'

GROUP_RE = re.compile(r'^# group: (.*)$')
EMOJI_RE = re.compile(r'^((?:[A-F0-9]{4,5} )*[A-F0-9]{4,5})\s*;\s*(component|fully-qualified|minimally-qualified|unqualified)\s*#.*$')

def hex_to_emoji(emoji: str):
    return ''.join(chr(int(code, 16)) for code in emoji.split())

data = requests.get(URL).content.decode()
emojis: dict[str, list[str]] = {} # group: [emojis]

if len(sys.argv) != 3:
    print(f"Insufficient arguments. Usage: python3 generate_emojis_model.py path/to/SailDiscord")

saildiscord_root = Path(sys.argv[1])


group = ''
for line in data.split('\n'):
    if line.startswith('#'):
        group_match = GROUP_RE.match(line)
        if group_match:
            group = group_match[1]
            if group not in emojis:
                emojis[group] = []
    elif line:
        match = EMOJI_RE.match(line)
        if match:
            if (saildiscord_root / f"images/twemoji/{'-'.join(match[1].lower().split())}.svg").exists():
                emojis[group].append(hex_to_emoji(match[1]))


with open(saildiscord_root / 'qml/components/EmojisModel.qml', 'w') as f:
    f.write('''\
import QtQuick 2.0

ListModel {
    Component.onCompleted: {
''')
    for group, group_emojis in emojis.items():
        obj = json.dumps({'group': group, 'emojis': [{'emoji': e} for e in group_emojis]})
        f.write(f'''\
        append({obj})\n''')
    f.write('''\
    }
}''')