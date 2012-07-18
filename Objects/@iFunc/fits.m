function [pars_out,criteria,message,output] = fits(model, a, pars, options, constraints, varargin)
% [pars,criteria,message,output] = fits(model, data, pars, options, constraints, ...) : fit a model on a data set
%
%   @iFunc/fits find best parameter estimates in order to minimize the 
%     fitting criteria using model 'fun', by mean of an optimization method
%     described with the 'options' structure argument.
%     Additional constraints may be set by fixing some parameters, or define
%     more advanced constraints (min, max, steps). The last arguments controls the 
%     fitting options with the optimset mechanism, and the constraints to apply
%     during optimization.
%  [pars,...] = fits(model, data, pars, options, lb, ub)
%     uses lower and upper bounds as parameter constraints (double arrays)
%  [pars,...] = fits(model, data, pars, options, fixed)
%     indicates which parameters are fixed (non zero elements of array).
%  [pars,...] = fits(model, data, pars, 'optimizer', ...)
%     uses a specific optimizer and its default options options=feval(optimizer,'defaults')
%  [pars,...] = fits(model, data, pars, options, constraints, args...)
%     send additional arguments to the fit model(pars, axes, args...).
%
%  When the data is entered as a structure or iData object with a Monitor value, 
%    the fit is performed on Signal/Monitor.
%  When parameters, options, and constraints are entered as a string with
%    name=value pairs, the string is interpreted as a structure description, so
%    that options='TolX=1e-4; optimizer=fminpso' is a compact form for 
%    options=struct('TolX','1e-4','optimizer','fminpso').
% 
% The default fit options.criteria is 'least_square', but others are available:
%   least_square          (|Signal-Model|/Error).^2     non-robust 
%   least_absolute         |Signal-Model|/Error         robust
%   least_median    median(|Signal-Model|/Error)        robust, scalar
%   least_max          max(|Signal-Model|/Error)        non-robust, scalar
%
%  Type <a href="matlab:doc(iData,'Fit')">doc(iData,'Fit')</a> to access the iFit/Fit Documentation.
%
% input:  model: model function (iFunc). When entered as an empty object, the
%           list of optimizers and fit models is shown.
%         data: array or structure/object (numeric or structure or cell)
%               Can be entered as a single numeric array (the Signal), or as a 
%                 structure/object with possible members 
%                   Signal, Error, Monitor, Axes={x,y,...}
%               or as a cell { x,y, ... , Signal }
%               or as an iData object
%           The 1st axis 'x' is row wise, the 2nd 'y' is column wise.
%         pars: initial model parameters (double array, string or structure). 
%           when set to empty or 'guess', the starting parameters are guessed.
%           Named parameters can be given as a structure or string 'p1=...; p2=...'
%         options: structure as defined by optimset/optimget (char/struct)
%           if given as a char, it defines the algorithm to use and its default %             options (single optimizer name or string describing a structure).
%           when set to empty, it sets the default algorithm options (fmin).
%           options.TolX
%             The termination tolerance for x. Its default value is 1.e-4.
%           options.TolFun
%             The termination tolerance for the function value. The default value is 1.e-4. 
%             This parameter is used by fminsearch, but not fminbnd.
%           options.MaxIter
%             Maximum number of iterations allowed.
%           options.MaxFunEvals
%             The maximum number of function evaluations allowed. 
%           options.optimizer
%             Optimization method. Default is 'fminpowell' (char/function handle)
%             the syntax for calling the optimizer is e.g. optimizer(criteria,pars,options,constraints)
%           options.criteria
%             Minimization criteria. Default is 'least_square' (char/function handle)
%             the syntax for evaluating the criteria is criteria(Signal, Error, Model)
%           options.OutputFcn
%             Function called at each iteration as outfun(pars, optimValues, state)
%             The 'fminplot' function may be used.
%           options.Display
%             Display additional information during fit: 'iter','off','final'. Default is 'iter'.
%         constraints: fixed parameter array. Use 1 for fixed parameters, 0 otherwise (double array)
%           OR use empty to not set constraints
%           OR use a structure with some of the following fields:
%           constraints.min:   minimum parameter values (double array)
%           constraints.max:   maximum parameter values (double array)
%           constraints.step:  maximum parameter step/change allowed.
%           constraints.fixed: fixed parameter flag. Use 1 for fixed parameters, 0 otherwise (double array)
%           OR use a string 'min=...; max=...'
%
% output: 
%         pars:              best parameter estimates (double array)
%         criteria:          minimal criteria value achieved (double)
%         message:           return message/exitcode from the optimizer (char/integer)
%         output:            additional information about the optimization (structure)
%           algorithm:         Algorithm used (char)
%           funcCount:         Number of function evaluations (double)
%           iterations:        Number of iterations (double)
%           parsHistory:       Parameter set history during optimization (double array)
%           criteriaHistory:   Criteria history during optimization (double array)
%           modelValue:        Final best model evaluation
%           parsHistoryUncertainty: Uncertainty on the parameters obtained from 
%                              the optimization trajectory (double)
%
% ex:     p=fits(gauss, data,[1 2 3 4]);
%         o=fminpowell('defaults'); o.OutputFcn='fminplot'; 
%         [p,c,m,o]=fits(gauss,data,[1 2 3 4],o); 
%         plot(a); hold on; plot(o.modelAxes, o.modelValue,'r');
%
% Version: $Revision: 1.3 $
% See also fminsearch, optimset, optimget, iFunc, iData/fits, iData, ifitmakefunc

% first get the axes and signal from 'data'

% a.Signal (numeric)
% a.Error (numeric)
% a.Monitor (numeric)
% a.Axes (cell of numeric)

% singlme empty argument: show funcs/optim list ================================
% handle default parameters, if missing
if nargin == 1 && isempty(model)
    % return the list of all available optimizers and fit functions
    output     = {};
    pars_out   = {};
    warn       = warning('off','MATLAB:dispatcher:InexactCaseMatch');
    if nargout == 0
      fprintf(1, '\n%s\n', version(iData));
      
      fprintf(1, '      OPTIMIZER DESCRIPTION [%s]\n', 'iFit/Optimizers');
      fprintf(1, '-----------------------------------------------------------------\n'); 
    end
    d = dir([ fileparts(which(mfilename)) filesep '..' filesep 'Optimizers' ]);
    for index=1:length(d)
      this = d(index);
      try
        [dummy, method] = fileparts(this.name);
        options = feval(method,'defaults');
        if isstruct(options)
          output{end+1} = options;
          pars_out{end+1}   = method;
          if nargout == 0
            fprintf(1, '%15s %s\n', options.optimizer, options.algorithm);
          end
        end
      end
    end % for
    if nargout == 0
      fprintf(1, '\n');
      fprintf(1, '       FUNCTION DESCRIPTION [%s]\n', 'iFit/Models');
      fprintf(1, '-----------------------------------------------------------------\n'); 
    end
    d = dir([ fileparts(which(mfilename)) filesep '..' filesep 'Models' ]);
    criteria = []; 
    for index=1:length(d)
      this = d(index);
      try
        [dummy, method] = fileparts(this.name);
        options = feval(method,'identify');
        if isa(options, 'iFunc')
          criteria   = [ criteria options ];
          if nargout == 0
            fprintf(1, '%15s %s\n', method, options.Name);
          end
        end
      end
    end % for
    
    % local (pwd) functions
    message = '';
    d = dir(pwd);
    for index=1:length(d)
      this = d(index);
      try
        [dummy, method] = fileparts(this.name);
        options = feval(method,'identify');
        if isa(options, 'iFunc')
          criteria   = [ criteria options ];
          if isempty(message)
            fprintf(1, '\nLocal functions in: %s\n', pwd);
            message = ' ';
          end
          if nargout == 0
            fprintf(1, '%15s %s\n', method, options.Name);
          end
        end
      end
    end % for

    if nargout == 0 && length(criteria)
      fprintf(1, '\n');
      % plot all functions
      subplot(criteria);
    end
    message = 'Optimizers and fit functions list'; 
    warning(warn);
    return
end


% check of input arguments =====================================================

if isempty(model)
  disp([ 'iFunc:' mfilename ': Using default gaussian model as fit function.' ]);
  model = gauss;
end

if nargin < 2
	a = [];
end

% extract Signal from input argument, as well as a Data identifier
% default values
Monitor=1; Error=1; Axes={}; Signal=[]; Name = ''; is_idata=[];
if iscell(a)
  Signal = a{end};
  a(end) = [];
  Axes = a;
elseif isstruct(a) || isa(a, 'iData')
  if isfield(a,'Signal')  Signal  = a.Signal; end
  if isfield(a,'Error')   Error   = a.Error; end
  if isfield(a,'Monitor') Monitor = a.Monitor; end
  if isa(a, 'iData')
    is_idata = a;
    Axes=cell(1,ndims(a));
    for index=1:ndims(a)
      Axes{index} = getaxis(a, index);
    end
    Name = strtrim([ inputname(2) ' ' char(a) ]);
  elseif isfield(a,'Axes')    Axes    = a.Axes; 
  end
elseif isnumeric(a)
  Signal = a; 
end
if isempty(Name)
  Name   = [ class(a) ' ' mat2str(size(Signal)) ' ' inputname(2) ];
end

if ~iscell(Axes) && isvector(Axes), Axes = { Axes }; end

% create the new Data structure to pass to the criteria
a = [];
a.Signal = iFunc_private_cleannaninf(Signal);
a.Error  = iFunc_private_cleannaninf(Error);
a.Monitor= iFunc_private_cleannaninf(Monitor);
a.Axes   = Axes;
clear Signal Error Monitor Axes

% starting configuration
SignalMon = a.Signal;
if not(all(a.Monitor(:) == 1 | a.Monitor(:) == 0)),
  SignalMon  = bsxfun(@rdivide,SignalMon, a.Monitor); 
end

if isempty(a.Signal)
  error([ 'iFunc:' mfilename ],[ 'Undefined/empty Signal ' inputname(2) ' to fit. Syntax is fits(model, Signal, parameters, ...).' ]);
end

if isvector(a.Signal) ndimS = 1;
else                  ndimS = ndims(a.Signal);
end
% handle case when model dimensionality is larger than actual Signal
if model.Dimension > ndimS
  error([ 'iFunc:' mfilename ], 'Signal %s with dimensionality %d has lower dimension than model %s dimensionality %d.\n', Name, ndimS, model.Name, model.Dimension);
% handle case when model dimensionality is smaller than actual Signal
elseif model.Dimension < ndimS && rem(ndimS, model.Dimension) == 0
  % extend model to match Signal dimensions
  disp(sprintf('iFunc:%s: Extending model %s dimensionality %d to data %s dimensionality %d.\n', ...
    mfilename, model.Name, model.Dimension, Name, ndimS));
  new_model=model;
  for index=2:(ndimS/model.Dimension)
    new_model = new_model * model;
  end
  model = new_model;
  clear new_model
elseif model.Dimension ~= ndimS
  error([ 'iFunc:' mfilename ], 'Signal %s with dimensionality %d has higher dimension than model %s dimensionality %d.\n', Name, ndimS, model.Name, model.Dimension);
end

% handle parameters: from char, structure or vector
if nargin < 3
  pars = []; % will use default/guessed parameters
end
pars_isstruct=0;
if ischar(pars) && ~strcmp(pars,'guess')
  pars = str2struct(pars);
end
if isstruct(pars)
  % search 'pars' names in the model parameters, and reorder the parameter vector
  p = [];
  for index=1:length(model.Parameters)
    match = strcmp(model.Parameters{index}, fieldnames(pars));
    if ~isempty(match) && any(match)
      p(index) = pars.(model.Parameters{index});
    end
  end
  if length(p) ~= length(model.Parameters)
    disp('Actual parameters')
    disp(pars)
    disp([ 'Required model ' model.Name ' ' model.Tag ' parameters' ])
    disp(model.Parameters)
    error([ 'iFunc:' mfilename], [ 'The parameters entered as a structure do not define all required model parameters.' ]);
  else
    pars_isstruct=1;
    pars = p;
  end
elseif strcmp(pars,'guess')
  feval(model, pars, a.Axes{:}, SignalMon);           % get default starting parameters
  pars = model.ParameterValues;
elseif isempty(pars)
  if ~isempty(model.ParameterValues)
    pars = model.ParameterValues;                % use stored starting parameters
  else     
    pars = feval(model, 'guess', a.Axes{:}, SignalMon);         % get default starting parameters
  end
end
pars = reshape(pars, [ 1 numel(pars)]); % a single row

% handle options
if nargin < 4, options=[]; end
if isempty(options)
  options = 'fmin';% default optimizer
end
if (ischar(options) && length(strtok(options,' =:;'))==length(options)) | isa(options, 'function_handle')
  algo = options;
  options           = feval(algo,'defaults');
  if isa(algo, 'function_handle'), algo = func2str(algo); end
  options.optimizer = algo;
elseif ischar(options), options=str2struct(options);
end
if ~isfield(options, 'optimizer')
  options.optimizer = 'fmin';
end
if ~isfield(options, 'criteria')
  options.criteria  = @least_square;
end
if ~isfield(options,'Display')   options.Display  =''; end
if  isempty(options.Display)     options.Display  ='notify'; end
if ~isfield(options,'algorithm') options.algorithm=options.optimizer; end

% handle constraints
if nargin < 5
  constraints = [];     % no constraints
end
% handle constraints given as vectors
if (length(constraints)==length(pars) | isempty(pars)) & (isnumeric(constraints) | islogical(constraints))
  if nargin<6
    fixed            = constraints;
    constraints      =[];
    constraints.fixed=fixed;
  elseif isnumeric(varargin{1}) && ~isempty(varargin{1}) ...
      && length(constraints) == length(varargin{1})
    % given as lb,ub parameters (nargin==6)
    lb = constraints;
    ub = varargin{1};
    varargin(1) = []; % remove the 'ub' from the additional arguments list
    constraints     = [];
    constraints.min = lb;
    constraints.max = ub;
  end
elseif ischar(constraints), options=str2struct(constraints);
end
if ~isstruct(constraints) && ~isempty(constraints)
  error([ 'iFunc:' mfilename],[ 'The constraints argument is of class ' class(constraints) '. Should be a single array or a struct' ]);
end
constraints.parsStart      = pars;
constraints.parsHistory    = [];
constraints.criteriaHistory= [];
constraints.algorithm      = options.algorithm;
constraints.optimizer      = options.optimizer;
constraints.funcCount      = 0;

% handle arrays of model functions
if numel(model) > 1
  pars_out={} ; criteria={}; message={}; output={};
  for index=1:numel(model)
    [pars_out{end+1},criteria{end+1},message{end+1},output{end+1}]=fits(model(index), a, pars, options, constraints, varargin{:});
  end
  return
end

feval(model, pars, a.Axes{:}, SignalMon); % this updates the 'model' with starting parameter values

if strcmp(options.Display, 'iter') | strcmp(options.Display, 'final')
  fprintf(1, '** Starting fit of %s\n   using model    %s\n   with optimizer %s\n', ...
    Name,  model.Name, options.algorithm);
  disp(  '** Minimization performed on parameters:');
  for index=1:length(model.Parameters); 
    fprintf(1,'  p(%3d)=%20s=%g\n', index,strtok(model.Parameters{index}), pars(index)); 
  end;
end

% we need to call the optimization method with the eval_criteria as FUN
% call minimizer ===============================================================
if abs(nargin(options.optimizer)) == 1 || abs(nargin(options.optimizer)) >= 6
  [pars_out,criteria,message,output] = feval(options.optimizer, ...
    @(pars) eval_criteria(model, pars, options.criteria, a, varargin{:}), pars, options, constraints);
else
  % Constraints not supported by optimizer
  [pars_out,criteria,message,output] = feval(options.optimizer, ...
    @(pars) eval_criteria(model, pars, options.criteria, a, varargin{:}), pars, options);
end

% format output arguments ======================================================
pars_out = reshape(pars_out, [ 1 numel(pars_out) ]); % row vector
model.ParameterValues = pars_out;
if nargout > 3
  output.modelValue = feval(model, pars_out, a.Axes{:});
  output.corrcoef   = eval_corrcoef(a.Signal, a.Error, a.Monitor, output.modelValue);
  if strcmp(options.Display, 'iter') | strcmp(options.Display, 'final')
    fprintf(1, ' Correlation coefficient=%g\n', output.corrcoef);
  end
  
  if ~isempty(is_idata)
    % make it an iData
    b = is_idata;
    % fit(signal/monitor) but object has already Monitor -> we compensate Monitor^2
    if not(all(a.Monitor == 1 | a.Monitor == 0)) 
      output.modelValue    = bsxfun(@times,output.modelValue, a.Monitor); 
    end
    setalias(b,'Signal', output.modelValue, model.Name);
    b.Title = [ model.Name '(' char(b) ')' ];
    b.Label = b.Title;
    b.DisplayName = b.Title;
    setalias(b,'Error', 0);
    setalias(b,'Parameters', pars_out, [ model.Name ' model parameters for ' Name ]);
    setalias(b,'Model', model, model.Name);
    output.modelValue = b;
  else
    if length(a.Axes) == 1
      output.modelAxes  = a.Axes{1};
    else
      output.modelAxes  = a.Axes(:);
    end
  end
  output.model      = model;
  
  % set output/results
  if ischar(message) | ~isfield(output, 'message')
    output.message = message;
  else
    output.message = [ '(' num2str(message) ') ' output.message ];
  end
  output.parsNames  = model.Parameters;
  
end
if pars_isstruct
  pars_out = cell2struct(num2cell(pars_out), strtok(model.Parameters), 2);
end

end % fits


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PRIVATE FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%
function c = eval_criteria(model, pars, criteria, a, varargin)
% criteria to minimize
  if nargin<5, varargin={}; end
  % then get model value
  Model  = feval(model, pars, a.Axes{:}, varargin{:}); % return model values
  Model  = iFunc_private_cleannaninf(Model);
  if isempty(Model)
    error([ 'iFunc:' mfilename ],[ 'The model ' model ' could not be evaluated (returned empty).' ]);
  end
  a.Monitor =real(a.Monitor);
  if not(all(a.Monitor == 1 | a.Monitor == 0)),
    % Model    = bsxfun(@rdivide,Model,   a.Monitor); % fit(signal/monitor) 
    a.Signal = bsxfun(@rdivide,a.Signal,a.Monitor); 
    a.Error  = bsxfun(@rdivide,a.Error, a.Monitor); % per monitor
  end
  
  % compute criteria
  c = feval(criteria, a.Signal(:), a.Error(:), Model(:));
  % divide by the number of degrees of freedom
  % <http://en.wikipedia.org/wiki/Goodness_of_fit>
  if numel(a.Signal) > length(pars)-1
    c = c/(numel(a.Signal) - length(pars) - 1); % reduced 'Chi^2'
  end
end % eval_criteria

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% <http://en.wikipedia.org/wiki/Least_squares>
function c=least_square(Signal, Error, Model)
% weighted least square criteria, which is also the Chi square
% the return value is a vector, and most optimizers use its sum (except LM).
% (|Signal-Model|/Error).^2
  c = least_absolute(Signal, Error, Model);
  c = c.*c;
end % least_square

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% <http://en.wikipedia.org/wiki/Least_absolute_deviation>
function c=least_absolute(Signal, Error, Model)
% weighted least absolute criteria
% the return value is a vector, and most optimizers use its sum (except LM).
% |Signal-Model|/Error
  if isempty(Error) || isscalar(Error) || all(Error == Error(end))
    index = find(isfinite(Model) & isfinite(Signal));
    c = abs(Signal(index)-Model(index)); % raw least absolute
  else
    % find minimal non zero Error
    Error = abs(Error);
    index = find(Error~=0 & isfinite(Error));
    minError = min(Error(index));
    % find zero Error, which should be replaced by minimal Error whenever possible
    index = find(Error == 0);
    Error(index) = minError;
    index = find(isfinite(Error) & isfinite(Model) & isfinite(Signal));
    if isempty(index), c=Inf;
    else               c=abs((Signal(index)-Model(index))./Error(index));
    end
  end
end % least_absolute

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% <http://en.wikipedia.org/wiki/Median_absolute_deviation>
function c=least_median(Signal, Error, Model)
% weighted median absolute criteria
% the return value is a scalar
% median(|Signal-Model|/Error)
  c = median(least_absolute(Signal, Error, Model));
end % least_median

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% <http://en.wikipedia.org/wiki/Absolute_deviation>
function c=least_max(Signal, Error, Model)
% weighted median absolute criteria
% the return value is a scalar
% median(|Signal-Model|/Error)
  c = max(least_absolute(Signal, Error, Model));
end % least_max

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function r=eval_corrcoef(Signal, Error, Monitor, Model)
% correlation coefficient between the data and the model

  if not(all(Monitor(:) == 1 | Monitor(:) == 0)),
    Model  = bsxfun(@rdivide,Model, Monitor); % fit(signal/monitor) 
    Signal = bsxfun(@rdivide,Signal,Monitor); 
    Error  = bsxfun(@rdivide,Error, Monitor); % per monitor
  end
  
  % compute the correlation coefficient
  if isempty(Error) || isscalar(Error) || all(Error(:) == Error(end))
    wt = 1;
  else
    wt = 1./Error;
    wt(find(~isfinite(wt))) = 0;
  end
  r = corrcoef(Signal.*wt,Model.*wt);
  r = r(1,2);                                     % correlation coefficient
  if isnan(r)
    r = corrcoef(Signal,Model);
    r = r(1,2);
  end
end % eval_corrcoef

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function s=iFunc_private_cleannaninf(s)
% iFunc_private_cleannaninf: clean NaNs and Infs from a numerical field
%
  
  if isnumeric(s)
    S = s(:);
    if all(isfinite(S)), return; end
    index_ok     = find(isfinite(S));

    maxs = max(S(index_ok));
    mins = min(S(index_ok));

    S(isnan(S)) = 0;
    if ~isempty(mins)
      if mins<0, S(find(S == -Inf)) = mins*100;
      else       S(find(S == -Inf)) = mins/100; end
    end
    if ~isempty(maxs)
      if maxs>0, S(find(S == +Inf)) = maxs*100;
      else       S(find(S == +Inf)) = maxs/100; end
    end

    s = double(reshape(S, size(s)));
  end

end