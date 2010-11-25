function [pars,fval,exitflag,output] = fminpowell(varargin)
% [MINIMUM,FVAL,EXITFLAG,OUTPUT] = FMINPOWELL(FUN,PARS,[OPTIONS],[CONSTRAINTS]) Powell minimization
%
% This minimization method uses the Brent-Powell method, with either the Coggins 
% or the Golden section search method at each iteration.
% 
% Calling:
%   fminpowell(fun, pars) asks to minimize the 'fun' objective function with starting
%     parameters 'pars' (vector)
%   fminpowell(fun, pars, options) same as above, with customized options (optimset)
%   fminpowell(fun, pars, options, fixed) 
%     is used to fix some of the parameters. The 'fixed' vector is then 0 for
%     free parameters, and 1 otherwise.
%   fminpowell(fun, pars, options, lb, ub) 
%     is used to set the minimal and maximal parameter bounds, as vectors.
%   fminpowell(fun, pars, options, constraints) 
%     where constraints is a structure (see below).
%
% Example:
%   banana = @(x)100*(x(2)-x(1)^2)^2+(1-x(1))^2;
%   [x,fval] = fminpowell(banana,[-1.2, 1])
%
% Input:
%  FUN is the function to minimize (handle or string).
%
%  PARS is a vector with initial guess parameters. You must input an
%  initial guess.
%
%  OPTIONS is a structure with settings for the optimizer, 
%  compliant with optimset. Default options may be obtained with
%      o=fminpowell('defaults')
%   options.Hybrid specifies the algorithm to use for line search optimizations
%      valid choices are 'Coggins' (default) and 'Golden rule'
%
%  CONSTRAINTS may be specified as a structure
%   constraints.min=   vector of minimal values for parameters
%   constraints.max=   vector of maximal values for parameters
%   constraints.fixed= vector having 0 where parameters are free, 1 otherwise
%   constraints.step=  vector of maximal parameter changes per iteration
%
% Output:
%          MINIMUM is the solution which generated the smallest encountered
%            value when input into FUN.
%          FVAL is the value of the FUN function evaluated at MINIMUM.
%          EXITFLAG return state of the optimizer
%          OUTPUT additional information returned as a structure.
%
% Reference: Brent, Algorithms for minimization without derivatives, Prentice-Hall (1973)
% Contrib: Argimiro R. Secchi (arge@enq.ufrgs.br) 2001 [powell]
%
% Version: $Revision: 1.14 $
% See also: fminsearch, optimset

% default options for optimset
if nargin == 0 || (nargin == 1 && strcmp(varargin{1},'defaults'))
  options=optimset; % empty structure
  options.Display='';
  options.TolFun =1e-3;
  options.TolX   =1e-8;
  options.MaxIter=1000;
  options.MaxFunEvals=5000;
  options.Hybrid = 'Coggins';
  options.algorithm  = [ 'Powell Search (by Secchi) [' mfilename ']' ];
  options.optimizer = mfilename;
  pars = options;
  return
end

[pars,fval,exitflag,output] = fmin_private_wrapper(mfilename, varargin{:});

