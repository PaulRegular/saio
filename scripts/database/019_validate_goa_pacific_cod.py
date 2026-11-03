"""Check Pacific cod native records and preservation of other assessments."""
import csv
import hashlib
import io
import re
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path
root=Path(sys.argv[1])
folder=root/'analysis/comp_assessments'
rows=list(csv.DictReader((folder/'database/inputs.csv').open(encoding='utf-8-sig')))
current=[r for r in rows if r['assessment_id']=='afsc_cod_goa_2026']
assert len(current)==12689
counts=Counter(r['measure'] for r in current)
assert counts=={'total_biomass':147,'total_numbers':52,'log_index_sd':52,'proportion_at_length':3822,'conditional_proportion_at_age':8570,'environmental_covariate':46},counts
source=defaultdict(dict)
for r in csv.DictReader((folder/'source_cache/afsc_cod_goa_2026/native_observation_sections_raw.csv').open()):
 source[r['section']].setdefault(int(r['row']),{})[int(r['column'])]=float(r['value'])
groups=defaultdict(list)
for r in current:
 if r['measure'] in ('proportion_at_length','conditional_proportion_at_age'): groups[r['observation_id']].append(r)
assert len(groups)==1039
for key,group in groups.items():
 section,number=key.split('_'); original=source[section][int(number)]
 assert len(group)==(21 if section=='length' else 10)
 assert abs(sum(float(r['value']) for r in group)-1)<0.0001
 for r in group:
  column=7+int(round((float(r['length_bin'])-4.5)/5)) if section=='length' else 9+int(r['age'])
  assert float(r['value'])==original[column]
  assert float(r['sample_size'])==original[6 if section=='length' else 9]
  assert float(r['sampling_time'])==(original[2]-1)/12
  if section=='age':
   assert float(r['length_bin_lower'])==original[7]
   assert float(r['length_bin_upper'])==original[8]
   assert int(r['age_error'])==original[6]
native=(folder/'source_cache/afsc_cod_goa_2026/accepted_model/GOAPcod2025Dec08.dat').read_text().splitlines()
start=next(i for i,line in enumerate(native) if '#_year\tvariable\tindex' in line)+1
expected={}
for line in native[start:]:
 values=line.split('#')[0].split()
 if not values: continue
 year,variable,value=map(float,values)
 if year==-9999: break
 expected[int(year)]=value
covariates={int(r['year']):float(r['value']) for r in current if r['type']=='covariate'}
assert covariates==expected and min(covariates.values())<0
output_rows=list(csv.DictReader((folder/'database/outputs.csv').open(encoding='utf-8-sig')))
mortality=[r for r in output_rows if r['assessment_id']=='afsc_cod_goa_2026' and r['measure']=='natural_mortality_at_age']
assert len(mortality)==539
assert {(int(r['year']),int(r['age'])) for r in mortality}=={(y,a) for y in range(1977,2026) for a in range(11)}
for r in mortality:
 elevated=2014<=int(r['year'])<=2016
 assert float(r['value'])==(.84 if elevated else .5)
 assert float(r['se'])==(.053 if elevated else .023)
 assert not r['lwr'] and not r['upr']
previous_blob=subprocess.check_output(['git','show','HEAD:analysis/comp_assessments/database/inputs.csv'],cwd=root)
if previous_blob.startswith(b'version https://git-lfs.github.com/spec/v1'):
 match=re.search(rb'oid sha256:([0-9a-f]{64})',previous_blob)
 assert match, 'Could not read the committed LFS pointer for inputs.csv'
 oid=match.group(1).decode('ascii')
 lfs_objects=Path(subprocess.check_output(['git','rev-parse','--git-path','lfs/objects'],cwd=root,text=True).strip())
 if not lfs_objects.is_absolute(): lfs_objects=root/lfs_objects
 previous_path=lfs_objects/oid[:2]/oid[2:4]/oid
 assert previous_path.is_file(), f'Committed inputs.csv LFS object is not cached: {oid}'
 previous_blob=previous_path.read_bytes()
 assert hashlib.sha256(previous_blob).hexdigest()==oid, 'Cached inputs.csv LFS object failed its SHA-256 check'
previous=previous_blob.decode('utf-8-sig')
curated_ids={
 'dfo_cod_2j3kl_2025','ices_cod_north_sea_2025','ices_cod_northeast_arctic_2026',
 'ices_haddock_north_sea_2026','ices_herring_north_sea_2026',
 'afsc_pollock_ebs_2024','afsc_pollock_goa_2024','afsc_cod_goa_2026',
 'nefsc_haddock_georges_bank_2026'
}
old=[r for r in csv.DictReader(io.StringIO(previous)) if r['assessment_id'] not in curated_ids]
previous_rows=Counter(tuple(r[key] for key in old[0]) for r in old)
current_rows=Counter(tuple(r[key] for key in old[0]) for r in rows)
assert all(current_rows[row] >= count for row,count in previous_rows.items()), 'Unrelated or untimed prior input records changed'
print('Pacific cod source records and all non-targeted prior inputs verified.')


