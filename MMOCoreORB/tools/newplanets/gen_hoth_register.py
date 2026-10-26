#!/usr/bin/env python3
"""gen_hoth_register.py — wire the generated Hoth mobiles into planet config and object templates.

Idempotent: re-running leaves already-applied edits alone.
"""
import os

import gen_hoth_mobiles as g

S = g.ROOT
OBJS = ['wampa', 'snowtrooper_s01', 'rebel_snow_m_01', 'rebel_snow_f_01']


def p(*parts):
    return os.path.join(S, *parts)


def rw(path, fn):
    s = open(path, encoding='utf-8', newline='').read()
    t = fn(s)
    if t != s:
        open(path, 'w', encoding='utf-8', newline='').write(t)
        print('updated', os.path.relpath(path, S))
    else:
        print('unchanged', os.path.relpath(path, S))


def planet_objects(s):
    i = s.index('\nhoth = {')
    j = s.index('\n}\n', i)
    blk = s[i:j]
    empty = '\tplanetObjects = {\n\t}'
    if empty not in blk:
        return s
    rows = '\n'.join(g.terminals())
    return s[:i] + blk.replace(empty, '\tplanetObjects = {\n' + rows + '\n\t}') + s[j:]


def world_spawner(s):
    todo = '\t-- TODO: SPAWNAREA + WORLDSPAWNAREA world spawner once scripts/mobile/hoth exists\n'
    if todo not in s:
        return s
    return s.replace(todo, '\t-- World spawner (lairs, herds and patrols from mobile/spawn/hoth/hoth_world.lua)\n'
                           '\t{"@hoth_region_names:world_spawner", 0, 0, {RECTANGLE, 0, 0}, SPAWNAREA + WORLDSPAWNAREA, {"hoth_world"}, 1024},\n')


def shared_templates(s):
    for o in OBJS:
        if f'object_mobile_shared_{o} = ' in s:
            continue
        s = s.rstrip('\n') + f'''

object_mobile_shared_{o} = SharedCreatureObjectTemplate:new {{
	clientTemplateFileName = "object/mobile/shared_{o}.iff"
	--Data below here is deprecated and loaded from the tres (Hoth mobile ported from SWG Infinity)
}}

ObjectTemplates:addClientTemplate(object_mobile_shared_{o}, "object/mobile/shared_{o}.iff")
'''
    return s


def server_includes(s):
    nl = '\r\n' if '\r\n' in s else '\n'
    for o in OBJS:
        line = f'includeFile("mobile/{o}.lua")'
        if line not in s:
            s = s.rstrip('\r\n') + nl + line + nl
    return s


def main():
    rw(p('managers', 'planet', 'planet_manager.lua'), planet_objects)
    rw(p('managers', 'planet', 'hoth_regions.lua'), world_spawner)
    rw(p('object', 'mobile', 'objects.lua'), shared_templates)
    hdr = open(p('object', 'mobile', 'tauntaun.lua'), encoding='utf-8').read()
    hdr = hdr[:hdr.index('object_mobile_tauntaun')]
    for o in OBJS:
        g.write(f'object/mobile/{o}.lua', hdr + f'object_mobile_{o} = object_mobile_shared_{o}:new {{\n}}\n\n'
                                                f'ObjectTemplates:addTemplate(object_mobile_{o}, "object/mobile/{o}.iff")\n')
    rw(p('object', 'mobile', 'serverobjects.lua'), server_includes)


if __name__ == '__main__':
    main()
