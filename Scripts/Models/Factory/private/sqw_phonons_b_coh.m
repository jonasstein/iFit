function b_coh = sqw_phonons_b_coh(chemical_elements)

chemical_elements = cellstr(chemical_elements);
b_coh = zeros(size(chemical_elements));

% get all scattering lengths
[elements,b_cohs] = sqw_phonons_b_cohs;

% search for the elements from the formula
for index=1:numel(chemical_elements)
  index_element = find(strcmpi(chemical_elements{index}, elements));
  if numel(index_element) == 1
    b_coh(index) = b_cohs(index_element);
  end
end

% ------------------------------------------------------------------------------
function [elements,b_cohs] = sqw_phonons_b_cohs
% neutron scattering length from https://www.ncnr.nist.gov/resources/n-lengths/list.html

elements ='H 1H  2H  3H  He  3He  4He  Li  6Li  7Li  Be  B  10B  11B  C  12C  13C  N  14N  15N  O  16O  17O  18O  F  Ne  20Ne  21Ne  22Ne  Na  Mg  24Mg  25Mg  26Mg  Al  Si  28Si  29Si  30Si  P  S  32S  33S  34S  36S  Cl  35Cl  37Cl  Ar  36Ar  38Ar  40Ar  K  39K  40K  41K  Ca  40Ca  42Ca  43Ca  44Ca  46Ca  48Ca  Sc  Ti  46Ti  47Ti  48Ti  49Ti  50Ti  V  50V  51V  Cr  50Cr  52Cr  53Cr  54Cr  Mn  Fe  54Fe  56Fe  57Fe  58Fe  Co  Ni  58Ni  60Ni  61Ni  62Ni  64Ni  Cu  63Cu  65Cu  Zn  64Zn  66Zn  67Zn  68Zn  70Zn  Ga  69Ga  71Ga  Ge  70Ge  72Ge  73Ge  74Ge  76Ge  As  Se  74Se  76Se  77Se  78Se  80Se  82Se  Br  79Br  81Br  Kr  78Kr  80Kr  82Kr  83Kr  84Kr  86Kr  Rb  85Rb  87Rb  Sr  84Sr  86Sr  87Sr  88Sr  Y  Zr  90Zr  91Zr  92Zr  94Zr  96Zr  Nb  Mo  92Mo  94Mo  95Mo  96Mo  97Mo  98Mo  100Mo  Tc  Ru  96Ru  98Ru  99Ru  100Ru  101Ru  102Ru  104Ru  Rh  Pd  102Pd  104Pd  105Pd  106Pd  108Pd  110Pd  Ag  107Ag  109Ag  Cd  106Cd  108Cd  110Cd  111Cd  112Cd  113Cd  114Cd  116Cd  In  113In  115In  Sn  112Sn  114Sn  115Sn  116Sn  117Sn  118Sn  119Sn  120Sn  122Sn  124Sn  Sb  121Sb  123Sb  Te  120Te  122Te  123Te  124Te  125Te  126Te  128Te  130Te  I  Xe  124Xe  126Xe  128Xe  129Xe  130Xe  131Xe  132Xe  134Xe  136Xe  Cs  Ba  130Ba  132Ba  134Ba  135Ba  136Ba  137Ba  138Ba  La  138La  139La  Ce  136Ce  138Ce  140Ce  142Ce  Pr  Nd  142Nd  143Nd  144Nd  145Nd  146Nd  148Nd  150Nd  Pm  Sm  144Sm  147Sm  148Sm  149Sm  150Sm  152Sm  154Sm  Eu  151Eu  153Eu  Gd  152Gd  154Gd  155Gd  156Gd  157Gd  158Gd  160Gd  Tb  Dy  156Dy  158Dy  160Dy  161Dy  162Dy  163Dy  164Dy  Ho  Er  162Er  164Er  166Er  167Er  168Er  170Er  Tm  Yb  168Yb  170Yb  171Yb  172Yb  173Yb  174Yb  176Yb  Lu  175Lu  176Lu  Hf  174Hf  176Hf  177Hf  178Hf  179Hf  180Hf  Ta  180Ta  181Ta  W  180W  182W  183W  184W  186W  Re  185Re  187Re  Os  184Os  186Os  187Os  188Os  189Os  190Os  192Os  Ir  191Ir  193Ir  Pt  190Pt  192Pt  194Pt  195Pt  196Pt  198Pt  Au  Hg  196Hg  198Hg  199Hg  200Hg  201Hg  202Hg  204Hg  Tl  203Tl  205Tl  Pb  204Pb  206Pb  207Pb  208Pb  Bi  Po  At  Rn  Fr  Ra  Ac  Th  Pa  U  233U  234U  235U  238U  Np  Pu  238Pu  239Pu  240Pu  242Pu  Am  Cm  244Cm  246Cm  248Cm';
elements = textscan(elements, '%s','Delimiter',' ');
elements = elements{1};
elements = elements(~cellfun(@isempty, elements));

b_cohs =[ -3.7390  -3.7406  6.671  4.792  3.26 5.74-1.483i  3.26  -1.90  2.00-0.261i  -2.22  7.79  5.30-0.213i  -0.1-1.066i  6.65  6.6460  6.6511  6.19  9.36  9.37  6.44  5.803  5.803  5.78  5.84  5.654  4.566  4.631  6.66  3.87  3.63  5.375  5.66  3.62  4.89  3.449  4.1491  4.107  4.70  4.58  5.13  2.847  2.804  4.74  3.48  3. 9.5770  11.65  3.08  1.909  24.90  3.5  1.830  3.67  3.74  3. 2.69  4.70  4.80  3.36  -1.56  1.42  3.6  0.39  12.29  -3.438  4.93  3.63  -6.08  1.04  6.18  -0.3824  7.6  -0.402  3.635  -4.50  4.920  -4.20  4.55  -3.73  9.45  4.2  9.94  2.3  15. 2.49  10.3  14.4  2.8  7.60  -8.7  -0.37  7.718  6.43  10.61  5.680  5.22  5.97  7.56  6.03  6. 7.288  7.88  6.40  8.185  10.0  8.51  5.02  7.58  8.2  6.58  7.970  0.8  12.2  8.25  8.24  7.48  6.34  6.795  6.80  6.79  7.81  nan  nan  nan  nan  nan  8.1  7.09  7.03  7.23  7.02  7. 5.67  7.40  7.15  7.75  7.16  6.4  8.7  7.4  8.2  5.5  7.054  6.715  6.91  6.80  6.91  6.20  7.24  6.58  6.73  6.8  7.03  nan  nan  nan  nan  nan  nan  nan  5.88  5.91  7.7 7.7 5.5  6.4  4.1  7.7 5.922 7.555  4.165  4.87-0.70i  5. 5.4  5.9  6.5  6.4  -8.0-5.73i  7.5  6.3  4.065-0.0539i  5.39  4.01-0.0562i  6.225  6. 6.2  6. 5.93  6.48  6.07  6.12  6.49  5.74  5.97  5.57  5.71  5.38  5.80  5.3  3.8  -0.05-0.116i  7.96  5.02  5.56  5.89  6.02  5.28  4.92  nan  nan  nan  nan  nan  nan  nan  nan  nan  5.42  5.07  -3.6  7.8  5.7  4.67  4.91  6.83  4.84  8.24  8. 8.24  4.84  5.80  6.70  4.84  4.75  4.58  7.69  7.7  14. 2.8  14. 8.7  5.7  5.3  12.6  0.80-1.65i  -3. 14. -3. -19.2-11.7i  14. -5.0  9.3  7.22-1.26i  6.13-2.53i  8.22  6.5-13.82i  10. 10. 6.0-17.0i  6.3  -1.14-71.9i  9. 9.15  7.38  16.9-0.276i  6.1  6. 6.7  10.3  -1.4  5.0  49.4-0.79i  8.01  7.79  8.8  8.2  10.6  3.0  7.4  9.6  7.07  12.43  -4.07-0.62i  6.77  9.66  9.43  9.56  19.3  8.72  7.21  7.24  6.1-0.57i  7.7  10.9 6.61  0.8 5.9  7.46  13.2  6.91  7. 6.91  4.86  5. 6.97  6.53  7.48  -0.72  9.2  9.0  9.3  10.7  10. 11.6 10. 7.6  10.7  11.0  11.5  10.6  nan  nan  9.60  9.0  9.9  10.55  8.83  9.89  7.8  7.63  12.692  30.3 nan  16.9  nan  nan  nan  nan  8.776  6.99  9.52  9.405  9.90  9.22  9.28  9.50  8.532  nan  nan  nan  nan  10.0 nan  10.31  9.1  8.417  10.1  12.4  10.47  8.402  10.55  nan  14.1  7.7  3.5  8.1  8.3  nan  9.5  9.3  7.7 ];
