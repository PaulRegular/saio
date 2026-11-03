"""Import the official January 2026 GOA Pacific cod run without deriving age catches."""
import csv
import io
import sys
from pathlib import Path
from collections import defaultdict

root = Path(sys.argv[1]) / 'analysis/comp_assessments'
cache = root / 'source_cache/afsc_cod_goa_2026'
assessment = 'afsc_cod_goa_2026'
stock_id = 'afsc_cod_goa'
report = 'https://meetings.npfmc.org/CommentReview/DownloadFile?fileName=C1+GOA+Pcod+Assessment.pdf&p=f00593eb-12f5-458c-842e-a5cdd45306bb.pdf'
framework = 'https://files.npfmc.org/SAFE/2024/GOApcod.pdf'
repo = 'https://github.com/afsc-assessments/goapcod'
native = repo + '/blob/e632807e4947686c16caf99b864bfe8466f8dbca/docs/2025_Assessment/January_Model/model_files/M24.0_SS3_files.zip'
sections = defaultdict(dict)
for row in csv.DictReader((cache/'native_observation_sections_raw.csv').open()):
    sections[row['section']].setdefault(int(row['row']), {})[int(row['column'])] = float(row['value'])
inputs, outputs, assumptions = [], [], []
labels = {1:'Trawl fishery', 2:'Longline and jig fishery', 3:'Pot fishery', 4:'NMFS bottom-trawl survey', 5:'NMFS longline survey'}

def add(section, number, row, measure, basis, value, unit, **dimensions):
    fleet = int(row[3])
    inputs.append(dict(assessment_id=assessment, type='catch' if fleet<=3 else 'index',
                       measure=measure, basis=basis, fleet=labels[fleet] if fleet<=3 else '',
                       survey=labels[fleet] if fleet>3 else '', year=int(row[1]), year_basis='calendar_year',
                       value=value, unit=unit, source_type='native_model',
                       source_reference=native+'; GOAPcod2025Dec08.dat; '+section+' record '+str(number),
                       **dimensions))

for number, row in sections['catch'].items():
    if row[1]>0 and row[3] in (1,2,3):
        add('catch',number,row,'total_biomass','biomass',row[4],'t',
            notes='Native annual catch; initial equilibrium catches are separate model inputs not included here. Terminal catch may be assumed.')
for number, row in sections['index'].items():
    if row[1]>0 and row[3] in (4,5):
        for measure,basis,value,unit in [('total_numbers','numbers',row[4],'thousand fish' if row[3]==4 else 'relative population number'),
                                         ('log_index_sd','log_scale',row[5],'log scale')]:
            add('index',number,row,measure,basis,value,unit,sampling_time=(row[2]-1)/12,
                notes='Native month 7 gives year fraction 0.5. Bottom-trawl abundance and longline relative population number retain distinct native scales.')
for section in ('length','age'):
    for number,row in sections[section].items():
        if row[1]<=0 or row[3] not in labels: continue
        size = row[6] if section=='length' else row[9]
        assert size>0
        start = 7 if section=='length' else 10
        bins = [4.5+5*i for i in range(21)] if section=='length' else list(range(1,11))
        values = [row[j] for j in range(start,start+len(bins))]
        assert abs(sum(values)-1)<0.0001
        for bin_value,value in zip(bins,values):
            dimensions = dict(observation_id=f'{section}_{number}',sample_size=size,partition=int(row[5]),
                              sampling_time=(row[2]-1)/12,
                              sex='combined', notes='Native number proportions and supplied sample size; negative fleet/year rows excluded. Month retained through sampling_time.')
            if section=='length':
                dimensions['length_bin']=bin_value
                measure='proportion_at_length'
            else:
                dimensions.update(age=bin_value,age_error=int(row[6]),length_bin_lower=row[7],length_bin_upper=row[8])
                dimensions['notes']+=' Conditional labels retained verbatim; Lbin_method=1. They are not asserted to be centimetre bounds. Age 10 is 10+.'
                measure='conditional_proportion_at_age'
            add(section,number,row,measure,'proportion_numbers',value,'proportion',**dimensions)
native_lines=(cache/'accepted_model/GOAPcod2025Dec08.dat').read_text().splitlines()
start=next(i for i,line in enumerate(native_lines) if '#_year\tvariable\tindex' in line)+1
for line in native_lines[start:]:
    values=line.split('#')[0].split()
    if not values: continue
    year,variable,value=map(float,values)
    if year==-9999: break
    inputs.append(dict(assessment_id=assessment,type='covariate',measure='environmental_covariate',basis='native_covariate',
                       survey=labels[5],year=int(year),year_basis='calendar_year',value=value,unit='native covariate scale',
                       observation_id='environment_1',source_type='native_model',source_reference=native+'; environmental variable 1',
                       notes='Native temperature covariate linked to longline catchability via control env_var&link=101. Preserve supplied signed values; scaling units unresolved, no restandardization.'))
assert sum(r['type']=='covariate' for r in inputs)==46
for row in csv.DictReader((cache/'historical_summary_verified.csv').open()):
    outputs.append(dict(assessment_id=assessment, type='recruitment' if row['measure']=='recruitment' else 'biomass',
                        measure=row['measure'],year=row['year'],age=0 if row['measure']=='recruitment' else '',
                        value=row['value'],se=row['reported_sd'],unit=row['unit'],source_type='official_table',
                        source_reference=report+'; Table '+row['table'],
                        notes='Current official historical estimate. SSB is female. Recruitment unit corrected to billion fish using native outputs and reporting code; printed heading says millions. SD retained without inventing intervals.'))
for year in range(1977,2026):
    elevated=2014<=year<=2016
    for age in range(11):
        outputs.append(dict(assessment_id=assessment,type='mortality',measure='natural_mortality_at_age',year=year,age=age,
                            age_group='10+' if age==10 else '',value=.84 if elevated else .5,se=.053 if elevated else .023,
                            unit='per year',source_type='official_table',source_reference=report+'; Table 2.6; '+native+'; natM_type=0; block 4',
                            notes='Rounded published estimated M and SD expanded according to native age-constant model and 2014–2016 replacement block. All cells in each block share one parameter, not independent estimates. No intervals invented.'))
for component,setting,value,notes in [
    ('assessment','accepted_model','Model 24.0; January 2026 update','February 2026 Council/SSC adopted update; supersedes December rollover.'),
    ('population','modeled_years','1977–2025','Historical model years; forecasts excluded.'),
    ('population','ages','0–10; plus group 10+','Age composition bins are 1–10; recruitment is age 0.'),
    ('population','recruitment_age','0',''),
    ('population','sex_structure','Combined-sex population','Published female SSB divides native spawning output by two.'),
    ('biology','spawning_time','0','Native spawning month 1.'),
    ('catch','representation','Three total catches plus length and conditional age compositions','Longline fleet includes jig. No age-specific catch is manufactured.'),
    ('index','active_streams','NMFS bottom-trawl and NMFS longline surveys','Other named fleet definitions have disabled index likelihoods.'),
    ('index','sampling_time','0.5','All active native index observations use month 7.'),
    ('M','treatment','Estimated age-constant M with 2014–2016 temporal block','Fitted M surfaces still need extraction; parameter starts are not fixed biological inputs.'),
    ('biology','maturity','Length-based logistic','Do not substitute a fitted age surface for an original age-vector input.'),
    ('recruitment','stock_recruit','Beverton–Holt','Native stock-recruit code 3.'),
    ('catch','composition_likelihood','Multinomial','Native CompError code 0; supplied sample sizes retained.'),
    ('assessment','unresolved_inputs','unknown','Ageing-error vectors and equilibrium catches retained in assumptions; temperature covariate represented. Biological parameter interpretation and fitted N/F surfaces remain incomplete.'),
    ('F','complete_selectivity_structure','unknown','Native control file cached; full statistical inventory pending.'),
    ('q','complete_parameter_structure','unknown','Native control file cached; full statistical inventory pending.')]:
    assumptions.append(dict(assessment_id=assessment,component=component,setting=setting,value=value,notes=notes,source_reference=native+'; '+report))
assumptions.append(dict(assessment_id=assessment,component='q',survey=labels[5],setting='environmental_link',
                        value='Native environmental variable 1; control code 101',source_reference=native+'; Model24_0.ctl LnQ_base_LLSrv(5)',
                        notes='46 supplied annual covariate values represented; link interpretation follows Stock Synthesis time-varying parameter convention.'))
assumptions.append(dict(assessment_id=assessment,component='biology',setting='mean_size_at_age_likelihood',
                        value='Disabled: all 16 observations have negative fleet code -4',source_reference=native+'; MeanSize_at_Age_obs',
                        notes='Diagnostic observations are cached but excluded from canonical fitted inputs.'))
for number,row in sections['catch'].items():
    if row[1]==-999 and row[3] in (1,2,3):
        assumptions.append(dict(assessment_id=assessment,component='catch',fleet=labels[int(row[3])],setting='initial_equilibrium_catch',
                                value=str(row[4]),source_reference=native+'; catch record '+str(number),
                                notes='Native equilibrium catch in tonnes; source year code -999 is not a calendar year. Supplied catch SE '+str(row[5])+'.'))
start=next(i for i,line in enumerate(native_lines) if '#_N_ageerror_definitions' in line)+1
vectors=[]
for line in native_lines[start:]:
    values=line.split('#')[0].split()
    if values:
        assert len(values)==11
        vectors.append(values)
    if len(vectors)==4: break
for definition in (1,2):
    for part,values in zip(('mean','sd'),vectors[2*(definition-1):2*definition]):
        assumptions.append(dict(assessment_id=assessment,component='biology',setting=f'age_error_{definition}_{part}_input',
                                value='; '.join(values),source_reference=native+'; ageing_error',
                                notes='Native age-0 through age-10 definition vector, stored once. Definition 2 mean values -1 are model-control flags, not measured negative ages; do not use as an empirical misclassification matrix.'))
for setting,value in [('weight_length_coefficient','3.4297e-06'),('weight_length_exponent','3.27469'),
                      ('maturity_length_50_percent_cm','53.7'),('maturity_logistic_slope','-0.273657'),
                      ('stock_recruit_steepness','1'),('recruitment_sigma','0.44')]:
    assumptions.append(dict(assessment_id=assessment,component='biology' if setting.startswith(('weight','maturity')) else 'recruitment',
                            setting=setting,value=value,source_reference=native+'; Model24_0.ctl',
                            notes='Fixed native parameter (negative estimation phase); not an estimated biological surface.'))
specific=[r for r in assumptions if r['setting']=='unresolved_inputs'][0]
specific['notes']='Equilibrium catches, ageing-error vectors and temperature covariate represented. Mean-size observations are disabled. Full fitted N/F surfaces and remaining statistical interpretation pending.'
stock=dict(stock_id=stock_id,charbonneau_id='AFSC_GOA_Gadus_macrocephalus',authority='NOAA-AFSC',authority_stock_id='GOA Pacific cod',scientific_name='Gadus macrocephalus',common_name='Gulf of Alaska Pacific cod',area='Gulf of Alaska',region='Alaska',ocean='Northeast Pacific',notes='Official January 2026 assessment update; combined-sex Stock Synthesis model.')
record=dict(assessment_id=assessment,stock_id=stock_id,assessment_year=2026,terminal_year=2025,estimate_terminal_year=2025,assessment_type='annual',model_family='Stock Synthesis',model_version='24.0',framework_year=2024,is_current='TRUE',is_applied='TRUE',assessment_url=report,framework_url=framework,data_url=native,repository_url=repo,assumptions_status='partial',inputs_status='partial',outputs_status='partial',notes='Verified current native inputs and matching compact fitted outputs. Three catch fleets and two active surveys represented with native compositions. Further biological/covariate/equilibrium inputs, statistical inventory and N/F-at-age outputs pending; rounded M surface represented from reported parameters and native blocks. See source_reviews/afsc_cod_goa.md.')
dimensions=['observation_id','length_bin','length_bin_lower','length_bin_upper','sample_size','age_error','partition']
for filename,new,key in [('stocks.csv',[stock],'stock_id'),('assessments.csv',[record],'assessment_id'),('inputs.csv',inputs,'assessment_id'),('outputs.csv',outputs,'assessment_id'),('assumptions.csv',assumptions,'assessment_id')]:
    path=root/'database'/filename
    content=path.read_bytes().decode('utf-8-sig')
    reader=csv.DictReader(io.StringIO(content)); fields=reader.fieldnames; old=list(reader)
    lines=content.splitlines(keepends=True)
    assert len(lines)==len(old)+1
    extra=[f for f in dimensions if f not in fields] if filename=='inputs.csv' else []
    fields=fields+extra
    def expand(line,header=False):
        return line.rstrip('\r\n')+(','+','.join(extra) if header and extra else ','*len(extra))+'\n'
    preserved=[expand(lines[0],True)]+[expand(line) for line,row in zip(lines[1:],old) if row[key]!=new[0][key]]
    with path.open('w',newline='',encoding='utf-8') as f:
        f.writelines(preserved)
        csv.DictWriter(f,fields).writerows({field:r.get(field,'') for field in fields} for r in new)
print(f'Imported {len(inputs)} inputs, {len(outputs)} outputs, {len(assumptions)} assumptions; all statuses partial.')
