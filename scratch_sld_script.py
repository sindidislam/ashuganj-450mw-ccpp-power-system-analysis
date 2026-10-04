python -c "
import json
with open(r'C:\Users\Sindid\.gemini\antigravity-ide\brain\bf024316-2661-459f-9596-d3aac26370ad\.system_generated\logs\transcript_full.jsonl', 'r', encoding='utf-8') as f:
    for line in f:
        d = json.loads(line)
        idx = d.get('step_index', 0)
        tcs = d.get('tool_calls') or []
        for tc in tcs:
            if 'sld_fault_locations_marked' in json.dumps(tc):
                print('Step:', idx, tc.get('name'))
                if 'CommandLine' in tc.get('args', {}):
                    with open('scratch_sld_script.py', 'w', encoding='utf-8') as out:
                        out.write(tc['args']['CommandLine'])
                    print('Wrote scratch_sld_script.py')
"