function  [s,parameters,fields] = Sqw_parameters(s, fields)
% [s,p,fields] = Sqw_parameters(s,type): search for parameter values in a Sqw/Sab data set
%
% input:
%   s: any iData object, including S(q,w) and S(alpha,beta) ones.
%   fields: an optional list of items to search (cellstr)
% output:
%   s: updated object with found parameters
%   p: parameters as a structure, also stored into s.parameters
%
% (c) E.Farhi, ILL. License: EUPL.

% extract a list of parameters
parameters = [];

if nargin == 0, return; end
if ~isa(s, 'iData'), s=iData(s); end
if nargin < 2, fields=[]; end
if isempty(fields) % default: search all parameters and assemble them
  [s,parameters1,fields1] = Sqw_parameters(s, 'sqw');
  [s,parameters2,fields2] = Sqw_parameters(s, 'sab');
  if isstruct(parameters1) && isstruct(parameters2)
    % merge the structures/cells handling duplicated fields
    f = [ fieldnames(parameters1) ; fieldnames(parameters2) ];
    [pnames,index] = unique(f);
    pairs = [fieldnames(parameters1), struct2cell(parameters1); ...
             fieldnames(parameters2), struct2cell(parameters2)].';
    parameters = struct(pairs{:,index});
    fields = [ fields1 fields2 ];
    fields = fields(index);
    s.parameters=parameters(1);
  end
  if nargout == 0 & length(inputname(1))
    assignin('caller',inputname(1),s);
  end
  return
end

if ischar(fields) && strcmpi(fields, 'sqw')
  % a list of parameter names, followed by comments
  % aliases can be specified when a parameter is given as a cellstr, with 
  % consecutive possibilities.
  fields={ ...
      'density [g/cm3] Material density'	...
     {'weight [g/mol] Material molar weight'	'mass' 'AWR'}...
      'T_m [K] Melting T'	...
      'T_b [K] Boiling T'	'MD_at Number of atoms in the molecular dynamics simulation'	...
      'MD_box [Angs] Simulation box size'	...
     {'Temperature [K]' 'T' 'TEMP'}	...
      'dT [K] T accuracy' ...
      'MD_duration [ps] Molecular dynamics duration'	'D [cm^2/s] Diffusion coefficient' ...
      'sigma_coh [barn] Coherent scattering neutron cross section' ...
      'sigma_inc [barn] Incoherent scattering neutron cross section'	...
      'sigma_abs [barn] Absorption neutron cross section'	...
      'c_sound [m/s] Sound velocity' ...
      'At_number Atomic number Z' ...
      'Pressure [bar] Material pressure' ...
      'v_sound [m/s] Sound velocity' ...
      'Material Material description' ...
      'Phase Material state' ...
      'Scattering process' ...
     {'Wavelength [Angs] neutron wavelength' 'lambda' 'Lambda' }...
      'Instrument neutron spectrometer used for measurement' ...
      'Comment' ...
      'C_s [J/mol/K]   heat capacity' ...
      'Sigma [N/m] surface tension' ...
      'Eta [Pa s] viscosity' ...
      'L [J/mol] latent heat' ...
     {'classical [0=from measurement, with Bose factor included, 1=from MD, symmetric]' 'symmetry' } ...
      'multiplicity  [atoms/unit cell] number of atoms/molecules per scattering unit cell' ...
     {'IncidentEnergy [meV] neutron incident energy' 'fixed_energy' 'energy' 'ei' 'Ei'} ...
     {'IncidentWavevector [Angs-1] neutron incident wavevector' 'ki' 'Ki'} ...
     {'Distance [m] Sample-Detector distance' 'distance' } ...
     {'ChannelWidth [time unit] ToF Channel Width' } ...
     {'V_rho [Angs^-3] atom density' 'rho' } ...
    };
elseif ischar(fields) && strcmpi(fields, 'sab')
  % ENDF compatibility flags: MF1 MT451 and MF7 MT2/4
  % we have added parameters from PyNE/ENDF
  fields = { ...
    'MF ENDF File number' ...
    'MT ENDF Reaction type' ...
    'ZA ENDF material id (Z,A)' ...
   {'weight [g/mol] Material molar weight'	'mass' 'AWR'} ...
   {'classical [0=from measurement, with Bose factor included, 1=from MD, symmetric]' 'symmetry' } ...
   {'Temperature [K]' 'T' }	...
    'sigma_coh [barn] Coherent scattering neutron cross section' ...
    'sigma_inc [barn] Incoherent scattering neutron cross section'	...
    'sigma_abs [barn] Absorption neutron cross section'	...
    'At_number Atomic number Z' ...
    'Scattering process' ...
   {'Material ENDF material code' 'MAT' } ...
    'charge' ...
    'EDATE ENDF Evaluation date' ...
    'LRP ENDF Resonance flag' ...
   {'LFI ENDF Fission flag' 'fissionable' } ...
   {'NLIB ENDF Library' 'library' } ...
   {'NMOD ENDF modification id' 'modification' } ...
   {'ELIS ENDF Excitation energy' 'excitation_energy' } ...
   {'STA ENDF Target stability flag' 'stable' } ...
   {'LIS ENDF State number of the target nucleus' 'state' } ...
   {'LISO ENDF Isomeric state number' 'isomeric_state' } ...
    'NFOR ENDF format id' ...
    'AWI ENDF Projectile mass in neutron units' ...
   {'EMAX ENDF Max energy [eV]' 'energy_max' } ...
    'LREL ENDF Release number' ...
   {'NSUB ENDF Sublibrary' 'sublibrary' } ...
    'NVER ENDF Release number' ...
    'TEMP ENDF Target temperature for Doppler broadening [K]' ...
   {'LDRV ENDF derived evaluation id' 'derived' }...
    'NWD ENDF Number of records' ...
    'NXC ENDF Number of records in directory' ...
    'ZSYMAM ENDF Character representation of the material' ...
   {'ALAB ENDF Laboratory' 'laboratory' } ...
   {'AUTH ENDF Author' 'author' } ...
   {'REF ENDF Primary reference' 'reference' } ...
   {'DDATE ENDF Distribution date' 'date_distribution' } ...
   {'RDATE ENDF Release date' 'date_release' } ...
   {'ENDATE ENDF Entry date' 'date_entry' } ...
    'HSUB ENDF Libabry hierarchy' ...
    'SB ENDF bound cross section [barns]' ...
    'NR' ...
   {'NP ENDF Nb of pairs' 'n_pairs' } ...
    'LTHR ENDF Thermal data flag' ...
    'S ENDF Thermal elastic' 'E' 'LT ENDF Temperature dependance flag' ...
   {'LAT ENDF T used for (alpha,beta)' 'temperature_used' } ...
    'LASYM ENDF Asymmetry flag' 'B ENDF model parameters' 'NI' ...
   {'NS ENDF Number of states/parameters' 'num_non_principal' } ...
   {'LLN ENDF storage form [linear/ln(S)]' 'ln_S_' } ...
    'NT' 'Teff ENDF Effective temperatures [K]' ...
   {'Sab S(alpha,beta,T) scattering law' 'scattering_law' }
        };
end

% add parameters by searching field names from 'fields' in the object
for index=1:length(fields)
  f = fields{index};
  if ischar(f), f= {f}; end
  p_name = strtok(f{1});
  for f_index=1:numel(f)
    name   = strtok(f{f_index});
    if     isfield(s, name)   val0=s.(name);
    elseif isfield(s, p_name) val0=s.(p_name);
    else val0=[]; end
    if index==1 && f_index==1
      links    = findfield(s,strtok(f{f_index}),'exact');
    else
      links    = findfield(s,strtok(f{f_index}),'exact cache');
    end
    if isfield(s.Data, name)
      links = [ 'Data.' name ];
    end
    if ~iscell(links), links = { links }; end
    for l_index=1:numel(links)
      link = links{l_index};
      try
        val = s.(link);
      catch
        link = []; val=[];
      end
      % Do not update when:
      %   old value is 'larger' than previous one
      if ~isempty(val) && ~isempty(val0)
        if (isnumeric(val) && isnumeric(val0) && isscalar(val) && isscalar(val0) && val < val0) ...
        || (isnumeric(val) && isnumeric(val0) && numel(val) < numel(val0))
          link=[]; 
        end
      end
      % make sure it makes sense to update the link. must not link to itself.
      if ~isempty(link) && ~isempty(val) && ~strcmp(p_name, link)
        parameters.(p_name) = link;  % update/store the link/alias
      end
    end

  end
  fields{index} = f{1}; % store the parameter name, plus optional label
end

% now transfer parameters into the object, as alias values
s=setalias(s, 'parameters', parameters, 'Material parameters');
for index=1:numel(fields)
  [name, comment] = strtok(fields{index});
  if isfield(parameters, name)
    link = parameters.(name);  % link
    % get and store the value of the parameter
    if ~isempty(link) && ~isempty(val) && ~strcmp(name, link)  % must not link to itself
      s=setalias(s, name, link, strtrim(comment));
      parameters.(name) = get(s, link); % the value
    end
  end
end

if nargout == 0 & length(inputname(1))
  assignin('caller',inputname(1),s);
end

