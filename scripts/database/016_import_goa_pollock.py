"""Import official 2024 GOA pollock native inputs and final-report outputs."""
import csv
import io
import sys
from collections import defaultdict
from pathlib import Path

root = Path(sys.argv[1]) / 'analysis/comp_assessments'
cache = root / 'source_cache/afsc_pollock_goa_2024'
assessment = 'afsc_pollock_goa_2024'
stock_id = 'afsc_pollock_goa'
revision = 'aefe1692520510d55fd25db60121b292a53840a3'
repo = 'https://github.com/afsc-assessments/GOApollock'
native = repo + '/blob/' + revision + '/data/2024/pk24_12.txt'
code = repo + '/blob/' + revision + '/data/2024/goa_pk.cpp'
report = 'https://files.npfmc.org/SAFE/2024/GOApollock.pdf'
data = defaultdict(dict)
for row in csv.DictReader((cache / 'native_inputs_raw.csv').open()):
    data[row['key']][int(row['row']), int(row['column'])] = float(row['value'])
def vector(key):
    return [data[key][i, 1] for i in range(1, len(data[key]) + 1)]
def matrix_row(key, i):
    return [data[key][i, j] for j in range(1, 11)]
inputs, outputs, assumptions = [], [], []
def add(kind, measure, basis, year, value, unit, age='', fleet='', survey='', timing='', field='', notes='', transformation='', source=native, sample_size=''):
    inputs.append(dict(assessment_id=assessment, type=kind, measure=measure, basis=basis,
                       year='' if year is None else int(year),
                       year_basis='' if year is None else 'calendar_year', value=value, unit=unit, age=age,
                       fleet=fleet, survey=survey, sampling_time=timing, sample_size=sample_size, source_type='reconstructed_source_input' if transformation else 'native_model',
                       source_reference=source + '; ' + field, notes=notes, transformation=transformation))
def assume(component, setting, value, notes='', survey='', fleet='', source=report):
    assumptions.append(dict(assessment_id=assessment, component=component, setting=setting, value=value,
                            notes=notes, survey=survey, fleet=fleet, source_reference=source))

for i, year in enumerate(range(1970, 2025), 1):
    add('catch', 'total_biomass', 'biomass', year, vector('cattot')[i-1], 't', fleet='Combined fishery', field='cattot',
        notes='Total biomass likelihood input; terminal 2024 catch is assumed. Separate number composition ends in 2023.')
    for age in range(1, 11):
        add('catch_weight', 'weight_at_age', 'kg_per_fish', year, data['wt_fsh'][i, age], 'kg', age,
            fleet='Combined fishery', field='wt_fsh', notes='Supplied annual matrix; terminal age 10 is 10+.')
        for key, region in [('wt_srv2', 'Population biomass'), ('wt_srv1', 'Spawning biomass')]:
            row = dict(assessment_id=assessment, type='weight', measure='spawning_weight_at_age' if key=='wt_srv1' else 'weight_at_age', basis='kg_per_fish',
                       year=year, year_basis='calendar_year', age=age, value=data[key][i,age], unit='kg',
                       source_type='native_model', source_reference=code+'; wt_pop=wt_srv2; wt_spawn=wt_srv1',
                       notes='Supplied survey weight matrix used for this biological purpose. Distinct population and spawning weights; 10+.')
            inputs.append(row)
for age, value in enumerate(vector('mat'), 1):
    add('maturity', 'maturity_at_age', 'proportion', None, value, 'proportion', age, field='mat',
        notes='Constant female maturity vector, 1983–2024 average, valid in all model years; stored once. Female fraction 0.5 is applied separately in SSB.')
for age, value in enumerate([1.39, .69, .48, .37, .34, .30, .30, .29, .28, .29], 1):
    add('M', 'natural_mortality_at_age', 'per_year', None, value, 'per year', age, source=code, field='M',
        notes='Fixed external age-specific vector, valid 1970–2024, stored once. natMscalar fixed at 1 by official preparation map.')

for year, value in zip(vector('Ecov_obs_year'), vector('Ecov_obs')):
    add('covariate', 'environmental_covariate', 'native_covariate', year, value, 'native covariate scale',
        survey='Shelikof winter acoustic', field='Ecov_obs',
        notes='Supplied environmental observations linked to latent annual Ecov_exp by a normal observation model. Native values retained without restandardization; physical units unresolved.')
assume('q', 'environmental_observation_sd', '0.02 on native covariate scale, fixed',
       'prepare_par initializes log_Ecov_obs_sd=log(0.02); prepare_map fixes it. Observation likelihood uses the matching calendar-year latent Ecov_exp; latent process uses SCALE(AR1(rho), exp(log_Ecov_sd)).',
       survey='Shelikof winter acoustic', source=code+'; R/tmb_fns.R')

streams = [(1, 'Shelikof winter acoustic'), (2, 'NMFS bottom trawl'),
           (3, 'ADF&G crab/groundfish trawl'), (6, 'Summer acoustic')]
for number, label in streams:
    for year, value, sd in zip(vector(f'srvyrs{number}'), vector(f'indxsurv{number}'), vector(f'indxsurv_log_sd{number}')):
        if sd <= 0:
            continue
        timing = vector(f'yrfrct_srv{number}')[int(year)-1970]
        add('index', 'total_biomass', 'biomass', year, value, 'million t', survey=label, timing=timing,
            field=f'indxsurv{number}', notes='Native numerical scale: N in billions times kg per fish gives million tonnes; no conversion applied.')
        add('index', 'log_index_sd', 'log_scale', year, sd, 'log scale', survey=label, timing=timing,
            field=f'indxsurv_log_sd{number}', notes='SD supplied directly to log-index likelihood; source uses mean bias correction -SD^2/2.')
    for i, year in enumerate(range(1970, 2025), 1):
        for age in range(1,11):
            add('weight', 'weight_at_age', 'kg_per_fish', year, data[f'wt_srv{number}'][i,age], 'kg', age,
                survey=label, field=f'wt_srv{number}', notes='Annual supplied survey prediction weights, including filled model years; 10+.')
    assume('index', 'sampling_time', f'yrfrct_srv{number}', 'Timing supplied annually on each index row.', survey=label, source=native)
    assume('index', 'observation_likelihood', 'Lognormal, supplied log SD, mean bias correction', survey=label, source=code)
    assume('index', 'composition_likelihood', 'Linear Dirichlet-multinomial', 'Official Model 23d; separate from biomass index.', survey=label, source=code)

for number, label in [(0, 'Combined fishery')] + streams:
    years = vector('fshyrs' if number == 0 else f'srv_acyrs{number}')
    key = 'catp' if number == 0 else f'srvp{number}'
    size_key = 'multN_fsh' if number == 0 else f'multN_srv{number}'
    sizes = vector(size_key)
    multiplier = 2 if number in (1,3,6) else 1
    for i, year in enumerate(years, 1):
        if sizes[i-1] <= 0:
            continue
        values = matrix_row(key, i)
        lower = int(vector('ac_yng_fsh')[i-1]) if number==0 else int(vector('ac_yng_srv1')[i-1]) if number==1 else 1
        upper = int(vector('ac_old_fsh')[i-1]) if number==0 else int(vector(f'ac_old_srv{number}')[i-1]) if number in (1,2,6) else 10
        if number in (0,1):
            values[lower-1] += sum(values[:lower-1])
        timing = '' if number==0 else vector(f'yrfrct_srv{number}')[int(year)-1970]
        for age in range(lower, upper+1):
            add('catch' if number==0 else 'index', 'proportion_at_age', 'proportion_numbers', year,
                values[age-1], 'proportion', age, fleet=label if number==0 else '', survey='' if number==0 else label,
                timing=timing, field=key, sample_size=sizes[i-1]*multiplier,
                transformation=f'Accumulate ages 1–{lower} in first fitted bin' if lower>1 else '',
                notes=f'Number composition as fitted, without renormalization. First bin includes ages 1–{lower}; final age 10 is 10+. Input sample size {sizes[i-1]*multiplier:g}; official script multiplier {multiplier}. Supplied sample size is recorded separately; it is not the estimated effective sample size.')
    assume('index' if number else 'catch', 'composition_input_sample_sizes', size_key + f' * {multiplier}',
           'Native values and post-read multiplier retained in per-composition notes; estimated D-M overdispersion is not a supplied ESS.',
           survey='' if number==0 else label, fleet=label if number==0 else '', source=native+'; data/2024/run_assessment.R')

for row in csv.DictReader((cache/'report_historical_outputs_raw.csv').open()):
    metric = row['metric']
    outputs.append(dict(assessment_id=assessment, type={'numbers_at_age':'population','ssb':'biomass','recruitment':'recruitment'}[metric],
                        measure='SSB' if metric=='ssb' else metric, year=row['year'], age=row['age'],
                        age_group='10+' if row['age']=='10' else '', value=row['value'], lwr=row['lower'], upr=row['upper'],
                        unit='million fish' if row['unit']=='million_fish' else 'thousand t', source_type='official_table',
                        source_reference=report+'; Table '+row['table'],
                        notes='Official historical estimate. Published 95% interval retained where available; printed CV not converted to SE. SSB is female; recruitment age 1; N terminal age is 10+.'))
for row in csv.DictReader((cache/'report_age3plus_biomass.csv').open(encoding='utf-8')):
    outputs.append(dict(assessment_id=assessment, type='biomass', measure='total_biomass',
                        year=row['year'], age_group='3+', value=row['value'], unit='thousand t',
                        source_type='official_table', source_reference=report+'; Table 1.23, 2024 assessment columns',
                        notes='Beginning-year biomass of ages 3–10+, not all-age biomass. Historical official-run estimate; no uncertainty published in this table. Harvest rate is not fishing mortality.'))
assume('assessment', 'accepted_model', 'Model 23d: 2024 final', 'Adopted by final December 2024 SSC, page 40; 2025 catch-only rollover.')
assume('population', 'modeled_years', '1970–2024', source=native)
assume('population', 'ages', '1–10; plus group 10+', source=native)
assume('population', 'recruitment_age', '1', source=native)
assume('biology', 'spawning_time', '0.21', 'Survival to spawning uses exp(-0.21*Z); distinct from winter acoustic timing 0.209.', source=code)
assume('biology', 'female_fraction', '0.5', source=code)
assume('M', 'treatment', 'Fixed age-specific external vector', 'natMscalar fixed at 1. Summary scalar 0.3 describes older-age scaling, not all ages.', source=code)
assume('recruitment', 'process', 'Lognormal deviations with fixed sigmaR=1.3', 'Final report page 16 and native parameter map agree.')
assume('catch', 'representation', 'Total biomass plus number composition', 'Ages 1–2 accumulated in first fitted composition bin.', fleet='Combined fishery')
assume('catch', 'observation_likelihood', 'Lognormal total catch with log SD 0.05; D-M age composition', source=code)
assume('q', 'Shelikof_covariate', 'Latent AR1 environmental covariate with observed timing mismatch', '40 supplied Ecov observations represented in canonical inputs; physical units unresolved.', survey='Shelikof winter acoustic', source=code)
assume('index', 'disabled_streams', 'Shelikof age-1/age-2 indices and all length compositions', 'Zero log SDs disable young-age indices; zero sample sizes and/or unused likelihoods disable lengths.', source=code)
assume('F', 'selectivity_and_penalties', 'Double-logistic fishery selectivity normalized at age 7; annual ascending-limb parameters',
       'log slope and inflection deviations have first-difference normal penalties with supplied rwlk_sd and 4*rwlk_sd, respectively. Descending-limb deviations are fixed at zero by prepare_map. Annual F is exp(mean_log_F + dev_log_F); mean_log_F is fixed. Broad selectivity priors remain in the objective.',
       fleet='Combined fishery', source=code+'; R/tmb_fns.R: prepare_map')
assume('F', 'selectivity_increment_sd', '0.05 for log ascending slope; 0.2 for ascending inflection',
       'All 54 supplied rwlk_sd values equal 0.05, for transitions 1970->1971 through 2023->2024. Inflection penalty multiplies these SDs by 4. Descending deviations are fixed at zero.',
       fleet='Combined fishery', source=code+'; '+native)
assume('q', 'catchability_increment_sd', str(vector('q3_rwlk_sd')),
       '54 native SDs in transition order 1970->1971 through 2023->2024; used for first differences in log_q3_dev. Values are supplied, not estimated process variances.',
       survey='ADF&G crab/groundfish trawl', source=code+'; '+native)
for label, shape, details in [
    ('Shelikof winter acoustic', 'Descending logistic, normalized at age 3; ages 1 and 2 zero', 'Descending log slope and inflection estimated; ascending parameters do not enter this implemented selectivity.'),
    ('NMFS bottom trawl', 'Double logistic, normalized at age 10', 'Ascending log slope and inflection estimated; descending log slope and inflection fixed by prepare_map.'),
    ('ADF&G crab/groundfish trawl', 'Ascending logistic, normalized at age 10', 'Ascending log slope and inflection estimated.'),
    ('Summer acoustic', 'Double logistic, normalized at age 1', 'Ascending log slope and inflection fixed; descending log slope and inflection estimated.')]:
    assume('index', 'selectivity', shape, details+' Selectivity is time invariant.', survey=label,
           source=code+'; R/tmb_fns.R: prepare_map')
assume('N', 'initial_state_treatment', 'Initial ages 2–10 tied to first-year recruitment and fixed M; extra initial-age deviations fixed at zero',
       'Implementation: initN[0]=exp(mean_log_recruit+dev_log_recruit[0]-M[0]); initN[j]=initN[j-1]*exp(-M[j+1]) for j=1..8; final age divided by 1-exp(-M[9]). These zero-based indices are preserved exactly. Subsequent cohort survival uses total mortality, without additional survival deviations.',
       source=code+'; R/tmb_fns.R: prepare_par and prepare_map')
assume('q', 'catchability_structure', 'Constant baseline plus latent environmental effect on log q',
       'log_q1=log_q1_mean+Ecov_beta*Ecov_exp; log_q1_dev fixed at zero. Ecov_exp is integrated as a random effect; annual catchability is not an independent q random walk in this official run.',
       survey='Shelikof winter acoustic', source=code+'; R/tmb_fns.R: prepare_pk_input and prepare_map')
assume('q', 'catchability_structure', 'Constant estimated log catchability with normal prior',
       'log_q2_dev fixed at zero; log_q2_mean prior mean log(0.85), SD 0.1.',
       survey='NMFS bottom trawl', source=code+'; R/tmb_fns.R: prepare_map')
assume('q', 'catchability_structure', 'Annual log catchability deviations with first-difference normal penalties',
       'log_q3_mean fixed; log_q3_dev estimated with supplied q3_rwlk_sd. These deviations are fitted by penalized likelihood, not declared integrated random effects in prepare_pk_input.',
       survey='ADF&G crab/groundfish trawl', source=code+'; R/tmb_fns.R: prepare_pk_input and prepare_map')
assume('q', 'catchability_structure', 'Constant estimated catchability exp(log_q6)',
       'No annual q6 deviations.', survey='Summer acoustic', source=code+'; R/tmb_fns.R: prepare_map')
age_transition = [matrix_row('age_trans', i) for i in range(1, 11)]
assume('biology', 'age_error_matrix', str(age_transition),
       'Native constant 10x10 age_trans matrix, recorded row by row. Rows are true ages 1–10, columns observed ages 1–10; age 10 is the terminal group. Predictions multiply a true-age row composition by this matrix before fitted-bin accumulation. Applies to fishery and all four active survey age compositions.', source=code+'; '+native)

stock = dict(stock_id=stock_id, charbonneau_id='AFSC_GOA_Gadus_chalcogrammus', authority='NOAA-AFSC',
             authority_stock_id='GOA pollock W/C/WYK', scientific_name='Gadus chalcogrammus',
             common_name='Gulf of Alaska walleye pollock', area='Western/Central/West Yakutat, west of 140 W',
             region='Alaska', ocean='Northeast Pacific', notes='Age-structured Tier 3 stock; excludes separate Southeast Outside Tier 5 assessment.')
record = dict(assessment_id=assessment, stock_id=stock_id, assessment_year=2024, terminal_year=2024,
              estimate_terminal_year=2024, assessment_type='annual', model_family='Statistical catch-at-age (TMB)',
              model_version='23d', framework_year=2024, is_current='TRUE', is_applied='TRUE', assessment_url=report,
              data_url=native, repository_url=repo, assumptions_status='partial', inputs_status='partial', outputs_status='partial',
              notes='Official Model 23d; 2025 catch-only rollover verified after separating Southeast Outside allowances. All four active biomass/composition surveys, supplied annual weights, maturity and fixed M represented. Age-error matrix and supplied composition sample sizes preserved; remaining statistical assumptions pending; environmental observations preserved on native scale; F-at-age and further outputs missing. See source_reviews/afsc_pollock_goa.md.')
for filename, new, key in [('stocks.csv',[stock],'stock_id'), ('assessments.csv',[record],'assessment_id'),
                          ('inputs.csv',inputs,'assessment_id'), ('outputs.csv',outputs,'assessment_id'), ('assumptions.csv',assumptions,'assessment_id')]:
    path = root/'database'/filename
    content = path.read_bytes().decode('utf-8-sig')
    reader = csv.DictReader(io.StringIO(content))
    fields, old = reader.fieldnames, list(reader)
    lines = content.splitlines(keepends=True)
    assert len(lines)==len(old)+1
    preserved = [lines[0]] + [line for line,row in zip(lines[1:],old) if row[key]!=new[0][key]]
    with path.open('w',newline='',encoding='utf-8') as f:
        f.writelines(preserved)
        csv.DictWriter(f,fields).writerows({field:r.get(field,'') for field in fields} for r in new)
print(f'Imported {len(inputs)} inputs, {len(outputs)} outputs, {len(assumptions)} assumptions; statuses partial.')

