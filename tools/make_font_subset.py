#!/usr/bin/env python3
"""重新生成中文字体子集 assets/fonts/NotoSansSC-subset.otf。
改了/加了中文文字（strings.csv、.gd、.tscn）之后运行一次：
    pip install fonttools
    python3 tools/make_font_subset.py [NotoSansCJK-Regular.ttc 路径]
会扫描项目里所有用到的非 ASCII 字符 + 常用标点，并检查有没有字体里没有的字。"""
import glob, os, subprocess, sys
from fontTools.ttLib import TTFont
SRC = sys.argv[1] if len(sys.argv) > 1 else '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc'
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
chars = set()
for ext in ('gd', 'tscn', 'tres', 'csv'):
    for f in glob.glob('**/*.' + ext, recursive=True):
        if f.startswith(('.godot', 'zz_check')): continue
        try: chars |= {c for c in open(f, encoding='utf-8').read() if ord(c) > 127}
        except UnicodeDecodeError: pass
chars |= set('，。！？：；、“”‘’（）《》【】「」『』…—–·★☆✓√→←↑↓×÷■□●○◆◇%￥①②③')
chars |= set('零一二三四五六七八九十百千万亿上下左右前后中大小多少开关是否好坏新旧高低快慢长短'
             '确定取消设置语言中文英文音乐音效音量全屏窗口暂停继续重新开始退出返回保存读取帮助关于版本')
src_cmap = set(TTFont(SRC, fontNumber=2).getBestCmap())   # 2 = Noto Sans CJK SC（简体）
anta = set(TTFont('assets/Anta-Regular.ttf').getBestCmap())
missing = [c for c in sorted(chars) if ord(c) not in src_cmap and ord(c) not in anta]
if missing: print('WARNING 这些字符任何字体都没有，请换掉：', missing, [hex(ord(c)) for c in missing])
txt = ''.join(c for c in sorted(chars) if ord(c) in src_cmap)
open('/tmp/subset_chars.txt', 'w', encoding='utf-8').write(txt)
subprocess.check_call(['pyftsubset', SRC, '--font-number=2', '--text-file=/tmp/subset_chars.txt',
    '--unicodes=U+0020-007E', '--layout-features=*', '--output-file=assets/fonts/NotoSansSC-subset.otf'])
print('OK', len(txt), 'characters ->', os.path.getsize('assets/fonts/NotoSansSC-subset.otf'), 'bytes')
