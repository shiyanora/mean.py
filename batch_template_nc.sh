#!/bin/bash
# execute ensemble runs of parcel model

# define location of parcel model
base_name=YOURDIRECTORY
#define your type of system (max, linux)
system_type='linux'

# it is necessary to change the sed call because mac os does not support the standard call
if [ "$system_type" == "mac" ]
then
   sed_call='sed -i '' -e'
else
   sed_call='sed -i'
fi

# specify total number of ensemble members
ens_tot=10

# declare some variables which need to be kept constant
IN_name='dep' #'dep' #'imm'
time_entr='0.0'
time_end='610.0'

#                         N0          N1         N2        N3       N4       N5       | f1        f2       f3=N2    f4        | d1      d2=N2    d3       | r1        r2       r3=N2    r4       | h1        h2        h3        h4
declare -a rh_value_arr=( '0.95'      '0.95'     '0.95'    '0.95'   '0.95'   '0.95'     '0.95'    '0.95'            '0.95'     '0.95'            '0.95'     '0.85'    '0.90'            '1.00'     '0.95'    '0.95'    '0.95'    '0.95' )
declare -a d_value_arr=(  '1.0E-4'    '1.0E-4'   '1.0E-4'  '1.0E-4' '1.0E-4' '1.0E-4'   '1.0E-4'  '1.0E-4'          '1.0E-4'   '1.0E-5'          '1.0E-3'   '1.0E-4'  '1.0E-4'          '1.0E-4'   '1.0E-4'  '1.0E-4'  '1.0E-4'  '1.0E-4' )
declare -a nIN_arr=(      '0.00001E6' '0.0001E6' '0.001E6' '0.01E6' '0.1E6'  '1.0E6'    '0.01E6'  '0.01E6'          '0.01E6'   '0.01E6'          '0.01E6'   '0.01E6'  '0.01E6'          '0.01E6'   '0.01E6'  '0.01E6'  '0.01E6'  '0.01E6' )
declare -a f_arr=(        '0.2'       '0.2'      '0.2'     '0.2'    '0.2'    '0.2'      '0.0'     '0.1'             '0.4'      '0.2'             '0.2'      '0.2'     '0.2'             '0.2'      '0.2'     '0.2'     '0.2'     '0.2'  )
declare -a hr_value_arr=( '0.0'       '0.0'      '0.0'     '0.0'    '0.0'    '0.0'      '0.0'     '0.0'             '0.0'      '0.0'             '0.0'      '0.0'     '0.0'             '0.0'      '0.000976119402985' '0.00976119402985' '-0.00097611940298' '-0.00976119402985' )
declare -a hr_name_arr=(  '0.0'       '0.0'      '0.0'     '0.0'    '0.0'    '0.0'      '0.0'     '0.0'             '0.0'      '0.0'             '0.0'      '0.0'     '0.0'             '0.0'      '0.1'     '1.0'     '-0.1'    '-1.0' )

declare -a base_arr=( 'TURB' 'HOM' )

for (( j=0; j<1; j=j+1 ));
do

   base=${base_arr[$j]}

   for (( i=0; i<3; i=i+1 ));       # change i-loop to change number of configs 
   do

      for (( k=1; k<ens_tot+1; k=k+1 ));
      do

#        turn the parcel model into batch mode
         ${sed_call} 's/switch_batch_mode =.*/switch_batch_mode = .TRUE.,/g' ${base_name}/input.nml

         echo 'ensemble member: '$k' of '${ens_tot}
#        the file name is automatically extended by the ensemble number
         file_ending=${base}'_N_'${nIN_arr[$i]}'_f_'${f_arr[$i]}'_diss_'${d_value_arr[$i]}'_rh_'${rh_value_arr[$i]}'_IN_'${IN_name}'_hr_'${hr_name_arr[$i]}'_entr_'${time_entr}
         file_ending=${file_ending}'_ens_'${k}
         echo 'file name:       '${file_ending}

         ${sed_call} 's/file_ending =.*/file_ending = "'${file_ending}'",/g' ${base_name}/input.nml
         ${sed_call} 's/n_ensemble =.*/n_ensemble = '${k}',/g' ${base_name}/input.nml

         ${sed_call} 's/time_entr =.*/time_entr = '${time_entr}',/g' ${base_name}/input.nml
         ${sed_call} 's/time_end =.*/time_end = '${time_end}',/g' ${base_name}/input.nml

         ${sed_call} 's/n_IN =.*/n_IN = '${nIN_arr[$i]}',/g' ${base_name}/input.nml
         ${sed_call} 's/diss_rate_LEM =.*/diss_rate_LEM = '${d_value_arr[$i]}',/g' ${base_name}/input.nml
         ${sed_call} 's/fraction_air_entrainment =.*/fraction_air_entrainment = '${f_arr[$i]}',/g' ${base_name}/input.nml
         ${sed_call} 's/rh_entrainment =.*/rh_entrainment = '${rh_value_arr[$i]}',/g' ${base_name}/input.nml
         ${sed_call} 's/heating_rate_parcel =.*/heating_rate_parcel = '${hr_value_arr[$i]}',/g' ${base_name}/input.nml

         if [ "$IN_name" == "dep" ]
         then
            ${sed_call} 's/type_aero =.*/type_aero = 3,/g' ${base_name}/input.nml
         elif [ "$IN_name" == "imm" ]
         then
            ${sed_call} 's/type_aero =.*/type_aero = 2,/g' ${base_name}/input.nml
         fi

         if [ "$base" == "TURB" ]
         then
            ${sed_call} 's/switch_mol_diff_LEM =.*/switch_mol_diff_LEM = .TRUE.,/g' ${base_name}/input.nml
            ${sed_call} 's/switch_turbulence_LEM =.*/switch_turbulence_LEM = .TRUE.,/g' ${base_name}/input.nml
            ${sed_call} 's/switch_sedimentation_LEM =.*/switch_sedimentation_LEM = .TRUE.,/g' ${base_name}/input.nml
            ${sed_call} 's/switch_supersat_fluct_LEM =.*/switch_supersat_fluct_LEM = .TRUE.,/g' ${base_name}/input.nml
         elif [ "$base" == "HOM" ]
         then
            ${sed_call} 's/switch_mol_diff_LEM =.*/switch_mol_diff_LEM = .FALSE.,/g' ${base_name}/input.nml
            ${sed_call} 's/switch_turbulence_LEM =.*/switch_turbulence_LEM = .FALSE.,/g' ${base_name}/input.nml
            ${sed_call} 's/switch_sedimentation_LEM =.*/switch_sedimentation_LEM = .FALSE.,/g' ${base_name}/input.nml
            ${sed_call} 's/switch_supersat_fluct_LEM =.*/switch_supersat_fluct_LEM = .FALSE.,/g' ${base_name}/input.nml
         fi

         make -f particle.make run
         ncl ${base_name}/time_series_2_nc.ncl
         ncl ${base_name}/spectra_2_nc.ncl
         ncl ${base_name}/1D_LEM_2_nc.ncl
         
      done

   done

done

echo All done
