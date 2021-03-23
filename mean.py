### Calculate the mean of all ensemble runs and write it in a file. ###

import os
import numpy as num
import netCDF4 as nc


# Define function 'find': Find string in files and append to list
def find(files, string, list):
    for file in files:
        if string in file and '.dat.nc' in file:
            list.append(file)
        else:
            pass


# Ask for directory and get filelist:                          
c = True
while c:
    dir_in = input("Type directory or type 'here': ")
    if dir_in == 'here':
        dir = os.getcwd()
        filelist = os.listdir(dir)
        c = False
    else:
        dir = dir_in
        try:
            filelist = os.listdir(dir)
            c = False
            break
        except:
            pass
        print("You either typed 'here' incorrectly or the given directory does not exist. Try again.")

print('Success! Reading files in', dir)


# Ask for data and check if data is available:
while True:
    data_types = {1: 'time_series', 2: 'spectra', 3: '1D_LEM'}

    for d in data_types.keys():
        print(d, " ", data_types[d])

    nb = input('Which data do you want to average? ')

    while True:
        if int(nb) in data_types.keys():
            break
        else:
            nb = input('Number out of range. Try again: ')

    # Find string fn in filelist and append to lfn
    fn = data_types[int(nb)]

    lfn = []
    find(filelist, fn, lfn)
    n_files = len(lfn)

    if n_files == 0:
        print('There are no', fn, 'data files in this directory.')
    else:
        break


# Calculate number of configurations and number of ensembles:
lfn_1 = []
find(lfn, 'ens_1.dat.nc', lfn_1)
n_conf = len(lfn_1)
conf = num.arange(n_conf) + 1
n_ens = n_files / n_conf


# Print some numbers for checking purposes:
print('Number of',fn,'files:', n_files)
print('Number of configurations:', n_conf)
print('Number of ensemble runs:', int(n_ens))


# Create array with strings of the different configurations:
strings = []
for s in lfn_1:
    strings.append(s[len(fn):(len(s)-12)])


# Configuration loop:
for n in conf:
    lfn_temp = []
    find(lfn, strings[n-1], lfn_temp)
    data = nc.Dataset(dir + "/" + lfn_temp[0])
    var_sum = dict()
    var_mean = dict()

    # Initialiaze sum and mean array:
    for i in data.variables:
        var_sum.update({i: num.zeros(num.shape(data.variables[i][:]))})
        var_mean.update({i: num.zeros(num.shape(data.variables[i][:]))})

    # Ensemble loop:
    for m in lfn_temp:
        data = nc.Dataset(dir + "/" + m, 'r')
        keys = data.variables.keys()

        for j in keys:
            var_sum[j] += data.variables[j][:]

    # Calculate ensemble mean:
    for l in keys:
        var_mean[l] = var_sum[l] / n_ens

    # Print ensemble sum and mean of time for the first configuration:
    if n == 1:
        print('Printing first and last three values of time sum and time mean of the first config. for checking purposes: ')
        print(var_sum['TIME'][0:3], var_sum['TIME'][-3:])
        print(var_mean['TIME'][0:3], var_mean['TIME'][-3:])


    # Create output file:
    try:
        out_dir = os.mkdir(dir + "/mean_output/")
    except:
        out_dir = dir + "/mean_output/"
    new_file = (out_dir + fn + strings[n-1] + 'mean.nc')
    print('Creating', new_file)
    new_data = nc.Dataset(new_file, "w", format="NETCDF3_CLASSIC")

    # Copy dimensions:
    for dname, the_dim in data.dimensions.items():
        print
        dname, len(the_dim)
        new_data.createDimension(dname, len(the_dim) if not the_dim.isunlimited() else None)

    # Copy variables:
    for v_name, varin in data.variables.items():
        outVar = new_data.createVariable(v_name, varin.datatype, varin.dimensions)
        print
        varin.datatype

        # Copy variable attributes:
        outVar.setncatts({k: varin.getncattr(k) for k in varin.ncattrs()})
        outVar[:] = varin[:]

    # Write mean values in output file:
    for y in keys:
        new_data.variables[y][:] = var_mean[y][:]

    # Close the output file:
    new_data.close()
