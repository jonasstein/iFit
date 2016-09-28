function [options, sav] = sqw_phonons_get_forces(options, decl, calc)

  target = options.target;
  
  if ismac,      precmd = 'DYLD_LIBRARY_PATH= ;';
  elseif isunix, precmd = 'LD_LIBRARY_PATH= ; '; 
  else           precmd = ''; end

  % init calculator
  if strcmpi(options.calculator, 'GPAW')
    % GPAW Bug: gpaw.aseinterface.GPAW does not support pickle export for 'input_parameters'
    sav = sprintf('ph.calc=None\natoms.calc=None\nph.atoms.calc=None\n');
  else
    sav = '';
  end

  % start python --------------------------
  options.script_get_forces = [ ...
    '# python script built by ifit.mccode.org/Models.html sqw_phonons\n', ...
    '# on ' datestr(now) '\n' ...
    '# E. Farhi, Y. Debab and P. Willendrup, J. Neut. Res., 17 (2013) 5\n', ...
    '# S. R. Bahn and K. W. Jacobsen, Comput. Sci. Eng., Vol. 4, 56-66, 2002.\n', ...
    '#\n', ...
    '# Computes the Hellmann-Feynman forces and stores an ase.phonon.Phonons object in a pickle\n', ...
    '# Launch with: python sqw_phonons_build.py (and wait...)\n', ...
    'from ase.phonons import Phonons\n', ...
    'import pickle\n', ...
    'import numpy\n', ...
    'import scipy.io as sio\n', ...
    'from os import chdir\n' ...
    'chdir("' target '")\n' ...
    '# Get the crystal and calculator\n', ...
    'fid = open("' fullfile(target, 'atoms.pkl') '","rb")\n' ...
    'atoms = pickle.load(fid)\n' ...
    'fid.close()\n' ...
    decl '\n', ...
    calc '\n', ...
    'atoms.set_calculator(calc)\n' ...
    '# Phonon calculator\n', ...
    sprintf('ph = Phonons(atoms, calc, supercell=(%i, %i, %i), delta=0.05)\n',options.supercell), ...
    'print "Computing Forces: %%i atoms to move, %%i displacements\\n" %% (len(ph.indices), (6*len(ph.indices)))\n', ...
    'ph.run()\n', ...
    '# Read forces and assemble the dynamical matrix\n', ...
    'ph.read(acoustic=True, cutoff=None) # cutoff in Angs\n', ...
    '# save FORCES and phonon object as a pickle\n', ...
    'sio.savemat("' fullfile(target, 'FORCES.mat') '", { "FORCES":ph.get_force_constant(), "delta":ph.delta, "celldisp":atoms.get_celldisp() })\n', ...
    'fid = open("' fullfile(target, 'phonon.pkl') '","wb")\n' , ...
    'calc = ph.calc\n', ...
    sav, ...
    'pickle.dump(ph, fid)\n', ...
    'fid.close()\n', ...
    '# additional information\n', ...
    'atoms.set_calculator(calc) # reset calculator as we may have cleaned it for the pickle\n', ...
    'print "Computing properties\\n"\n', ...
    'from ase.vibrations import Vibrations\n', ...
    'try:    magnetic_moment    = atoms.get_magnetic_moment()\n', ...
    'except: magnetic_moment    = None\n', ...
    'try:    kinetic_energy     = atoms.get_kinetic_energy()\n', ... 
    'except: kinetic_energy     = None\n', ...
    'try:    potential_energy   = atoms.get_potential_energy()\n',... 
    'except: potential_energy   = None\n', ...
    'try:    stress             = atoms.get_stress()\n', ... 
    'except: stress             = None\n', ...
    'try:    total_energy       = atoms.get_total_energy()\n', ...
    'except: total_energy       = None\n', ...
    'try:    angular_momentum   = atoms.get_angular_momentum()\n', ... '
    'except: angular_momentum   = None\n', ...
    'try:    charges            = atoms.get_charges()\n', ...
    'except: charges            = None\n', ...
    'try:    dipole_moment      = atoms.get_dipole_moment()\n', ... 
    'except: dipole_moment      = None\n', ...
    'try:    momenta            = atoms.get_momenta()\n', ... 
    'except: momenta            = None\n', ...
    'try:    moments_of_inertia = atoms.get_moments_of_inertia()\n', ...
    'except: moments_of_inertia = None\n', ...
    'try:    center_of_mass     = atoms.get_center_of_mass()\n', ...
    'except: center_of_mass     = None\n', ...
    '# get the previous properties from the init phase\n' ...
    'try:\n' ...
    '  fid = open("' fullfile(target, 'properties.pkl') '","rb")\n' ...
    '  properties = pickle.load(fid)\n' ...
    '  fid.close()\n' ...
    'except:\n' ...
    '  properties = dict()\n' ...
    'try:\n' ...
    '  vib = Vibrations(atoms)\n', ...
    '  print "Computing molecular vibrations\\n"\n', ...
    '  vib.run()\n', ...
    '  vib.summary()\n' ...
    '  properties["zero_point_energy"] = vib.get_zero_point_energy()\n' ...
    '  properties["vibrational_energies"]=vib.get_energies()\n' ...
    'except:\n' ...
    '  pass\n' ...
    'properties["magnetic_moment"]  = magnetic_moment\n' ...
    'properties["kinetic_energy"]   = kinetic_energy\n' ...
    'properties["potential_energy"] = potential_energy\n' ...
    'properties["stress"]           = stress\n' ...
    'properties["momenta"]          = momenta\n' ...
    'properties["total_energy"]     = total_energy\n' ...
    'properties["angular_momentum"] = angular_momentum\n' ...
    'properties["charges"]          = charges\n' ...
    'properties["dipole_moment"]    = dipole_moment\n' ...
    'properties["moments_of_inertia"]= moments_of_inertia\n' ...
    'properties["center_of_mass"]   = center_of_mass\n' ...
    '# remove None values\n' ...
    'properties = {k: v for k, v in properties.items() if v is not None}\n' ...
    '# export properties as pickle\n' ...
    'fid = open("' fullfile(target, 'properties.pkl') '","wb")\n' ...
    'pickle.dump(properties, fid)\n' ...
    'fid.close()\n' ...
    '# export properties as MAT\n' ...
    'sio.savemat("' fullfile(target, 'properties.mat') '", properties)\n' ...
  ];
  % end   python --------------------------

  % write the script in the target directory
  fid = fopen(fullfile(target,'sqw_phonons_forces.py'),'w');
  fprintf(fid, options.script_get_forces);
  fclose(fid);
  
  % call python script with calculator
  disp([ mfilename ': computing Hellmann-Feynman forces and creating Phonon/ASE model.' ]);
  options.status = 'Starting computation. Script is <a href="sqw_phonons_forces.py">sqw_phonons_forces.py</a>';
  sqw_phonons_htmlreport('', 'status', options);
  
  result = '';
  try
    if strcmpi(options.calculator, 'GPAW') && isfield(options,'mpi') ...
      && ~isempty(options.mpi) && options.mpi > 1
      [st, result] = system([ precmd status.mpirun ' -np ' num2str(options.mpi) ' '  status.gpaw ' ' fullfile(target,'sqw_phonons_forces.py') ]);
    else
      [st, result] = system([ precmd 'python ' fullfile(target,'sqw_phonons_forces.py') ]);
    end
    disp(result)
  catch
    disp(result)
    sqw_phonons_error([ mfilename ': failed calling ASE with script ' ...
      fullfile(target,'sqw_phonons_build.py') ], options);
    options = [];
    return
  end
