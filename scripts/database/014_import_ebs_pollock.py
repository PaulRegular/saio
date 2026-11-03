"""Import the official 2024 EBS pollock main-run files and historical report outputs."""
import csv
import io
import json
import sys
from pathlib import Path

root=Path(sys.argv[1])/'analysis/comp_assessments'
cache=root/'source_cache/afsc_pollock_ebs_2024'
assessment='afsc_pollock_ebs_2024'; stock_id='afsc_pollock_ebs'
revision='44e0cb0ac8698e1d3954273e8aaf760d7c76cba5'
repo='https://github.com/noaa-afsc/EBS_pollock'
native=repo+'/blob/'+revision+'/runs/data/pm_24.dat'
report='https://www.npfmc.org/wp-content/PDFdocuments/SAFE/2024/EBSpollock.pdf'
b=json.loads((cache/'native_input_blocks.json').read_text())
inputs,outputs,assumptions=[],[],[]

def add(kind,measure,basis,year,value,unit,age='',fleet='',survey='',timing='',notes='',field='',transformation=''):
    inputs.append(dict(assessment_id=assessment,type=kind,measure=measure,basis=basis,
                       year=int(year),year_basis='calendar_year',value=value,unit=unit,age=age,
                       fleet=fleet,survey=survey,sampling_time=timing,notes=notes,
                       source_type='native_model',source_reference=native+'; '+field,transformation=transformation))

for i,year in enumerate(range(1964,2025)):
    add('catch','total_biomass','biomass',year,b['obs_catch'][0][i],'thousand t',fleet='Combined fishery',field='obs_catch',
        notes='Native fitted total catch; 2024 is a terminal-year assumed catch. Separate number composition ends in 2023.')
    for age in range(1,16):
        for key,kind in [('wt_fsh','catch_weight'),('wt_ssb','weight')]:
            add(kind,'weight_at_age','kg_per_fish',year,b[key][i][age-1],'kg',age,
                fleet='Combined fishery' if key=='wt_fsh' else '',field=key,
                notes='Supplied annual input matrix; terminal age 15 is 15+. Additional fitted weight model inputs remain in source cache.')
for age,value in enumerate(b['p_mature'][0],1):
    add('maturity','maturity_at_age','proportion',1964,value,'proportion',age,field='p_mature',
        notes='Constant supplied maturity vector valid 1964–2024, stored once. Source multiplies by 0.5 for female SSB; this row retains maturity before sex-fraction multiplication.')

for key,survey in [('cpue','Historical fishery CPUE'),('avo','Acoustic vessels of opportunity')]:
    obs='obs_cpue' if key=='cpue' else 'ob_avo'
    for year,value in zip(b['yrs_'+key][0],b[obs][0]):
        add('index','total_biomass','biomass',year,value,'native biomass-proportional index',survey=survey,timing=0,
            field=obs,notes='Source prediction uses beginning-year N without a within-year survival adjustment. Numerical index units unresolved; no conversion applied.')

for fleet,label in [('fsh','Combined fishery'),('bts','NMFS bottom-trawl VAST'),('ats','NMFS acoustic-trawl')]:
    years=b['yrs_'+fleet+'_data'][0]
    comp=b['oac_fsh_data' if fleet=='fsh' else 'oac_'+fleet]
    for i,(year,values) in enumerate(zip(years,comp)):
        first=2 if fleet=='ats' else 1
        denominator=sum(values[first-1:])
        assert denominator>0
        for age in range(first,16):
            add('catch' if fleet=='fsh' else 'index','proportion_at_age','proportion_numbers',year,
                values[age-1]/denominator,'proportion',age,fleet=label if fleet=='fsh' else '',
                survey='' if fleet=='fsh' else label,timing='' if fleet=='fsh' else 0.5,
                field='oac_fsh_data' if fleet=='fsh' else 'oac_'+fleet,
                transformation='Normalize over ages '+str(first)+'–15, as in source_pm.tpl',
                notes='Model-ready number composition; 15 is 15+. Preserve separately from the biomass total. Native raw composition values and effective sample sizes are cached; do not replace this with a derived age-specific catch or index.')
        if fleet!='fsh':
            add('index','total_biomass','biomass',year,b['ob_'+fleet][0][i],'thousand t',survey=label,timing=0.5,
                field='ob_'+fleet,notes='Native biomass likelihood input. BTS values are VAST estimates with full covariance. Earlier rounded SAFE VAST values differ slightly; the 2024 SAFE VAST cell is blank. No report substitution or averaging applied.')
    if fleet=='ats':
        ignore_last=b['ot_ats_std'][0][-1]/sum(comp[-1][1:])>0.4
        for i,(year,values) in enumerate(zip(years,comp)):
            if ignore_last and i==len(years)-1:
                continue
            add('index','numbers_at_age','numbers',year,values[0],'million fish',age=1,
                survey='NMFS acoustic-trawl age-1 index',timing=0.5,field='oac_ats[,1]',
                notes='Separate recruitment index with analytical q. Terminal 2024 excluded by source rule std_ot_ats/ot_ats > 0.4. Older-age ATS composition remains separate.')

for r in csv.DictReader((cache/'report_historical_outputs_raw.csv').open(encoding='utf-8')):
    kind={'numbers_at_age':'population','SSB':'biomass','recruitment':'recruitment','biomass_at_age':'biomass'}[r['measure']]
    outputs.append(dict(assessment_id=assessment,type=kind,measure=r['measure'],year=r['year'],age=r['age'],
                        age_group=r['age_group'],value=r['value'],unit=r['unit'],source_type='official_table',
                        source_reference=report+'; Table '+r['table'],
                        notes='Historical official-model estimate. Displayed N group 10+ is an output aggregation, not the native 15+ model boundary. SSB is female. Printed CV not converted to SE or interval; uncertainty interpretation remains unresolved.'))

def assume(component,setting,value,notes='',survey='',fleet='',source=report):
    assumptions.append(dict(assessment_id=assessment,component=component,setting=setting,value=value,
                            notes=notes,survey=survey,fleet=fleet,source_reference=source))
assume('assessment','accepted_model','Model 23.0','Endorsed in final December 2024 SSC report; no new fitted assessment in 2025.')
assume('population','modeled_years','1964–2024',source=native)
assume('population','ages','1–15; plus group 15+',source=native+'; source_pm.tpl')
assume('population','recruitment_age','1',source=native)
assume('biology','spawning_time','0.25','(4-1)/12 in source; April spawning.')
assume('biology','female_fraction','0.5','Source multiplies supplied maturity by 0.5 for female SSB.')
assume('M','supplied_vector','0.9 at age 1; 0.45 at age 2; 0.3 at ages 3–15','Control phase_natmort=-6; alternate predation switches still require full verification before canonical fixed-M input export.',source=repo+'/blob/'+revision+'/runs/lastyr/control.dat')
assume('catch','representation','Total biomass plus number composition','No fishery composition for terminal 2024.',fleet='Combined fishery')
assume('index','BTS_likelihood','Biomass with full supplied covariance','DoCovBTS=1 and do_bts_bio=1. Covariance matrix is cached, not yet represented numerically in canonical inputs.',survey='NMFS bottom-trawl VAST')
assume('index','ATS_likelihood','Biomass total, older-age composition and separate age-1 index','Terminal age-1 index excluded by source uncertainty rule.',survey='NMFS acoustic-trawl')
for survey,timing in [('Historical fishery CPUE',0),('Acoustic vessels of opportunity',0),('NMFS bottom-trawl VAST',0.5),('NMFS acoustic-trawl',0.5),('NMFS acoustic-trawl age-1 index',0.5)]:
    assume('index','sampling_time',str(timing),'Model prediction timing, distinct from field sampling dates.',survey=survey,source=repo+'/blob/'+revision+'/source/pm.tpl; Get_Catch_at_Age')
for component,setting in [('F','selectivity_and_penalties'),('N','initial_state_treatment'),('recruitment','stock_recruit_parameters'),('q','parameter_sharing'),('index','effective_sample_sizes_and_SD')]:
    assume(component,setting,'unknown','Native controls/auxiliary files cached; detailed extraction still incomplete.')

stock=dict(stock_id=stock_id,charbonneau_id='AFSC_ESB_Gadus_chalcogrammus',authority='NOAA-AFSC',authority_stock_id='Eastern Bering Sea pollock',
           scientific_name='Gadus chalcogrammus',common_name='Eastern Bering Sea walleye pollock',area='Eastern Bering Sea',region='Alaska',ocean='Northeast Pacific',
           notes='Separate from Aleutian Islands and Bogoslof pollock; historical catalogue identifier uses ESB spelling.')
record=dict(assessment_id=assessment,stock_id=stock_id,assessment_year=2024,terminal_year=2024,estimate_terminal_year=2024,
            assessment_type='annual',model_family='Statistical catch-at-age (ADMB)',model_version='Model 23.0',is_current='TRUE',is_applied='TRUE',
            framework_year=2023,assessment_url=report,data_url=native,repository_url=repo,
            assumptions_status='partial',inputs_status='partial',outputs_status='partial',
            notes='2024 official model retained; 2025 was catch-only rollover. Native totals/compositions and supplied biology retained, historical report N/SSB/recruitment/age3+ biomass exported. Native 2024 starter verified by year/ages, report fishery weights and SSC model approval. Earlier report VAST values differ slightly from native inputs; native preferred and discrepancy documented. M, covariance/sample-size/SD export, detailed statistical assumptions, F-at-age and uncertainty remain incomplete. See source_reviews/afsc_pollock_ebs.md.')
for filename,new,key in [('stocks.csv',[stock],'stock_id'),('assessments.csv',[record],'assessment_id'),('inputs.csv',inputs,'assessment_id'),('outputs.csv',outputs,'assessment_id'),('assumptions.csv',assumptions,'assessment_id')]:
    path=root/'database'/filename; content=path.read_bytes().decode('utf-8-sig')
    reader=csv.DictReader(io.StringIO(content)); fields=reader.fieldnames; old=list(reader)
    lines=content.splitlines(keepends=True); assert len(lines)==len(old)+1
    preserved=[lines[0]]+[line for line,row in zip(lines[1:],old) if row[key]!=new[0][key]]
    with path.open('w',newline='',encoding='utf-8') as f:
        f.writelines(preserved); w=csv.DictWriter(f,fields)
        w.writerows({field:r.get(field,'') for field in fields} for r in new)
print(f'Imported {len(inputs)} inputs, {len(outputs)} outputs, {len(assumptions)} assumptions; statuses partial.')
