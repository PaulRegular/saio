"""Import verified native inputs and outputs of the 2026 NEA cod SAM run."""
import csv
import io
import math
import sys
from pathlib import Path

root = Path(sys.argv[1]) / 'analysis/comp_assessments'
cache = root / 'source_cache/ices_cod_northeast_arctic_2026'
assessment = 'ices_cod_northeast_arctic_2026'
stock_id = 'ices_cod_northeast_arctic'
run = 'https://stockassessment.org/datadisk/stockassessment/userdirs/user3/NEAcod_2026_final/'
report = 'https://www.hi.no/hi/nettrapporter/imr-vniro-2026-5'
source = run + 'baserun/model.RData'
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
                       transformation='exp(logobs)' if field == 'value' and kind in ('catch', 'index') else '', notes=notes))

def output_row(kind, measure, row, unit, fleet='', survey='', field='value', notes=''):
    value = number(row[field])
    if value is None:
        return
    outputs.append(dict(assessment_id=assessment, type=kind, measure=measure, fleet=fleet,
                        survey=survey, year=row['year'], age=row.get('age',''), value=value,
                        age_group='5–10' if measure == 'Fbar' else '',
                        lwr=row.get('lwr',''), upr=row.get('upr',''), unit=unit,
                        source_type='native_model', source_reference=source,
                        notes=notes))

obs = rows('native_observations.csv')
assert len(obs) == 2710
assert sum(number(r['value']) is not None for r in obs) == 2377
for row in obs:
    catch = row['fleet'] == '1'
    label = row['fleet_name']
    unit = 'thousand fish' if catch else 'native survey index'
    input_row('catch' if catch else 'index', 'numbers_at_age', 'numbers', row, unit,
              fleet=label if catch else '', survey='' if catch else label,
              timing='' if catch else row['sampling_time'],
              notes='Original fitted observation; excluded/missing log-observations are not restored from raw files. Age 15 is 15+ for catch; survey age 12 is its terminal plus group.')
    if number(row['value']) is not None:
        output_row('catch' if catch else 'index', 'numbers_at_age', row, unit,
                   fleet=label if catch else '', survey='' if catch else label,
                   field='prediction', notes='Prediction for the same fitted observation row; uncertainty unavailable in this export.')

for name, kind, measure, basis, unit in [
    ('stockMeanWeight', 'weight', 'weight_at_age', 'kg_per_fish', 'kg'),
    ('catchMeanWeight', 'catch_weight', 'weight_at_age', 'kg_per_fish', 'kg'),
    ('propMat', 'maturity', 'maturity_at_age', 'proportion', 'proportion'),
    ('natMor', 'M', 'natural_mortality_at_age', 'per_year', 'per year')]:
    for row in rows(f'native_{name}.csv'):
        note = 'Matrix consumed by the official fit; age 15 represents 15+.'
        if name == 'natMor':
            note += ' Fixed within SAM; includes external iterative cannibalism mortality. Raw nm.dat alone is not the final input.'
        input_row(kind, measure, basis, row, unit, fleet=row.get('fleet',''), notes=note)

for name, kind, measure, unit in [('logN','population','numbers_at_age','thousand fish'),
                                 ('logF','mortality','fishing_mortality_at_age','per year')]:
    for row in rows(f'native_{name}.csv'):
        if name == 'logF' and int(row['year']) == 2026:
            continue
        output_row(kind, measure, row, unit, fleet='Residual catch' if name == 'logF' else '',
                   notes='Native fitted state; age 15 represents 15+. F ages 14 and 15 share the same fitted state.')
for row in rows('native_summary.csv'):
    metric = row['metric']
    if metric == 'logfbar' and int(row['year']) == 2026:
        continue
    kind, measure, unit = {'logssb':('biomass','SSB','t'), 'logtsb':('biomass','total_biomass','t'),
                          'logR':('recruitment','recruitment','thousand fish'), 'logfbar':('mortality','Fbar','per year')}[metric]
    output_row(kind, measure, row, unit,
               notes='Native estimate with 95% log-scale Wald interval. SE omitted because canonical SE has no scale field. Recruitment is age 3; Fbar is ages 5–10. Fitted 2026 recruitment is not the RCT3 forecast used for advice.')

for key,measure in [('propF','fraction_F_before_spawning'),('propM','fraction_M_before_spawning')]:
    for row in rows('native_'+key+'.csv'):
        inputs.append(dict(assessment_id=assessment,type='biology',measure=measure,basis='proportion',
                           fleet=row.get('fleet',''),year=row['year'],year_basis='calendar_year',age=row['age'],value=row['value'],unit='proportion',
                           source_type='native_model',source_reference=source+'; fit$data$'+key,
                           notes='Original full source matrix; zero mortality fraction before spawning. Distinct from survey sampling timing.'))
for row in rows('native_catchability.csv'):
    outputs.append(dict(assessment_id=assessment,type='catchability',measure='q',survey=row['survey'],age=row['age'],
                        value=row['value'],se=row['se'],lwr=row['lwr'],upr=row['upr'],unit='native index coefficient',
                        source_type='native_model',source_reference=source+'; logFpar key '+row['key'],
                        notes='Time-invariant q coefficient; no density-dependent power. Natural-scale delta-method SE and 95% log-Wald interval. Ages 11 and 12 share the same fitted coefficient. Native survey units retained.'))

def assumption(component, setting, value, notes='', survey='', fleet='', reference=None):
    assumptions.append(dict(assessment_id=assessment, component=component, setting=setting,
                            value=value, notes=notes, survey=survey, fleet=fleet,
                            source_reference=reference or source))

assumption('assessment','authority','JRN-AFWG (IMR/VNIRO), outside ICES', reference=report)
assumption('population','modeled_years','1946–2026')
assumption('population','modeled_ages','3–15; terminal 15+ group')
assumption('population','recruitment_age','3')
assumption('population','sex_region_season_structure','Combined sexes; single NEA cod stock; annual model')
assumption('population','initial_state','initState=0: no explicit first-state process density',
           'First-year logN/logF remain latent random effects in the Laplace fit. Ordinary N/F transition densities start in year 2; a broad first-state prior is added only for observation residual calculations, not the ordinary assessment likelihood.',
           reference='https://github.com/fishfollower/SAM/blob/1cc464b80f6f/stockassessment/inst/include/SAM/n.hpp; https://github.com/fishfollower/SAM/blob/1cc464b80f6f/stockassessment/inst/include/SAM/f.hpp')
assumption('recruitment','treatment','Stochastic log recruitment; no stock–recruit relationship','stockRecruitmentModelCode=0; no constant recruitment breaks.')
assumption('N','process_variance_sharing','Age 3 separate; ages 4–15 share a variance','keyVarLogN=0,1,1,1,1,1,1,1,1,1,1,1,1')
assumption('F','state_sharing','Separate ages 3–13; ages 14 and 15 share a state','keyLogFsta=0,1,2,3,4,5,6,7,8,9,10,11,11',fleet='Residual catch')
assumption('F','process','Independent log-F random-walk innovations across represented age states','corFlag=0; this source-model process is not tinyAM approx_rw.',fleet='Residual catch',reference=run+'conf/model.cfg')
assumption('F','process_variance_sharing','Age 3 separate from older represented F states','keyVarF determines the two innovation variances.',fleet='Residual catch')
assumption('F','Fbar_age_range','5–10')
assumption('M','treatment','Fixed input within SAM: background 0.2 plus external iterative cannibalism mortality',reference=report+'; section 3.3; Table 3.17')
assumption('biology','weights_maturity','Fixed supplied annual age matrices','stockWeightModel=catchWeightModel=matureModel=0')
assumption('biology','pre_spawning_F_fraction','0 at every modeled year and age','Verified fit$data$propF.')
assumption('biology','pre_spawning_M_fraction','0 at every modeled year and age','Verified fit$data$propM.')
assumption('catch','landings_fraction','1 at every catch year and age','No modeled discard component; supplied land/discard weights equal catch weights.',fleet='Residual catch')
assumption('catch','excluded_observations','12 catch cells have missing log-observations','Source cn.dat contains some positive values excluded from fit$data; preserve the actual fitted exclusions.',fleet='Residual catch')
assumption('catch','observation_likelihood','Lognormal, independent across age','obsLikelihoodFlag=LN; obsCorStruct=ID.',fleet='Residual catch')
assumption('observation','prediction_variance_link','Enabled for four survey parameter groups','Introduced in official 2026 assessment; numerical keys retained in cached configuration.',reference=report+'; section 3.4.1; Table 3.14')
for fleet in range(2,7):
    group = [r for r in obs if int(r['fleet']) == fleet]
    label = group[0]['fleet_name']
    assumption('survey','sampling_time',group[0]['sampling_time'],survey=label)
    assumption('survey','age_range','3–12, with survey terminal plus group',survey=label)
    assumption('q','structure','Time-invariant age-specific q; ages 11–12 share q; no density-dependent power',survey=label)
    assumption('observation','likelihood','Lognormal with AR observation correlation across age',survey=label)
assumption('assessment','forecast_distinction','RCT3 recruitment replaces fitted recruitment for short-term advice','2026 fitted recruitment 132.286 million versus advice forecast 243 million; do not merge the two.',reference=report+'; section 3.6.2')

stock = dict(stock_id=stock_id,charbonneau_id='ICES-AFWG_NEA1-2_Gadus_morhua',authority='JRN-AFWG',
             authority_stock_id='cod.27.1-2',scientific_name='Gadus morhua',common_name='Northeast Arctic cod',
             area='ICES subareas 1 and 2',region='Barents Sea and Norwegian Sea',ocean='Northeast Atlantic',
             notes='Historical ICES stock; official assessment has been conducted outside ICES since 2022 by JRN-AFWG.')
record = dict(assessment_id=assessment,stock_id=stock_id,assessment_year=2026,terminal_year=2026,
              estimate_terminal_year=2026,assessment_type='assessment_update',model_family='SAM',
              model_version='stockassessment 0.12.0; RemoteSha 1cc464b80f6f',is_current='TRUE',is_applied='TRUE',
              framework_year=2021,assessment_url=report,framework_url='https://doi.org/10.17895/ices.pub.7920',
              data_url=run+'data/',model_url=source,repository_url='',inputs_status='partial',
              outputs_status='partial',assumptions_status='partial',
              notes='Verified official final run: 320 summary and 3120 age-specific report values match within rounding. All fitted catch and five survey streams, weights, maturity and final M input represented. Survey native units, external cannibalism auxiliary data and detailed statistical-key/initial-state semantics require further review. Catch ends 2025; fitted surveys extend 2026. Native estimates kept separate from short-term advice forecasts. Numerical q and age-state uncertainty not yet exported. See source_reviews/ices_cod_northeast_arctic.md.')
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
