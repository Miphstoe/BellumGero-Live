#!/usr/bin/env python3
"""iff_names.py <object iff>... — print objectName / detailedDescription stf refs and appearance for SWG object templates."""
import re, sys, os
def strs(d): return [s.decode('latin-1') for s in re.findall(rb'[\x20-\x7e]{3,}', d)]
for f in sys.argv[1:]:
    s = strs(open(f, 'rb').read())
    def after(key, n=2):
        try:
            i = s.index(key); return s[i+1:i+1+n]
        except ValueError:
            # keys may carry a length-prefix byte glued on: find suffix match
            for i, x in enumerate(s):
                if x.endswith(key): return s[i+1:i+1+n]
            return []
    on = after('objectName'); dd = after('detailedDescription'); ap = after('appearanceFilename', 1); got = after('gameObjectType', 0)
    print(f"{(f.split('object/',1)[1] if 'object/' in f else os.path.basename(f)):70s} name={':'.join(on) if on and on[0]!='detailedDescription' else '-':45s} desc={':'.join(dd) if dd and dd[0]!='lookAtText' else '-':45s} app={ap[0] if ap and ap[0]!='portalLayoutFilename' else '-'}")
