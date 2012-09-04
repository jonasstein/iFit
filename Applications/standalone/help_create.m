function make(target)


% location of the iFit directory
cd(ifitpath); p=pwd;  % get fully qualified path for ifitpath
% location of the make script
m=fullfile(p, 'Applications', 'standalone');

if nargin == 0
  target = '';
end
if isempty(target)
  [dummy, vers] = version(iData); % get version number
  target = fullfile(ifitpath, '..', [ 'ifit-' vers '-' lower(computer) ]);
end
dummy=rmdir(target, 's'); 
mkdir(target);              % remove previous package
cd (target); target = pwd;  % get fully qualified path for target

% create the help pages
create_help(ifitpath);

% activate some standalone only scripts (which are in principle forbiden by Matlab Compiler)
cd(m);
movefile('edit.m.org',     'edit.m');
movefile('web.m.org',      'web.m');
movefile('inspect.m.org',  'inspect.m');
movefile('propedit.m.org', 'propedit.m');

disp(  'Creating the deployed version');
disp([ 'from ' p ]) 
disp([ 'into ' target ])

cd   (target);
disp([ 'mcc -m ifit -a ', p ])
mcc('-m', 'ifit', '-a', p);

% tuning the standalone
movefile('ifit', 'run_ifit');
delete('run_ifit.sh');
copyfile([ m filesep 'ifit' ],       target)
copyfile([ p filesep 'README.txt' ], target)
copyfile([ p filesep 'COPYING' ],    target)

% restore initial state
cd(m)
movefile('edit.m',     'edit.m.org');
movefile('web.m',      'web.m.org');
movefile('inspect.m',  'inspect.m.org');
movefile('propedit.m', 'propedit.m.org');

% create launchers for models, operators and commands
create_launchers_models(   fullfile(target, 'models'));
create_launchers_operators(fullfile(target, 'operators'));
create_launchers_commands( fullfile(target, 'commands'));

disp('DONE');

% ------------------------------------------------------------------------------

% create the help strings, to store as .txt files available for 'help' and 'doc'
function create_help(pw)
  to_parse = {'Objects/@iData','Objects/@iFunc','Libraries/Loaders','Libraries/Models','Libraries/Optimizers','Scripts/load','Applications/standalone','Tests'};
  disp('Creating help pages for deployed version');
  for index=1:length(to_parse)
    d = to_parse{index};
    disp(d);
    cd ([ pw filesep d ]);
    c = dir('*.m');       % get the contents m files
    for fun= 1:length(c); % scan functions
      [p,f,e] = fileparts(c(fun).name);
      h       = help([ d filesep f '.m' ]);
      fid     = fopen([ f '.txt' ],'w+');
      fprintf(fid,'File %s%s%s\n\n', d, filesep, c(fun).name);
      fprintf(fid,'%s\n', h);
      fclose(fid);
    end
  end
  
function create_launchers_models(target)
  % create launchers for Linux (OpenDesktop .desktop files) and Windows (.bat files)
  
  mkdir(target);
  
  % Model list (predefined iFunc)
  d = dir([ fileparts(which('gauss')) ]);
  criteria = []; 
  for index=1:length(d)
    this = d(index);
    try
      [dummy, method, ext] = fileparts(this.name);
      options = feval(method,'identify');
      if isa(options, 'iFunc') && strcmp(ext, '.m')
        launcher_write(target, method);
      end
    end
  end % for

function create_launchers_commands(target)
  % Commands
  mkdir(target);
  
  d = { 'caxis', 'char', 'colormap', 'contour', 'copyobj', 'doc', 'edit', 'feval', 'get', 'image', 'load', 'mesh', 'plot', 'plot3', 'scatter3', 'slice', 'subplot', 'surf', 'surfc', 'surfl', 'waterfall' };
  for index=1:length(d)
    launcher_write(target, d{index});
  end
  
function create_launchers_operators(target)
  % save the final object 'ans'
  mkdir(target);
  
  d = { 'abs', 'acos', 'acosh', 'asin', 'asinh', 'atan', 'atanh', 'camproj', 'cat', 'ceil', 'combine', 'conj', 'conv', 'convn', 'cos', 'cosh', 'ctranspose', 'cumsum', 'cumtrapz', 'del2', 'diff', 'dog', 'eq', 'exp', 'fft', 'fits', 'fliplr', 'flipud', 'floor', 'full', 'ge', 'gradient', 'gt', 'hist', 'ifft', 'imag', 'interp', 'intersect', 'isempty', 'le', 'linspace', 'log', 'log10', 'logspace', 'lt', 'max', 'mean', 'median', 'minus', 'mtimes', 'ndims', 'ne', 'norm', 'not', 'peaks', 'permute', 'plus', 'power', 'prod', 'rdivide', 'real', 'round', 'sign', 'sin', 'sinh', 'sqrt', 'std', 'sum', 'tan', 'tanh', 'times', 'transpose', 'trapz', 'uminus', 'union', 'xcorr' };
  for index=1:length(d)
    launcher_write(target, d{index});
  end
  
