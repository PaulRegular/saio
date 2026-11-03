"""Import published 2026 North Sea herring tables; retain unresolved source gaps."""
import csv
import io
import sys
from pathlib import Path

root=Path(sys.argv[1])/'analysis/comp_assessments'
cache=root/'source_cache/ices_herring_north_sea_2026'
assessment='ices_herring_north_sea_2026'
stock_id='ices_herring_north_sea'
report='https://doi.org/10.17895/ices.pub.31424315'
repository='https://github.com/ices-advice/2026_her.27.3a47d'
inputs,outputs,assumptions=[],[],[]
raw=list(csv.DictReader((cache/'report_tables_raw.csv').open(encoding='utf-8')))
summary=list(csv.DictReader((cache/'report_summary_raw.csv').open(encoding='utf-8')))

def assumption(component,setting,value,notes='',survey='',fleet='',reference='Table 2.6.2.7'):
    assumptions.append(dict(assessment_id=assessment,component=component,setting=setting,value=value,
                            notes=notes,survey=survey,fleet=fleet,source_reference=report+'; '+reference))

biology={2:('maturity','maturity_at_age','proportion','proportion'),
         4:('weight','weight_at_age','kg_per_fish','kg'),
         5:('catch_weight','weight_at_age','kg_per_fish','kg'),
         6:('catch','numbers_at_age','numbers','thousand fish')}
surveys={7:('HERAS',None),8:('IBTS0',0),9:('IBTS-Q1',1),10:('IBTS-Q3',None)}
larvae={11:('LAI-SNS','Downs',['16–31 Dec','01–15 Jan','16–31 Jan']),
        12:('LAI-CNS','Banks',['01–15 Sep','16–30 Sep','01–15 Oct','16–31 Oct']),
        13:('LAI-BUN','Buchan',['01–15 Sep','16–30 Sep']),
        14:('LAI-ORSH','Orkney/Shetland',['01–15 Sep','16–30 Sep'])}
for r in raw:
    table=r['table']; col=r['native_column']; year=int(r['year'])
    if r['value']=='.' or float(r['value'])<0:
        continue
    value=float(r['value'])
    age=col.rstrip('+'); notes='Age classes are winter rings; age 8 represents 8+.'
    base=dict(assessment_id=assessment,year=year,value=value,source_type='official_table',
              source_reference=report+'; Table '+table)
    if table.startswith('2.6.2.'):
        kind,measure,unit=('population','numbers_at_age','thousand fish') if table.endswith('.3') else ('mortality','fishing_mortality_at_age','per year')
        outputs.append(dict(base,type=kind,measure=measure,unit=unit,age=age,
                            fleet='Combined catch' if kind=='mortality' else '',notes=notes+' Reported 2026 states use partial-year survey information; catch ends in 2025.'))
        continue
    n=int(table.rsplit('.',1)[1])
    row=dict(base,year_basis='calendar_year',age=age,notes=notes)
    if n in biology:
        kind,measure,basis,unit=biology[n]
        row.update(type=kind,measure=measure,basis=basis,unit=unit,
                   fleet='Combined catch' if n in (5,6) else '')
        if n==6:
            row['notes']+=' Table caption incorrectly says catch weight; accompanying text identifies catch numbers. Closure observations 1978–1979 are absent.'
    elif n in surveys:
        survey,fixed_age=surveys[n]
        row.update(type='index',measure='numbers_at_age',basis='numbers',survey=survey,
                   age=fixed_age if fixed_age is not None else age,unit='native survey index (unit unresolved)',
                   notes=notes+' Model sampling fraction remains unresolved; no timing invented.')
    elif n in larvae:
        if year==1972:
            continue
        survey,region,windows=larvae[n]
        row.update(type='index',measure='larval_abundance_index',basis='numbers',survey=survey,
                   region=region,season=windows[int(col)],age='',sampling_time=0.67,
                   unit='native LAI index (unit unresolved)',
                   notes='Partial spawning-component index; columns are survey time windows, not fish ages. Model timing 0.67 from pinned data_construct_input.R differs from sampling-window dates. Published zeros retained; likelihood handling unresolved. 1972 retained only in source cache pending inclusion-rule verification.')
    else:
        # M remains staged until the +0.02 adjustment in the reported table is verified.
        continue
    inputs.append(row)

for r in summary:
    for prefix,kind,measure,unit in [('Rec','recruitment','recruitment','thousand fish'),
                                   ('TSB','biomass','total_biomass','t'),('SSB','biomass','SSB','t'),
                                   ('Catch','catch','total_biomass','t'),('Fbar','mortality','Fbar','per year')]:
        outputs.append(dict(assessment_id=assessment,type=kind,measure=measure,year=r['year'],
                            value=r[prefix],lwr=r[prefix+'_lo'],upr=r[prefix+'_hi'],unit=unit,
                            age_group='2–6 winter rings' if prefix=='Fbar' else '',
                            fleet='Combined catch' if prefix=='Catch' else '',source_type='official_table',
                            source_reference=report+'; Table 2.6.2.6',
                            notes='Published estimate and lower/upper interval retained without recomputation. Recruitment is age 0 winter rings. 2026 is the partial-year assessment state, not an advice forecast.'))

assumption('population','modeled_years','1947–2026')
assumption('population','ages','0–8 winter rings; plus group 8+')
assumption('population','recruitment_age','0 winter rings')
assumption('assessment','accepted_run','NSAS_HAWG2026_sf','Single-fleet historical assessment; multifleet model supports fleet forecasts.',reference='Section 2.6; pinned model_sf.R')
assumption('N','variance_sharing','Recruitment separate; ages 1–8 share variance')
assumption('F','state_sharing','Ages 0–6 separate; ages 7–8 share one state',fleet='Combined catch')
assumption('F','innovation_variance_sharing','Ages 0–1 / 2–5 / 6–8',fleet='Combined catch')
assumption('F','age_correlation','AR1','Pinned single-fleet configuration sets cor.F=2.',fleet='Combined catch',reference='utilities_model_config.R: config_sf_IBPNSherring2021')
assumption('catch','excluded_years','1978–1979','Closure catch observations deliberately set to NA.',fleet='Combined catch',reference='data_construct_input.R; Table 2.6.1.6')
assumption('M','structure','Externally supplied SMS-2023 age-year mortality plus 0.02','Not internally estimated. Report M table remains cached but omitted from canonical inputs until offset inclusion is verified.',reference='Section 2.4.3; model_sf.R')
assumption('biology','terminal_year_inputs','unknown','Published annual biology tables end in 2025; official 2026 construction not yet verified.')
assumption('biology','spawning_mortality_fractions','unknown','fprop.txt and mprop.txt are cited but current native files not recovered.')
assumption('population','initial_state_treatment','unknown','Requires verified FLSAM implementation or benchmark documentation.')
for survey in ['HERAS','IBTS0','IBTS-Q1','IBTS-Q3']+[v[0] for v in larvae.values()]:
    assumption('index','observation_correlation','AR1 across ages' if survey=='IBTS-Q3' else 'Independent',survey=survey)
    assumption('index','sampling_time','0.67' if survey.startswith('LAI') else 'unknown',survey=survey,
               reference='data_construct_input.R' if survey.startswith('LAI') else 'fleet.txt unavailable')
    assumption('index','units','unknown','Published native values preserved; numerical scale not silently converted.',survey=survey)
assumption('q','sharing','HERAS ages 1–2 / 3–8; Q1 one q; IBTS0 one q; Q3 age-specific; all four LAI share q')
assumption('q','power_law','None configured')
assumption('index','LAI_structure','Partial spawning-component indices with three logP variance parameters','Time-window dimensions retained; detailed logP process interpretation unresolved.')

stock=dict(stock_id=stock_id,charbonneau_id='ICES-HAWG_ NS-IV 3a,7d_Clupea_harengus',authority='ICES',
           authority_stock_id='her.27.3a47d',scientific_name='Clupea harengus',common_name='North Sea autumn-spawning herring',
           area='Subarea 4 and divisions 3.a and 7.d',region='North Sea, Skagerrak/Kattegat and eastern English Channel',
           ocean='Northeast Atlantic',notes='Winter-ring age convention and regional larval spawning-component indices retained.')
record=dict(assessment_id=assessment,stock_id=stock_id,assessment_year=2026,terminal_year=2026,
            estimate_terminal_year=2026,assessment_type='assessment_update',model_family='SAM',
            model_version='FLSAM; version unresolved',is_current='TRUE',is_applied='TRUE',framework_year=2021,
            assessment_url=report,repository_url=repository,inputs_status='partial',outputs_status='partial',
            assumptions_status='partial',notes='Report-native catch, four age/recruitment indices, four partial larval index streams, maturity, weights, N/F and summary intervals represented. M offset inclusion, terminal biology, spawning fractions, non-LAI timing, index units, 1972 LAI inclusion and initial-state semantics unresolved. Native current fit not recovered. See source_reviews/ices_herring_north_sea.md.')
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
print(f'Imported {len(inputs)} inputs, {len(outputs)} outputs, {len(assumptions)} assumptions; all statuses partial.')
