"""Import verified native inputs and outputs of the 2026 Northern Shelf haddock SAM run."""
import csv
import io
import sys
from pathlib import Path

root = Path(sys.argv[1]) / 'analysis/comp_assessments'
cache = root / 'source_cache/ices_haddock_north_sea_2026'
assessment = 'ices_haddock_north_sea_2026'
stock_id = 'ices_haddock_north_sea'
run = 'https://stockassessment.org/datadisk/stockassessment/userdirs/user3/NShaddock_WGNSSK2026_Run1/'
report = 'https://ndownloader.figshare.com/files/66104291'
source = run + 'run/model.RData'
inputs, outputs, assumptions = [], [], []

def rows(name):
    return list(csv.DictReader((cache / name).open(encoding='utf-8-sig')))

def number(value):
    return None if value in ('NA', '') else float(value)

def input_row(kind, measure, basis, row, unit, fleet='', survey='', timing='', notes='', field='value'):
    value = number(row[field])
    if value is None:
        return
    inputs.append(dict(assessment_id=assessment, type=kind, measure=measure, basis=basis,
                       fleet=fleet, survey=survey, year=row['year'], year_basis='calendar_year',
                       age=row['age'], value=value, unit=unit, sampling_time=timing,
                       source_type='native_model', source_reference=source + '; fit$data',
                       transformation='exp(logobs)' if measure == 'numbers_at_age' and kind in ('catch', 'index') else '', notes=notes))

def output_row(kind, measure, row, unit, fleet='', survey='', field='value', notes=''):
    value = number(row[field])
    if value is None:
        return
    outputs.append(dict(assessment_id=assessment, type=kind, measure=measure, fleet=fleet,
                        survey=survey, year=row['year'], age=row.get('age',''), value=value,
                        age_group='2–4' if measure == 'Fbar' else '',
                        lwr=row.get('lwr',''), upr=row.get('upr',''), unit=unit,
                        source_type='native_model', source_reference=source,
                        notes=notes))

obs = rows('native_observations.csv')
assert len(obs) == 1153
assert sum(number(r['value']) is not None for r in obs) == 1153
for row in obs:
    catch = row['fleet'] == '1'
    label = row['fleet_name']
    unit = 'thousand fish' if catch else 'native survey index'
    input_row('catch' if catch else 'index', 'numbers_at_age', 'numbers', row, unit,
              fleet=label if catch else '', survey='' if catch else label,
              timing='' if catch else row['sampling_time'],
              notes='Original fitted observation; excluded/missing log-observations are not restored from raw files. Age 8 is the terminal 8+ group for catch and both surveys.')
    if number(row['value']) is not None:
        output_row('catch' if catch else 'index', 'numbers_at_age', row, unit,
                   fleet=label if catch else '', survey='' if catch else label,
                   field='prediction', notes='Prediction for the same fitted observation row; uncertainty unavailable in this export.')

for name, kind, measure, basis, unit in [
    ('stockMeanWeight', 'weight', 'weight_at_age', 'kg_per_fish', 'kg'),
    ('catchMeanWeight', 'catch_weight', 'weight_at_age', 'kg_per_fish', 'kg'),
    ('propMat', 'maturity', 'maturity_at_age', 'proportion', 'proportion'),
    ('natMor', 'M', 'natural_mortality_at_age', 'per_year', 'per year'),
    ('landFrac', 'catch', 'landings_fraction_at_age', 'proportion', 'proportion'),
    ('landMeanWeight', 'catch_weight', 'landings_weight_at_age', 'kg_per_fish', 'kg'),
    ('disMeanWeight', 'catch_weight', 'discard_weight_at_age', 'kg_per_fish', 'kg')]:
    for row in rows(f'native_{name}.csv'):
        note = 'Matrix consumed by the official fit; age 8 represents 8+.'
        if name == 'natMor':
            note += ' Fixed externally supplied SMS mortality; plus-group aggregation performed before fitting.'
        input_row(kind, measure, basis, row, unit, fleet=row.get('fleet',''), notes=note)

for name, kind, measure, unit in [('logN','population','numbers_at_age','thousand fish'),
                                 ('logF','mortality','fishing_mortality_at_age','per year')]:
    for row in rows(f'native_{name}.csv'):
        if name == 'logF' and int(row['year']) == 2026:
            continue
        output_row(kind, measure, row, unit, fleet='Residual catch' if name == 'logF' else '',
                   notes='Native fitted state; age 8 represents 8+.')
for row in rows('native_summary.csv'):
    metric = row['metric']
    if metric == 'logfbar' and int(row['year']) == 2026:
        continue
    kind, measure, unit = {'logssb':('biomass','SSB','t'), 'logtsb':('biomass','total_biomass','t'),
                          'logR':('recruitment','recruitment','thousand fish'), 'logfbar':('mortality','Fbar','per year')}[metric]
    output_row(kind, measure, row, unit,
               notes='Native estimate with published approximate 95% interval exp(log estimate +/- 2 log-SE). SE omitted because canonical SE has no scale field. Recruitment is age 0; Fbar is ages 2–4. Fitted 2026 recruitment is distinct from resampled advice recruitment.')

for key,measure in [('propF','fraction_F_before_spawning'),('propM','fraction_M_before_spawning')]:
    for row in rows('native_'+key+'.csv'):
        input_row('biology',measure,'proportion',row,'proportion',fleet=row.get('fleet',''),
                  notes='Original full year-age spawning-fraction matrix used by SAM; values are zero. Preserve source matrix without inventing a nonzero spawning time.')

for row in rows('native_catchability.csv'):
    outputs.append(dict(assessment_id=assessment,type='catchability',measure=row['measure'],survey=row['survey'],age=row['age'],
                        value=row['value'],se=row['se'],lwr=row['lwr'],upr=row['upr'],unit='native index coefficient' if row['measure']=='q' else 'dimensionless',
                        source_type='native_model',source_reference=source+'; '+('logFpar' if row['measure']=='q' else 'logQpow')+' key '+row['key'],
                        notes='Time-invariant coefficient in I=q*(N at survey time)^power. Natural-scale delta-method SE; 95% log-Wald interval. q units depend on native survey scale and power; it is not a simple proportion caught.'))

def assumption(component, setting, value, notes='', survey='', fleet='', reference=None):
    assumptions.append(dict(assessment_id=assessment, component=component, setting=setting,
                            value=value, notes=notes, survey=survey, fleet=fleet,
                            source_reference=reference or source))

assumption('assessment','authority','ICES WGNSSK',reference=report)
assumption('population','modeled_years','1972–2026')
assumption('population','modeled_ages','0–8; terminal 8+ group')
assumption('population','recruitment_age','0')
assumption('population','sex_region_season_structure','Combined sexes; one Northern Shelf stock; annual model')
assumption('population','initial_state','initState=0: no explicit first-state process density',
           'First-year logN/logF remain latent random effects in the Laplace fit. Ordinary N/F transition densities start in year 2; a broad first-state prior is added only for observation residual calculations, not the ordinary assessment likelihood.',
           reference='https://github.com/fishfollower/SAM/blob/1cc464b80f6f/stockassessment/inst/include/SAM/n.hpp; https://github.com/fishfollower/SAM/blob/1cc464b80f6f/stockassessment/inst/include/SAM/f.hpp')
assumption('recruitment','treatment','Log-recruitment random walk; no stock–recruit relationship','stockRecruitmentModelCode=0; no constant-recruitment breaks.')
assumption('N','process_variance_sharing','Recruitment separate; ages 1–7 shared; plus group separate','keyVarLogN=0,1,1,1,1,1,1,1,2')
assumption('F','state_sharing','Independent representation at every modeled age','keyLogFsta=0,1,2,3,4,5,6,7,8',fleet='Residual catch')
assumption('F','process','Age-correlated log-F random-walk increments','corFlag=2: AR1 correlation between age innovations; common innovation variance across ages.',fleet='Residual catch',reference=run+'conf/model.cfg')
assumption('F','Fbar_age_range','2–4')
assumption('M','treatment','Fixed annual supplied SMS mortality; age 8+ aggregated before fitting',reference=report+'; section 8.2.4; '+run+'src/datascript.R')
assumption('biology','spawning_fractions','Zero F and M fractions before spawning in every native year-age cell','Both native matrices represented directly; beginning-of-year SSB definition.')
assumption('biology','weights_maturity','Fixed annual supplied matrices; 8+ calculated before fitting','Stock weight, maturity and M use catch-number weights; component catch weights use corresponding component-number weights.',reference=run+'src/datascript.R')
assumption('catch','components','Single total-catch fleet; landings, discards, BMS and industrial bycatch contribute','Component weights and landings fractions retained as supplied to SAM.',fleet='Residual catch')
assumption('observation','likelihood','Lognormal; independent observation errors across age','obsCorStruct=ID for all three fleets.')
assumption('observation','variance_sharing','Catch keys 0,1,2,2,2,2,2,2,2; Q1 keys -1,3,4,4,5,5,5,6,6; Q3Q4 keys 7,8,9,10,10,10,11,11,11','Keys index separate log-observation variance parameters.',reference=run+'conf/model.cfg')
assumption('observation','survey_weighting','Relative precision weight = 1/log(1+CV^2); variance scale remains estimated','CV columns follow read.ices matrix semantics, including its leading column. Original weights preserved without shifting.',reference=run+'src/datascript.R')
for label,ages,timing in [('delta-GAMNS-WCQ1','1–8+',.125),('delta-GAMNS-WCQ3+Q4','0–8+',.75)]:
    assumption('survey','age_range',ages,survey=label)
    assumption('survey','sampling_time',timing,survey=label)
    assumption('q','structure','Time-invariant age-specific coefficient, with density-dependent power at young ages',
               'Power applies at Q1 age 1 and Q3+Q4 ages 0–1; all other fitted survey ages have power 1. I=q*(N at survey time)^power.',
               survey=label,reference=run+'conf/model.cfg; https://github.com/fishfollower/SAM/blob/1cc464b80f6f/stockassessment/inst/include/SAM/predobs.hpp')
assumption('assessment','forecast_distinction','Advice resamples 2000–2025 recruitment and uses forecast weights and three-year mean maturity/M','Native fitted 2026 SSB differs from advice forecast SSB; preserve native quantities.',reference=report+'; section 8.6')
for row in obs:
    if row['fleet']=='1':
        continue
    input_row('index','log_index_sd','log_scale',dict(row,value=1/float(row['weight'])**.5),
              'relative log-scale SD',survey=row['fleet_name'],timing=row['sampling_time'],
              notes='Relative supplied log-SD factor = 1/sqrt(native precision weight); observation variance is estimated scale squared times this factor squared. Native precision weight='+row['weight'])
    inputs[-1]['transformation']='1/sqrt(fit$data$weight); equivalent to sqrt(log(1+CV^2))'

stock=dict(stock_id=stock_id,charbonneau_id='ICES-WGNSSK_NS  4-6a-20_Melanogrammus_aeglefinus',authority='ICES',
           authority_stock_id='had.27.46a20',scientific_name='Melanogrammus aeglefinus',common_name='Northern Shelf haddock',
           area='Subarea 4, Division 6.a and Subdivision 20',region='North Sea, West of Scotland and Skagerrak',ocean='Northeast Atlantic',
           notes='Combined stock since 2014; current assessment uses SAM, replacing historical TSA represented in Charbonneau metadata.')
record=dict(assessment_id=assessment,stock_id=stock_id,assessment_year=2026,terminal_year=2026,estimate_terminal_year=2026,
            assessment_type='assessment_update',model_family='SAM',model_version='stockassessment 0.12.0; RemoteSha 1cc464b80f6f',
            is_current='TRUE',is_applied='TRUE',framework_year=2022,assessment_url=report,
            framework_url='',data_url=run+'data/',model_url=source,repository_url='',
            inputs_status='partial',outputs_status='partial',assumptions_status='partial',
            notes='Official final run verified against 648 summary estimates/interval endpoints and 981 N/F-at-age values. All catch and both survey streams plus supplied matrices and relative survey SD factors represented. Survey-unit clarification, benchmark/2025 review and detailed other framework semantics remain unresolved. Catchability coefficients and powers with transformed uncertainty are represented; state uncertainty remains pending. Baseline object in baserun is historical and not used. See source_reviews/ices_haddock_north_sea.md.')
for filename,new,key in [('stocks.csv',[stock],'stock_id'),('assessments.csv',[record],'assessment_id'),
                         ('inputs.csv',inputs,'assessment_id'),('outputs.csv',outputs,'assessment_id'),
                         ('assumptions.csv',assumptions,'assessment_id')]:
    path=root/'database'/filename
    content=path.read_bytes().decode('utf-8-sig')
    reader=csv.DictReader(io.StringIO(content)); fields=reader.fieldnames; old=list(reader)
    lines=content.splitlines(keepends=True)
    assert len(lines)==len(old)+1
    preserved=[lines[0]]+[line for line,row in zip(lines[1:],old) if row[key]!=new[0][key]]
    with path.open('w',newline='',encoding='utf-8') as f:
        f.writelines(preserved)
        writer=csv.DictWriter(f,fields)
        writer.writerows({field:row.get(field,'') for field in fields} for row in new)
print(f'Imported {len(inputs)} inputs, {len(outputs)} outputs, {len(assumptions)} assumptions; statuses remain partial.')
