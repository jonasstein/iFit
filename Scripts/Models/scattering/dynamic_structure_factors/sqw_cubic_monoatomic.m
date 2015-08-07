function signal=sqw_cubic_monoatomic(varargin)
% model = sqw_cubic_monoatomic(p, h,k,l,w, {signal}) : 3D dispersion(HKL) in perovskites ABX3 with DHO(energy)
%
%   iFunc/sqw_cubic_monoatomic: a 4D S(q,w) with a 3D HKL dispersion, and a DHO line
%      shape, for a simple monoatomic system on a cubic lattice. Only the 3 
%      acoustic modes are computed.
%
% WARNING: this model is slow to evaluate.
%      Single intensity and line width parameters are used here.
%      The HKL position is relative to the closest Bragg peak. 
%
% Example:
% s=sqw_cubic_monoatomic([1 1]); qh=linspace(0,.5,50);qk=qh; ql=qh; w=linspace(0.01,10,51);
% f=iData(s,[],qh,qk,ql,w); scatter3(log(f(:,:,1,:)),'filled');
%
% References: 
%
% input:  p: sqw_cubic_monoatomic model parameters (double)
%           p(1)=C_ratio C1/C2 force constant ratio first/second neighbours.
%           p(2)=E0      sqrt(C1/m) energy [meV]
%           p(3)=Gamma   dispersion DHO half-width in energy [meV]
%           p(4)=Temperature of the material [K]
%           p(5)=Amplitude
%           p(6)=Background (constant)
%         qh: axis along QH in rlu (row,double)
%         qk: axis along QK in rlu (column,double)
%         ql: axis along QL in rlu (page,double)
%         w:  axis along energy in meV (double)
%    signal: when values are given, a guess of the parameters is performed (double)
% output: signal: model value
%
% Version: $Date$
% See also iData, iFunc/fits, iFunc/plot, gauss

signal.Name           = [ 'S(q,w) 3D dispersion(HKL) for cubic monoatomic crystal [' mfilename ']' ];
signal.Description    = 'A 3D HKL 3D dispersion(HKL) for a cubic monoatomic crystal with DHO(energy) shape. From the dynamical matrix.';

signal.Parameters     = {  ...
  'C_ratio C1/C2 force constant ratio first/second neighbours' ...
  'E0      sqrt(C1/m) energy [meV]' ...
  'Gamma   Dampled Harmonic Oscillator width in energy [meV]' ...
  'Temperature [K]' ...
  'Amplitude' 'Background' };
  
signal.Dimension      = 4;           % dimensionality of input space (axes) and result

signal.Guess          = [1 1 .1 10 1 0];        % default parameters

signal.Expression     = { ...
'% get parameter values',...
'c_quot=p(1); E0=p(2); Gamma=p(3); T=p(4); Amplitude=p(5); Bkg=p(6);', ...
'signal=zeros(size(x));',...
'M = nan(3);', ...
'if ndims(x) == 4, x=squeeze(x(:,:,:,1)); y=squeeze(y(:,:,:,1)); z=squeeze(z(:,:,:,1)); end',...
'for index=1:numel(x); kx=x(index); ky=y(index); kz=z(index);', ...
'  M(1, 1) = 2*(1 - cos(2*pi*kx)) +2/c_quot*(2- cos(2*pi*kx)*cos(2*pi*ky)-cos(2*pi*kx)*cos(2*pi*kz)) ;', ...
'  M(1, 2) = 2/c_quot* sin(2*pi*kx)* sin(2*pi*ky) ;', ...
'  M(1, 3) = 2/c_quot* sin(2*pi*kx)* sin(2*pi*kz) ;', ...
'  M(2, 1) = M(1, 2) ;', ...
'  M(2, 2) = 2*(1 - cos(2*pi*ky)) +2/c_quot*(2- cos(2*pi*kx)*cos(2*pi*ky)-cos(2*pi*ky)*cos(2*pi*kz)) ;', ...
'  M(2, 3) = 2/c_quot* sin(2*pi*ky)* sin(2*pi*kz) ;', ...
'  M(3, 1) = M(1, 3) ;', ...
'  M(3, 2) = M(2, 3) ;', ...
'  M(3, 3) = 2*(1 - cos(2*pi*kz)) +2/c_quot*(2-cos(2*pi*kx)*cos(2*pi*kz)-cos(2*pi*ky)*cos(2*pi*kz)) ;', ...
'  [eigvectors,eigvalues ] = eig(M);',...
'  eigvalues = sqrt(diag(eigvalues))*E0;',...
'  [dummy,sorted]=max(abs(eigvectors''));',...
'  eigvalues = eigvalues(sorted);',...
'% apply DHO on each',...
'if T<=0, T=300; end', ...
'p=[Amplitude eigvalues(1) Gamma Bkg T/11.609 ];',...
'for m=1:numel(eigvalues)',...
'  p(2)=eigvalues(m); ',...
'  if ndims(x)==3',...
'    [ix,iy,iz] = ind2sub(size(x),index); w=t(ix,iy,iz,:);',...
'    signal(ix,iy,iz,:) = signal(ix,iy,iz,:)+p(1)*p(3) *p(2)^2.*(1+1./(exp(abs(w)/p(5))-1))./((w.^2-p(2)^2).^2+(p(3)*w).^2);',...
'  else',...
'    signal = signal+p(1)*p(3) *p(2)^2.*(1+1./(exp(abs(t)/p(5))-1))./((t.^2-p(2)^2).^2+(p(3)*t).^2);',...
'  end',...
'end % for modes',...
'end % index in kx,ky,kz' };

signal=iFunc(signal);

if nargin == 1 && isnumeric(varargin{1})
  p = varargin{1};
  if numel(p) == 2, p =[ p(:)' .1 10 1 0 ]; end 
  signal.ParameterValues = p;
elseif nargin > 1
  signal = signal(varargin{:});
end

