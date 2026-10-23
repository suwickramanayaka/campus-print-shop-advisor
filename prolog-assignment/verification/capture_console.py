"""Replay console inputs in isolated databases and capture real output."""
from pathlib import Path
import subprocess, tempfile
ROOT=Path(__file__).resolve().parents[1]
SWI='/opt/homebrew/bin/swipl'
scenarios={
 'all_menus_and_invalid_inputs': ['oops','2','4','6','1','2','paper.','2','unknown.','9','0','3','oops','1','ink','3','1','paper','-1','1','paper','20','2','paper','80','3','staple','1','staple','30','0','1','abc','0','40','3','maybe','no','yes','yes','spiral','1020','none','99','1','maybe','yes','2','4','6','1','0','5','999','5','1','2','0'],
 'budget_rejection':['1','40','3','no','yes','yes','spiral','1000','none','0'],
 'capacity_rejection':['1','1000','1','no','no','yes','staple','99999','none','0'],
 'colour_and_optional_binding':['3','2','paper','100','0','1','5','2','yes','yes','no','1000','none','1','no','0'],
 'either_binding_and_back':['1','4','1','no','no','yes','either','1000','none','0','0'],
 'unknown_cancel_and_nonnumeric':['5','abc','3','2','paper','abc','0','0'],
 'malformed_term':['6','2','bad(.','0','0'],
 'deadline_rejection': ['1','40','3','no','yes','yes','spiral','1020','tomorrow','2026-10-23 08:00','2026-10-23 09:16','0'],
 'deadline_accept_and_queue': ['1','40','3','no','yes','yes','spiral','1020','2026-10-23 09:17','1','yes','3','1','paper','60','0','1','40','3','no','yes','yes','spiral','1020','2026-10-23 09:20','4','0'],
 'end_of_input': ['1']
}
parts=[]
for name,inputs in scenarios.items():
 with tempfile.TemporaryDirectory() as d:
  db=Path(d)/'db.pl'
  goal=f"retractall(db_path(_)),assertz(db_path('{db}')),reset_records,set_demo_time('2026-10-23 09:00'),start"
  result=subprocess.run([SWI,'-q','-s','main.pl','-g',goal,'-t','halt'],cwd=ROOT,input='\n'.join(inputs)+'\n',text=True,capture_output=True,timeout=20)
  assert result.returncode==0,(name,result.stderr)
  assert not result.stderr,(name,result.stderr)
  parts.append(f'=== {name} ===\nINPUTS (one per line):\n'+ '\n'.join(inputs)+'\n\nCAPTURED OUTPUT:\n'+result.stdout)
(ROOT/'sample_runs.txt').write_text('\n\n'.join(parts))
print(f'Captured {len(scenarios)} real console sessions.')
