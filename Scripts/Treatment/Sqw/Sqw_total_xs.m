function sigma = Sqw_total_xs(s, Ei)
  % Sqw_total_xs(s,Ei): compute the total scattering cross section for
  %   incoming neutron energy. The S(|q|,w) should be the non-classical
  %   dynamic structure factor. Such data sets are obtained from e.g.
  %   xray and neutron scattering experiments on isotropic density materials
  %   (liquids, powders, amorphous systems). Data sets from analytical models
  %   and molecular dynamics simulations must be symmetrised in energy,
  %   and the detailed balance must be applied to take into account the
  %   material temperature on the inelastic part.
  %
  %   The incident neutron energy is given in [meV], and may be computed:
  %     Ei = 2.0721*Ki^2 = 81.8042/lambda^2
  %     
  %   The S(|q|,w) is first restricted to the achievable dynamic range:
  %     Ef         = Ei - w                                is positive
  %     cos(theta) = (Ki.^2 + Kf.^2 - q.^2) ./ (2*Ki.*Kf)  is within [-1:1]
  %   and then integrated as XS = 1/2Ki^2 \int q S(q,w) dq dw
  %
  %   This value must then be multiplied by the tabulated cross-section
  %   from e.g. Sears, Neut. News 3 (1992) 26.
  %
  % A classical S(|q|,w) obeys S(|q|,w) = S(|q|,-w) and is usually given
  % on the positive energy side (w>0).
  % The non classical S(q,w), needed by this function, can be obtained from e.g:
  %   extend to +/- energy range
  %     s = Sqw_symmetrize(s); 
  %   apply detailed balance (Bose factor). Omit T if you do not know it.
  %     s = Sqw_Bosify(s, T);
  %
  % The positive energy values in the S(q,w) map correspond to Stokes processes, 
  % i.e. material gains energy, and neutrons loose energy when scattered.
  %
  % input:
  %   s: Sqw data set (non classical, with T Bose factor e.g from experiment)
  %        e.g. 2D data set with w as 1st axis (rows), q as 2nd axis.
  %   Ei: incoming neutron energy [meV]
  % output:
  %   sigma: cross section per scattering unit
  %          to be multiplied afterwards by the bound cross section
  %
  % Example: sigma = Sqw_total_xs(s, 14.6)
  %
  % See also: Sqw_Bosify, Sqw_deBosify, Sqw_symmetrize, Sqw_dynamic_range

  % first look at the given arguments
  if nargin < 2
    Ei = [];
  end

  sigma = [];

  % handle array of objects
  if numel(s) > 1
    for index=1:numel(s)
      sigma = [ sigma feval(mfilename, s(index), Ei) ];
    end
    return
  end

  % check if the data set is Sqw (2D)
  w_present=0;
  q_present=0;
  if isa(s, 'iData') && ndims(s) == 2
    for index=1:2
      lab = lower(label(s,index));
      if any(strfind(lab, 'wavevector')) || any(strfind(lab, 'q')) || any(strfind(lab, 'Angs'))
        q_present=index;
      elseif any(strfind(lab, 'energy')) || any(strfind(lab, 'w')) || any(strfind(lab, 'meV'))
        w_present=index;
      end
    end
  end
  if ~w_present || ~q_present
    disp([ mfilename ': WARNING: The data set ' s.Tag ' ' s.Title ' from ' s.Source ' does not seem to be an isotropic S(|q|,w) 2D object. Ignoring.' ]);
    return
  end
    
  
  % check if we need to transpose the S(q,w)
  if w_present==2 && q_present==1
    s = transpose(s);
  end

  if numel(Ei) > 1
    sigma = [];
    % loop for each incoming neutron energy
    for ie=1:numel(Ei)
      sigma = [ sigma Sqw_total_xs(s, Ei(ie)) ];
    end
    return
  end

  % restrict to dynamic range
  s = Sqw_dynamic_range(s, Ei);
  sq= trapz(s); % integrate over energy w {1} in the 2D Sqw

  % constants
  SE2V = 437.393377;        % Convert sqrt(E)[meV] to v[m/s]
  V2K  = 1.58825361e-3;     % Convert v[m/s] to k[1/AA]
  K2V  = 1/V2K;
  VS2E = 5.22703725e-6;     % Convert (v[m/s])**2 to E[meV]

  % compute int q.S(q)*2/Ki^2
  Ki = SE2V*V2K*sqrt(Ei);
  q = sq{1};
  sigma = trapz(q.*sq)/2/Ki^2; % integrate over q {1}
  
 
  