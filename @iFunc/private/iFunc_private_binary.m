function c = iFunc_private_binary(a, b, op, varargin)
% iFunc_private_binary: handles binary operations
%
% Operator may apply on an iFunc array and:
%   a scalar/vector/matrix
%   a single iFunc object, which is then used for each iFunc array element
%     operator(a(index), b)
%   a string which is catenated with the Expression
%   an iFunc array, which should then have the same dimension as the other 
%     iFunc argument, in which case operator applies on pairs of both arguments.
%     operator(a(index), b(index))
%
% operator may be: 'plus','minus','times','rdivide','conv', 'xcorr', 'power'
%                  'mtimes','mrdivide','mpower' -> perform orthogonal axes dimensionality extension

% supported syntax: 
% iFunc <op> iFunc -> catenate Parameters Constraint and Expression, rename p and signal for each iFunc
% iFunc <op> scalar
% iFunc <op> string -> directly catenate with the Expression
% iFunc <op> global variable (caller/base)

% handle iFunc array input
if isa(a,'iFunc') && numel(a) > 1
  c = [];
  for index=1:numel(a)
    c = [ c iFunc_private_binary(a(index), b, op, varargin{:}) ];
  end
  return
elseif isa(b,'iFunc') && numel(b) > 1
  c = [];
  for index=1:numel(b)
    c = [ c iFunc_private_binary(a, b(index), op, varargin{:}) ];
  end
  return
end

isFa = isa(a, 'iFunc');
isFb = isa(b, 'iFunc');
if isempty(varargin)
  v = '';
else
  v = [ ', ''' char(varargin{1}) '''' ];
end

% make sure we have chars only (get rid of function handles)
if isFa 
  ax = 'x,y,z,t,u,'; ax = ax(1:(a.Dimension*2));
  if isa(a.Expression, 'function_handle')
    a.Expression = sprintf('signal = feval(%s, p, %s);', func2str(a.Expression), ax(1:(end-1)));
  end
  if isa(a.Constraint, 'function_handle')
    a.Constraint = sprintf('p = feval(%s, p, %s);', func2str(a.Constraint), ax(1:(end-1)));
  end
  if isa(a.Guess, 'function_handle')
    a.Guess = sprintf('[ feval(%s, %s, signal) ]', func2str(a.Guess), ax(1:(end-1)));
  elseif isnumeric(a.Guess)
    a.Guess = mat2str(double(a.Guess));
  end
end

if isFb
  ax = 'x,y,z,t,u,'; ax = ax(1:(b.Dimension*2));
  if isa(b.Expression, 'function_handle')
    b.Expression = sprintf('signal = feval(%s, p, %s);', func2str(b.Expression), ax(1:(end-1)));
  end
  if isa(b.Constraint, 'function_handle')
    b.Constraint = sprintf('p = feval(%s, p, %s);', func2str(b.Constraint), ax(1:(end-1)));
  end
  if isa(b.Guess, 'function_handle')
    b.Guess = sprintf('[ feval(%s, %s, signal) ]', func2str(b.Guess), ax(1:(end-1)));
  elseif isnumeric(b.Guess)
    b.Guess = mat2str(double(b.Guess));
  end
end

if isFa, c=a; else c=b; end

% now handle single object operation
if isFa && isFb
  % check Dimension: must be identical
  if a.Dimension ~= b.Dimension && 0
    error(['iFunc:' mfilename ], [mfilename ': can not apply operator ' op ' between iFunc objects of different dimensions' num2str(a.Dimension) ' and ' num2str(b.Dimension) '.' ]);
  end
  
  % use Tag-based names to copy/store signal and parameters
  tmp_a=a.Tag; 
  tmp_b=b.Tag; 
  if strcmp(tmp_a, tmp_b)
    t=iFunc;
    tmp_b=t.Tag;
  end
  % determine parameter indices for each object
  i1a=    1; i2a=    length(a.Parameters);
  i1b=i2a+1; i2b=i2a+length(b.Parameters);
  
  % append Parameter names
  Parameters(i1a:i2a)=a.Parameters;
  Parameters(i1b:i2b)=b.Parameters;
  % check for unicity of names and possibly rename similar ones
  [Pars_uniq, i,j] = unique(strtok(Parameters)); % length(j)=Pars_uniq, length(i)=Parameters
  for index=1:length(Pars_uniq)
    index_same=find(strcmp(Pars_uniq(index), strtok(Parameters)));
    if length(index_same) > 1 % more than one parameter with same name
      for k=2:length(index_same)
        [tok,rem] = strtok(Parameters{index_same(k)});
        Parameters{index_same(k)} = [ tok '_' num2str(k) ' ' rem ];
      end
    end
  end
  c.Parameters=Parameters; clear Parameters
  
  % append ParameterValues
  if length(a.ParameterValues) == length(a.Parameters) && length(b.ParameterValues) == length(b.Parameters)
    ParameterValues(i1a:i2a)=a.ParameterValues;
    ParameterValues(i1b:i2b)=b.ParameterValues;
  else
    ParameterValues=[];
  end
  c.ParameterValues=ParameterValues; clear ParameterValues
  
  % append parameter Guess
  if ischar(a.Guess) && ischar(b.Guess)
    Guess = [ '[ ' a.Guess ' ' b.Guess ' ]' ];
  elseif length(a.Guess) == length(a.Parameters) && length(b.Guess) == length(b.Parameters) ...
     && isnumeric(a.Guess) && isnumeric(b.Guess)
    Guess(i1a:i2a)=a.Guess;
    Guess(i1b:i2b)=b.Guess;
  else
    Guess=[];
  end
  c.Guess=Guess; clear Guess
  
  % append UserData
  if ~isempty(a.UserData) && ~isempty(b.UserData)
    c.UserData.a=a.UserData;
    c.UserData.b=b.UserData;
  elseif ~isempty(a.UserData)
    c.UserData=a.UserData;
  else
    c.UserData=b.UserData;
  end
  
  % append Description and Name
  if isempty(a.Description), a.Description = sprintf('%iD', ndims(a)); end
  if isempty(b.Description), b.Description = sprintf('%iD', ndims(b)); end
  c.Description = [ '(', a.Description, ') ', op, ' (', b.Description, ')' ]; 
  
  if isempty(a.Name), a.Name = tmp_a; end
  if isempty(b.Name), b.Name = tmp_b; end
  c.Name        = [ '(', a.Name, ') '       , op, ' (', b.Name, ')' ]; 
  
  % new Tag and Date
  t = iFunc;
  c.Tag  = t.Tag;
  c.Date = t.Date;
  
  % handle cross/orthogonal axes operation -> extend dimension
  if any(strcmp(op, {'mpower','mtimes','mrdivide'}))
    c.Dimension=a.Dimension + b.Dimension;
  else
    c.Dimension=max(a.Dimension,b.Dimension);
  end
  
  % append Constraint ==========================================================
  if     isempty(a.Constraint), c.Constraint = b.Constraint;
  elseif isempty(b.Constraint), c.Constraint = a.Constraint;
  else
    % append Constraint: 1st
    c.Constraint = [ ...
      sprintf('%s_p = p; %% store the whole parameter values\n'  , tmp_a), ... % full parameter vector
      sprintf('p=%s_p(%i:%i); %% evaluate 1st constraint for %s\n', tmp_a, i1a, i2a, op), ...
      a.Constraint, ...
      sprintf('%s_p(%i:%i)=p; %% updated parameters\n', tmp_a, i1a, i2a) ];
      
    % handle dimensionality expansion
    if any(strcmp(op, {'mpower','mtimes','mrdivide'}))
      ax = 'xyztu';
      % store inital axes definitions
      for index=1:c.Dimension
        c.Constraint = [ c.Constraint, sprintf('%s_%s = %s; %% store initial axes\n', tmp_a, ax(index), ax(index)) ];
      end
      % set 'b' axes from input axes, shifted backwards
      for index=1:b.Dimension
        c.Constraint = [ c.Constraint, sprintf('%s = %s; %% axes for 2nd object\n', ax(index), ax(index+a.Dimension)) ];
      end
    end
    
    % append Constraint: 2nd
    c.Constraint = [ c.Constraint, ...
      sprintf('p=%s_p(%i:%i); %% evaluate 2nd constraint for %s\n', tmp_a, i1b, i2b, op)
      b.Constraint, ...
      sprintf('%s_p(%i:%i)=p; %% updated parameters\n', tmp_a, i1b, i2b), ...
      sprintf('p=%s_p; %% restore initial parameter values\n'  , tmp_a) ];
    % restore initial axes definitions
    if any(strcmp(op, {'mpower','mtimes','mrdivide'}))
      for index=1:c.Dimension
        c.Constraint = [ c.Constraint, sprintf('%s = %s_%s; %% restore initial axes\n', ax(index), tmp_a, ax(index)) ];
      end
    end
  end
  
  % append Guess ==========================================================
  if ~isempty(a.Guess) && ~isempty(b.Guess)
    % append Guess: 1st
    c.Guess = [ ...
      sprintf('p=%s; %% evaluate 1st guess for %s\n', a.Guess, op), ...
      sprintf('%s_p(%i:%i)=p; %% updated parameters\n', tmp_a, i1a, i2a) ];
      
    % handle dimensionality expansion
    if any(strcmp(op, {'mpower','mtimes','mrdivide'}))
      ax = 'xyztu';
      % store inital axes definitions
      for index=1:c.Dimension
        c.Guess = [ c.Guess, sprintf('%s_%s = %s; %% store initial axes\n', tmp_a, ax(index), ax(index)) ];
      end
      % set 'b' axes from input axes, shifted backwards
      for index=1:b.Dimension
        c.Guess = [ c.Guess, sprintf('%s = %s; %% axes for 2nd object\n', ax(index), ax(index+a.Dimension)) ];
      end
    end
    
    % append Guess: 2nd
    c.Guess = [ c.Guess, ...
      sprintf('p=%s; %% evaluate 2nd Guess for %s\n', b.Guess, op), ...
      sprintf('%s_p(%i:%i)=p; %% updated parameters\n', tmp_a, i1b, i2b), ...
      sprintf('p=%s_p; %% restore initial parameter values\n'  , tmp_a) ];
  end
  
  % append Expression:
  % =========================================================
  c.Expression = [ ...
    sprintf('%s_p = p; %% store the whole parameter values\n'  , tmp_a), ...
    sprintf('p=%s_p(%i:%i); %% evaluate 1st expression for %s\n', tmp_a, i1a, i2a, op), ...
    a.Expression, ...
    sprintf('\n%s_s = signal;\n', tmp_a), ...
    sprintf('%s_p(%i:%i)=p; %% updated parameters\n', tmp_a, i1a, i2a) ];
  
  % handle dimensionality expansion
  if any(strcmp(op, {'mpower','mtimes','mrdivide'}))
    ax = 'xyztu';
    % store inital axes definitions
    for index=1:c.Dimension
      c.Expression = [ c.Expression, sprintf('%s_%s = %s; %% store initial axes\n', tmp_a, ax(index), ax(index)) ];
    end
    % set 'b' axes from input axes, shifted backwards
    for index=1:b.Dimension
      c.Expression = [ c.Expression, sprintf('%s = %s; %% axes for 2nd object\n', ax(index), ax(index+a.Dimension)) ];
    end
  end
  
  % append Expression: 2nd
  c.Expression = [ c.Expression, ...
    sprintf('p=%s_p(%i:%i); %% evaluate 2nd expression for %s\n', tmp_a, i1b, i2b, op), ...
    b.Expression, ...
    sprintf('\n%s_p(%i:%i)=p; %% updated parameters\n', tmp_a, i1b, i2b), ...
    sprintf('p=%s_p;\n'  , tmp_a) ];
  if any(strcmp(op, {'mpower','mtimes','mrdivide'}))
    % arrrange 2nd signal so that dimensions match singleton ones for the 1st signal
    % if b.Dimension == 1
    %  c.Expression = [ c.Expression, ...
    %    sprintf('signal=reshape(signal, [ ones(1,%i) numel(signal) ]);\n', a.Dimension) ];
    %else
    %  c.Expression = [ c.Expression, ...
    %    sprintf('signal=reshape(signal, [ ones(1,%i) size(signal) ]);\n', a.Dimension) ];
    %end
    c.Expression = [ c.Expression, ...
      sprintf('signal=bsxfun(@%s, %s_s, signal); %% operation: %s (orthogonal axes)\n', op(2:end), tmp_a, op) ];
  else
    c.Expression = [ c.Expression, ...
      sprintf('signal=feval(@%s, %s_s, signal%s); %% operation: %s\n', op, tmp_a, v, op) ];
  end
  c.Eval=char(c); % trigger new Eval

elseif isFa && ischar(b)
  c.Expression = [ c.Expression sprintf('\nsignal=%s(signal,%s%s);', op, b, v) ];
elseif isFb && ischar(a)
  c.Expression = [ c.Expression sprintf('\nsignal=%s(%s,signal%s);', op, a, v) ];
elseif isFa && ~isempty(inputname(2)) && ~isempty(whos('global',inputname(2)))
  c.Expression = [ c.Expression sprintf('\nglobal %s; signal=%s(%s,signal%s);', inputname(2), op, inputname(2), v) ];
elseif isFb && ~isempty(inputname(1)) && ~isempty(whos('global',inputname(1)))
  c.Expression = [ c.Expression sprintf('\nglobal %s; signal=%s(signal,%s%v);', inputname(1), op, inputname(1), v) ];
elseif   isFa && isnumeric(b) && isnumeric(b)
  c.Expression = [ c.Expression sprintf('\nsignal=%s(signal,%s%s);', op, mat2str(double(b)), v) ];
elseif isFb && isnumeric(a) && isnumeric(a)
  c.Expression = [ c.Expression sprintf('\nsignal=%s(%s,signal%v);', op, mat2str(double(a)), v) ];
else
  error(['iFunc:' mfilename ], [mfilename ': can not apply operator ' op ' between class ' class(a) ' and class ' ...
      class(b) '.' ]);
end

