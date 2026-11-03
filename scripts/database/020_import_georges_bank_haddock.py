"""Import verified 2026 Georges Bank haddock summaries; retain incomplete status."""
import csv,io,re,sys
from pathlib import Path
root=Path(sys.argv[1])/'analysis/comp_assessments'
cache=root/'source_cache/nefsc_haddock_georges_bank_2026'
assessment='nefsc_haddock_georges_bank_2026'
stock_id='nefsc_haddock_georges_bank'
portal='https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2026&species_id=5&stock_id=1&review_type_id=6&info_type_id=-1&map_type_id=&filename=Georges_Bank_haddock_Update_2026_06_17_100805.801712.pdf'
portal_bundle='https://apps-nefsc.fisheries.noaa.gov/saw/sasi_files.php?year=2026&species_id=5&stock_id=1&review_type_id=6&filename=2026_HAD_GB.zip'
diagnostics=portal_bundle+'; GBHaddock_MT26_diagnostics_osa_run.zip; diagnostics/summary_text.png'
review='https://www.fisheries.noaa.gov/s3/2026-07/june-2026-management-track-peer-review-panel-report_508_20260710.pdf'
framework='https://www.fisheries.noaa.gov/s3/2023-06/2022-RT-Haddock-GB-EGB-summary-ONLY-6-23-23-nefsc.pdf'
text=(cache/'2026_assessment_text.txt').read_text(encoding='utf-8')
final=(cache/'2026_peer_review_text.txt').read_text(encoding='utf-8')
assert '29,037' in final and '26,615' in final and '2DAR1' in final
inputs,outputs,assumptions=[],[],[]
def values(label):
 line=next(line for line in text.splitlines() if line.startswith(label))
 nums=[float(x.replace(',','')) for x in re.findall(r'\d[\d,]*(?:\.\d+)?',line[len(label):])]
 assert len(nums)==8,(label,nums)
 return nums
for year,value in zip(range(2018,2026),values('Catch for Assessment')):
 inputs.append(dict(assessment_id=assessment,type='catch',measure='total_biomass',basis='biomass',fleet='Combined commercial removals',year=year,year_basis='calendar_year',value=value,unit='t',source_type='official_table',source_reference=portal+'; Table 1; Catch for Assessment',notes='Published modeled total, including US landings/discards and Canadian catch. Native age composition not yet recovered; source total retained without manufacturing catch-at-age.'))
for age in range(1,10):
 inputs.append(dict(assessment_id=assessment,type='M',measure='natural_mortality_at_age',basis='per_year',year=1931,year_basis='calendar_year',age=age,value=.2,unit='per year',source_type='official_table',source_reference=review+'; Georges Bank haddock TOR 3',notes='Fixed M=0.2 for all modeled years and ages; constant vector stored once. Age 9 is 9+.'))
for measure,label,unit,kind in [('SSB','Spawning Stock Biomass','t','biomass'),('Fbar','F¯','per year','mortality'),('recruitment','Recruits (age 1)','thousand fish','recruitment')]:
 for year,value in zip(range(2018,2026),values(label)):
  row=dict(assessment_id=assessment,type=kind,measure=measure,year=year,value=value,unit=unit,source_type='official_table',source_reference=portal+'; Table 1',notes='Official WHAM historical estimate; no retrospective adjustment. Rounded published values.')
  if measure=='Fbar': row['age_group']='5–7'
  if measure=='recruitment': row['age']=1
  if year==2025 and measure=='SSB': row.update(lwr=16839,upr=50070,notes=row['notes']+' Published 95% limits; SE not reconstructed.')
  if year==2025 and measure=='Fbar': row.update(lwr=.114,upr=.388,notes=row['notes']+' Published 95% limits; SE not reconstructed.')
  outputs.append(row)
for component,setting,value,notes,source in [
 ('assessment','accepted_model','WHAM 2026 Management Track','Final June 2026 peer review accepts this update as BSIA.',review),
 ('assessment','diagnostic_run','mt26_redo.no.fall2025_osa','Run name shown in the official 2026 diagnostic bundle summary.',diagnostics),
 ('population','modeled_years','1931–2025','Report figure time series; exact native dimensions pending.',portal),
 ('population','ages','1–9; plus group 9+','Nine NAA panels in diagnostic bundle and base framework settings; current native inputs pending.',framework),
 ('population','recruitment_age','1','Published recruitment definition.',portal),
 ('recruitment','model','Random about mean','Current official diagnostic summary identifies the recruitment model; no stock-recruit relationship is listed.',diagnostics),
 ('catch','fleet_structure','One combined commercial-removals fleet','US landings/discards and Canadian catches; native composition still needed.',review),
 ('catch','composition_likelihood','Logistic-normal; zero proportions treated as missing','Current run summary labels the fleet age-composition model logistic normal (miss0).',diagnostics),
 ('index','active_streams','NEFSC spring BTS; NEFSC fall BTS; DFO BTS','All three require numerical input extraction.',review),
 ('index','excluded_observations','NEFSC spring 2023 and NEFSC fall 2025','Official exclusions, not missing values to impute.',review),
 ('index','composition_likelihood','Logistic-normal; zero proportions treated as missing','Current run summary gives this model for all three index age-composition series.',diagnostics),
 ('index','zero_observations','Treated as missing','Final TOR 3 model description.',review),
 ('index','sampling_time','unknown','Do not borrow timing from the separate Eastern Georges Bank assessment.',review),
 ('M','treatment','Fixed 0.2 for all years and ages','Constant input represented once.',review),
 ('N','process','2DAR1: correlated across age and year','Final TOR 3 confirms unchanged framework process.',review),
 ('assessment','retrospective_adjustment','None','No rho adjustment for stock status or projections.',portal),
 ('biology','projection_weights','Gaussian Markov random field','Projection method; not a replacement for historical supplied weights.',portal),
 ('q','parameter_structure','unknown','Current native configuration not yet available.',review),
 ('F','selectivity_structure','Five blocks: fleet 1 uses logistic blocks 1–2; indices 1–3 use age-specific blocks 3–5','Block assignments and model types are shown in the current run diagnostic summary; block-specific parameter values remain unavailable.',diagnostics),
 ('environment','covariates','None','Current run summary reports no environmental covariates.',diagnostics)]:
 assumptions.append(dict(assessment_id=assessment,component=component,setting=setting,value=value,notes=notes,source_reference=source))
def canonical(value):
 value='' if value is None else str(value).strip()
 if not value: return ''
 try: return str(float(value))
 except ValueError: return value
def update_table(filename,new,key,subkey=None):
 path=root/'database'/filename
 raw=path.read_bytes(); bom=raw.startswith(b'\xef\xbb\xbf'); content=raw.decode('utf-8-sig')
 reader=csv.DictReader(io.StringIO(content)); fields=reader.fieldnames; old=list(reader)
 target=str(new[0][key]); old_target=[row for row in old if row[key]==target]
 same=lambda left,right: all(canonical(left.get(field,''))==canonical(right.get(field,'')) for field in fields)
 identity=lambda row: tuple(canonical(row.get(field,'')) for field in subkey)
 old_by_key={identity(row):row for row in old_target} if subkey else {}
 if (len(old_target)==len(new) and all(same(left,right) for left,right in zip(old_target,new))) or (
  subkey and all(identity(row) in old_by_key and same(old_by_key[identity(row)],row) for row in new)
 ):
  return
 lines=content.splitlines(keepends=True); assert len(lines)==len(old)+1
 newline='\r\n' if '\r\n' in lines[0] else '\n'
 def serialize(rows):
  replacement=io.StringIO(newline='')
  csv.DictWriter(replacement,fields,lineterminator=newline).writerows(
   {field:row.get(field,'') for field in fields} for row in rows
  )
  return replacement.getvalue()
 remaining={identity(row):row for row in new} if subkey else {}
 output=[lines[0]]; inserted=False
 for line in lines[1:]:
  values=next(csv.reader([line.rstrip('\r\n')]))
  row=dict(zip(fields,values))
  if row[key]==target:
   if subkey:
    record_key=identity(row)
    if record_key in remaining:
     output.append(serialize([remaining.pop(record_key)]))
    else:
     output.append(line)
    continue
   if not inserted:
    output.append(serialize(new)); inserted=True
   continue
  output.append(line)
 if subkey:
  output.append(serialize(list(remaining.values())))
 elif not inserted:
  output.append(serialize(new))
 path.write_bytes((b'\xef\xbb\xbf' if bom else b'')+''.join(output).encode('utf-8'))
for filename,new,key in [('inputs.csv',inputs,'assessment_id'),('outputs.csv',outputs,'assessment_id'),('assumptions.csv',assumptions,'assessment_id')]:
 output_key=('type','measure','fleet','survey','sex','region','season','year','age','age_group') if filename=='outputs.csv' else None
 update_table(filename,new,key,output_key)
print(f'Imported {len(inputs)} inputs, {len(outputs)} outputs, {len(assumptions)} assumptions; all statuses partial.')
