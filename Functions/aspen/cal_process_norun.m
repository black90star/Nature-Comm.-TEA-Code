function [h] = cal_process_norun(Efficiency, CurrentDensity, potential, materials, components, input, process, h)
%% Techno-economic Analysis for Electrochemical Processes
% cal_process.m
%
% calculate the process flowsheet with generated structure
%
%
% 2018 Jonggeol Na
% -------------------------------------------------------------------------
% first version 7/20/2018
% ------------------------------input--------------------------------------
% materials: materials.mat is the overall database prepared by Jonggeol Na
% components.cathode: 1xn (1-18)   ex) [1 3 6] --> hydrogen+CO+methane
% components.anode  : 1xm (19-29)  ex) [19 24] --> O2 + FDCA
% structure: generated by gen_process
%
% 1	hydrogen
% 2	syngas
% 3	carbon monoxide
% 4	formate
% 5	methanol
% 6	methane
% 7	ethylene
% 8	ethanol
% 9	n-propanol
% 10	acetaldehyde
% 11	glyoxal
% 12	hydroxyacetone (acetol)
% 13	acetone
% 14	acetate
% 15	Allyl alcohol
% 16	glycolaldehyde
% 17	propionaldehyde
% 18	ethylene glycol
%
% 19	oxygen
% 20	acetic acid/acetate
% 21	benzoic acid
% 22	2-furoic acid (from furfural)
% 23	2-furoic acid (from furfuryl alcohol)
% 24	2,5-furandicarboxylic acid
% 25	4-methoxybenzaldehyde
% 26	acetophenone
% 27	acetone
% 28	nitrogen + CO2
% 29	phenoxyacetic acid
% 30	formate
% ------------------------------output-------------------------------------
% Result:
%
% -------------------------------------------------------------------------


[ProductionRate,Area]=electrolyzer(Efficiency,...
    CurrentDensity, potential, materials, components, input);
%% Aspen input
% INL:EL, INL:CH (calculated by z,FE,input.CO2, CD,...)
% SPL:EL

%% Define Inlet streams
% INL:CO2
h.Tree.FindNode('\Data\Streams\INL:CO2\Input\FLOW\MIXED\CARBO-02').value...Flowrate [kmol/s]
    = input.CO2/1000;
h.Tree.FindNode("\Data\Streams\INL:CO2\Input\TEMP\MIXED").value...         Temperature [K]
    = input.temperature;
h.Tree.FindNode("\Data\Streams\INL:CO2\Input\PRES\MIXED").value...         Pressure [Pa]
    = input.pressure;
% INL:CO2 --> Design spec for 90% conversion at electrolyzer
h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSCO2\Input\VARYSTREAM").value= 'INL:CO2';
h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSCO2\Input\EXPR2").value= input.CO2/1000;
h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSCO2\Input\TOL").value= input.CO2/1000/1000;
h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSCO2\Input\UPPER").value = input.CO2/1000;


% INL:EL --> should be changed
h.Tree.FindNode('\Data\Streams\INL:EL\Input\FLOW\MIXED\WATER').value...    Flowrate [kmol/s]
    = input.WATER/1000; % electrolyte
h.Tree.FindNode('\Data\Streams\INL:EL\Input\FLOW\MIXED\H+').value...       Flowrate [kmol/s]
    = input.WATER*1.585e-7/55.5/1000*100; % electrolyte (pH 6.8) 근데 수렴이 잘 안되고 사실 의미 없으므로 이 값에 100배를 해준다
h.Tree.FindNode("\Data\Streams\INL:EL\Input\TEMP\MIXED").value...          Temperature [K]
    = input.temperature;
h.Tree.FindNode("\Data\Streams\INL:EL\Input\PRES\MIXED").value...          Pressure [Pa]
    = input.pressure;
% INL:EL --> Design spec for 33 mM CO2
h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSEL\Input\VARYSTREAM").value= 'INL:EL';
% if HER then water flowrate is determined by OER required water
if length(components.cathode) == 1
    h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSEL\Input\EXPR1").value = 'CO2' ;
    h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSEL\Input\EXPR2").value= input.WATER; % 이부분만 mol/sec 되어 있음
    h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSEL\Input\TOL").value= input.WATER/1000;
    h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSEL\Input\UPPER").value = input.WATER;
    h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSEL\Input\FVN_COMPONEN\CO2").value = 'WATER';
    h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSEL\Input\FVN_STREAM\CO2").value = 'S7';
end

% INL:CH --> should be changed
if process.order.in(3) + process.order.out(3) ~= 0
    for i=2:length(components.anode) % Not for Oxygen        
        temp =strjoin(["\Data\Streams\INL:CH\Input\FLOW\MIXED\",materials.raw_materials(components.anode(i))],'');
        h.Tree.FindNode(temp).value...                                         Flowrate [kmol/s]
            = input.CH/1000;                                                   %marginal supply
        h.Tree.FindNode("\Data\Streams\INL:CH\Input\TEMP\MIXED").value...      Temperature [K]
            = input.temperature;
        h.Tree.FindNode("\Data\Streams\INL:CH\Input\PRES\MIXED").value...      Pressure [Pa]
            = input.pressure;
        if components.anode(2) ~= 20 % Not for H2O2
            % INL:CH --> Design spec for 90% conversion at electrolyzer
            h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSCH\Input\VARYSTREAM").value= 'INL:CH';
            h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSCH\Input\EXPR2").value= input.CH/1000;
            h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSCH\Input\TOL").value= input.CH/1000/1000;
            h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSCH\Input\UPPER").value = input.CH/1000;
            h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSCH\Input\FVN_COMPONEN\CH").value =  char(materials.raw_materials(components.anode(i)));
            h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSCH\Input\VARYCOMPONEN").value =   char(materials.raw_materials(components.anode(i)));
        else
            haha = h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec");
            try
                haha.Elements.Remove('DSCH');
            catch
            end
            temp =strjoin(["\Data\Streams\INL:CH\Input\FLOW\MIXED\",materials.raw_materials(components.anode(i))],'');
            h.Tree.FindNode(temp).value...                                         Flowrate [kmol/s]
                = input.CH/1000/1000;
        end
        
    end
else
    haha = h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec");
    try
        haha.Elements.Remove('DSCH');
    catch
    end
end

%% Define reactors (electrochemical reaction)
% Cathode (RXN:C-3)

h.Tree.FindNode("\Data\Blocks\RXN:C-3\Input\TEMP").value = input.temperature;% [K]
h.Tree.FindNode("\Data\Blocks\RXN:C-3\Input\PRES").value = input.pressure;   % [Pa]
% -Conversion or Reaction Extent [kmol/s]
for i = 1:length(components.cathode)
    temp = ['\Data\Blocks\RXN:C-3\Input\EXTENT\',num2str(components.cathode(i))];
    h.Tree.FindNode(temp).value = ProductionRate.cathode(i)/1000;                  %[kmol/sec]
end

% Anode (RXN:A-2)
h.Tree.FindNode("\Data\Blocks\RXN:A-2\Input\TEMP").value = input.temperature;% [K]
h.Tree.FindNode("\Data\Blocks\RXN:A-2\Input\PRES").value = input.pressure;   % [Pa]
for i = 1:length(components.anode)
    temp = ['\Data\Blocks\RXN:A-2\Input\EXTENT\',num2str(components.anode(i)-18)];
    h.Tree.FindNode(temp).value = ProductionRate.anode(i)/1000;                  %[kmol/sec]
end


%% Define separators
% [10 11 12 13 14 15]
% SEP:C:GL

% FLASH2
if process.order.in(10) + process.order.out(10) ~= 0 && strcmp(process.types{10},'block')
    h.Tree.FindNode("\Data\Blocks\SEP:C:GL\Input\TEMP").value = input.temperature;% [K]
    h.Tree.FindNode("\Data\Blocks\SEP:C:GL\Input\PRES").value = input.pressure;   % [Pa]
end


% SEP:C:GG
%PSA
if process.order.in(11) + process.order.out(11) ~= 0 && strcmp(process.types{11},'block')
    %CO2 Absorb
    if length(components.cathode) == 2 &&  length(components.anode) == 2
        temp_materials = {'HYDRO-01';'OXYGE-01';'H+';'WATER';'CARBO-02';'METHY-02';char(materials.ASPEN_NAME(components.cathode(2))); char(materials.ASPEN_NAME(components.anode(2)));  char(materials.raw_materials(components.anode(2)))};
    elseif length(components.cathode) == 1 &&  length(components.anode) == 2
        temp_materials = {'HYDRO-01';'OXYGE-01';'H+';'WATER';'CARBO-02';'METHY-02'; char(materials.ASPEN_NAME(components.anode(2)));  char(materials.raw_materials(components.anode(2)))};
    elseif length(components.cathode) == 2 &&  length(components.anode) == 1
        temp_materials = {'HYDRO-01';'OXYGE-01';'H+';'WATER';'CARBO-02';'METHY-02';char(materials.ASPEN_NAME(components.cathode(2)))};
    elseif length(components.cathode) == 1 &&  length(components.anode) == 1
        temp_materials = {'HYDRO-01';'OXYGE-01';'H+';'WATER';'CARBO-02';'METHY-02'};
    end
    for k = 1:length(temp_materials)
        temp=strjoin(string(['\Data\Blocks\',process.names{11},'\Input\FRACS\S11-16\MIXED\',temp_materials{k}]),'');
        h.Tree.FindNode(temp).value =0;
    end
    temp=strjoin(string(['\Data\Blocks\',process.names{11},'\Input\FRACS\S11-16\MIXED\CARBO-02']),'');
    h.Tree.FindNode(temp).value = 1;
    temp=strjoin(string(['\Data\Blocks\',process.names{11},'\Input\FRACS\S11-16\MIXED\WATER']),'');
    h.Tree.FindNode(temp).value = 1;
    
    %     h.Tree.FindNode("\Data\Blocks\SEP:C:GG\Input\VFRAC\S11-CC2").value = 1;
    if length(components.cathode)==2
        if strcmp(string(materials.phase(components.cathode(2))), 'g') % TYPE 1 %PSA
            % catalyst weight (V * D =10)
            
            % COMP:C, COMP:C2 27.3 bar
            h.Tree.FindNode("\Data\Blocks\COMP:C\Input\TYPE").value = 'ISENTROPIC';
            h.Tree.FindNode("\Data\Blocks\COMP:C\Input\OPT_SPEC").value = 'PRES';
            h.Tree.FindNode("\Data\Blocks\COMP:C2\Input\TYPE").value = 'ISENTROPIC';
            h.Tree.FindNode("\Data\Blocks\COMP:C2\Input\OPT_SPEC").value = 'PRES';
            
            h.Tree.FindNode("\Data\Blocks\COMP:C\Input\PRES").value = 27.3*101325;
            h.Tree.FindNode("\Data\Blocks\COMP:C2\Input\PRES").value = 27.3*101325;
            
            % HEAT:C, HEAT:C2, HEAT:C3, HEAT:C4 pseudo heater input.temperature, input.pressure
            h.Tree.FindNode("\Data\Blocks\HEAT:C\Input\SPEC_OPT").value = 'TP';
            h.Tree.FindNode("\Data\Blocks\HEAT:C2\Input\SPEC_OPT").value = 'TP';
            h.Tree.FindNode("\Data\Blocks\HEAT:C3\Input\SPEC_OPT").value = 'TP';
            h.Tree.FindNode("\Data\Blocks\HEAT:C4\Input\SPEC_OPT").value = 'TP';
            h.Tree.FindNode("\Data\Blocks\HEAT:C\Input\TEMP").value = input.temperature;  %[K]
            h.Tree.FindNode("\Data\Blocks\HEAT:C2\Input\TEMP").value = input.temperature; %[K]
            h.Tree.FindNode("\Data\Blocks\HEAT:C3\Input\TEMP").value = input.temperature;  %[K]
            h.Tree.FindNode("\Data\Blocks\HEAT:C4\Input\TEMP").value = input.temperature; %[K]
            h.Tree.FindNode("\Data\Blocks\HEAT:C\Input\PRES").value = input.pressure;  %[Pa]
            h.Tree.FindNode("\Data\Blocks\HEAT:C2\Input\PRES").value = input.pressure; %[Pa]
            h.Tree.FindNode("\Data\Blocks\HEAT:C3\Input\PRES").value = 0;  %[Pa]
            h.Tree.FindNode("\Data\Blocks\HEAT:C4\Input\PRES").value = 0; %[Pa]
            
            % Maxiter 1000
            % recycle stream initialization & Shadow Stream
            h.Tree.FindNode("\Data\Streams\SHC3-PC1\Input\TEMP\MIXED").value = input.temperature;
            h.Tree.FindNode("\Data\Streams\SHC3-PC1\Input\PRES\MIXED").value = 27.3*101325;
            h.Tree.FindNode("\Data\Streams\SHC3-PC1\Input\FLOW\MIXED\HYDRO-01").value = 0.01; %[kmol/sec]
            
            h.Tree.FindNode("\Data\Streams\SS1-PC2\Input\TEMP\MIXED").value = input.temperature;
            h.Tree.FindNode("\Data\Streams\SS1-PC2\Input\PRES\MIXED").value = input.pressure;
            h.Tree.FindNode("\Data\Streams\SS1-PC2\Input\FLOW\MIXED\HYDRO-01").value = 0.0000001; %[kmol/sec]
            
            
            % Design spec
            h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSGN:C\Input\FVN_STREAM\PROD").value = 'SPC1-H2';
            h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSGN:C\Input\FVN_COMPONEN\PROD").value = char(materials.ASPEN_NAME(components.cathode(2)));
            h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSGN:C\Input\FVN_STREAM\REC").value = 'SHC3-PC1';
            h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSGN:C\Input\FVN_COMPONEN\REC").value = char(materials.ASPEN_NAME(components.cathode(2)));
            h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSGN:C\Input\FVN_STREAM\IN").value = 'SHC4-PC1';
            h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSGN:C\Input\FVN_COMPONEN\IN").value = char(materials.ASPEN_NAME(components.cathode(2)));
            h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSGN:C\Input\VARYBLOCK").value = 'PSA1:C';
            h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec\DSGN:C\Input\VARYVARIABLE").value = 'V';
            
            % Transfer
            h.Tree.FindNode("\Data\Flowsheeting Options\Transfer\TRAN:C\Input\EQBLOCK").value = 'PSA1:C';
            h.Tree.FindNode("\Data\Flowsheeting Options\Transfer\TRAN:C\Input\EQVARIABLE").value = 'V';
            h.Tree.FindNode("\Data\Flowsheeting Options\Transfer\TRAN:C\Input\VARYBLOCK\#0").value = 'PSA2:C';
            h.Tree.FindNode("\Data\Flowsheeting Options\Transfer\TRAN:C\Input\VARYVARIABLE\#0").value = 'V';
        else
            haha = h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec");
            try
                haha.Elements.Remove('DSGN:C');
            catch
            end
            haha = h.Tree.FindNode("\Data\Flowsheeting Options\Transfer");
            try
                haha.Elements.Remove('TRAN:C');
            catch
            end
        end
    else
        haha = h.Tree.FindNode("\Data\Flowsheeting Options\Design-Spec");
        try
            haha.Elements.Remove('DSGN:C');
        catch
        end
        haha = h.Tree.FindNode("\Data\Flowsheeting Options\Transfer");
        try
            haha.Elements.Remove('TRAN:C');
        catch
        end
    end
    
end

% SEP:C:LL

if process.order.in(12) + process.order.out(12) ~= 0 && strcmp(process.types{12},'block')
    if materials.type(components.cathode(2)) == 1 % TYPE 1
        if components.cathode(2) == 5 ||  components.cathode(2) == 10 || components.cathode(2) == 13  % only for methanol
            %Radfrac
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_STREAM\TOTAL").value = 'S10-12';
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_VARIABLE\TOTAL").value = 'MOLE-FLOW';
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_STREAM\PROD").value = 'S10-12';
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_COMPONEN\PROD").value = char(materials.ASPEN_NAME(components.cathode(2)));
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_BLOCK\DF").value = 'SEP:C:LL';
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_VARIABLE\DF").value = 'D:F';
            
            h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\NSTAGE").value = 10;
            h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\D:F").value=0.5;
            h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\CONDENSER").value = 'PARTIAL-V';
            h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\BASIS_RR").value = 2;
            h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\FEED_STAGE\S10-12").value = 5;
            h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\PRES1").value = 101325;
            
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FORTRAN_EXEC\#1").value ='      DF = (PROD)/TOTAL*1.1      ';
        else
        %Distl
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_STREAM\TOTAL").value = 'S10-12';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_VARIABLE\TOTAL").value = 'MOLE-FLOW';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_STREAM\PROD").value = 'S10-12';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_COMPONEN\PROD").value = char(materials.ASPEN_NAME(components.cathode(2)));
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_BLOCK\DF").value = 'SEP:C:LL';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_VARIABLE\DF").value = 'D:F';
        
        h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\NSTAGE").value = 10;
        h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\FEED_LOC").value = 5;
        h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\RR").value = 2;
        h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\FEED_LOC").value = 5;
        h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\D_F").value = 0.5;
        h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\COND_TYPE").value = 'PARTIAL';
        h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\PTOP").value = 101325;
        h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\PBOT").value = 101325;
        h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\MAXIT").value = 500;
        h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\FLASH_MAXIT").value = 2000;
        end
        
    end
    if materials.type(components.cathode(2)) == 2 % TYPE 2
        %SEP
        if length(components.cathode) == 2 &&  length(components.anode) == 2
            temp_materials = {'HYDRO-01';'OXYGE-01';'H+';'WATER';'CARBO-02';'METHY-02';char(materials.ASPEN_NAME(components.cathode(2))); char(materials.ASPEN_NAME(components.anode(2)));  char(materials.raw_materials(components.anode(2)))};
        elseif length(components.cathode) == 1 &&  length(components.anode) == 2
            temp_materials = {'HYDRO-01';'OXYGE-01';'H+';'WATER';'CARBO-02';'METHY-02'; char(materials.ASPEN_NAME(components.anode(2)));  char(materials.raw_materials(components.anode(2)))};
        elseif length(components.cathode) == 2 &&  length(components.anode) == 1
            temp_materials = {'HYDRO-01';'OXYGE-01';'H+';'WATER';'CARBO-02';'METHY-02';char(materials.ASPEN_NAME(components.cathode(2)))};
        elseif length(components.cathode) == 1 &&  length(components.anode) == 1
            temp_materials = {'HYDRO-01';'OXYGE-01';'H+';'WATER';'CARBO-02';'METHY-02'};
        end
        for k = 1:length(temp_materials)
            temp=strjoin(string(['\Data\Blocks\SEP:C:EX\Input\FRACS\SEX-12\MIXED\',temp_materials{k}]),'');
            h.Tree.FindNode(temp).value = 0;
        end
        temp=strjoin(string(['\Data\Blocks\SEP:C:EX\Input\FRACS\SEX-12\MIXED\',materials.ASPEN_NAME(components.cathode(2))]),'');
        h.Tree.FindNode(temp).value = 0.9;
        temp=['\Data\Blocks\SEP:C:EX\Input\FRACS\SEX-12\MIXED\METHY-02'];
        h.Tree.FindNode(temp).value = 1;
        
        % Extraction solvent
        h.Tree.FindNode("\Data\Streams\SEX:C\Input\TEMP\MIXED").value...      Temperature [K]
            = input.temperature;
        h.Tree.FindNode("\Data\Streams\SEX:C\Input\PRES\MIXED").value...      Pressure [Pa]
            = input.pressure;
        h.Tree.FindNode('\Data\Streams\SEX:C\Input\FLOW\MIXED\METHY-02').value...Flowrate [kmol/s]
            = input.CO2/5000;
        
        %Distl
        %CATHODE
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_STREAM\TOTAL").value = 'SEX-12';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_VARIABLE\TOTAL").value = 'MOLE-FLOW';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_STREAM\PROD").value = 'SEX-12';
        
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_BLOCK\DF").value = 'SEP:C:LL';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_VARIABLE\DF").value = 'D:F';
        if materials.dist2(components.cathode(2)) == 0 % dist2 == 0 (product is lighter than MTBE)
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_COMPONEN\PROD").value = char(materials.ASPEN_NAME(components.cathode(2)));
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FORTRAN_EXEC\#1").value ='      DF = (PROD)/TOTAL      ';
        else
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FVN_COMPONEN\PROD").value = 'METHY-02';
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:C\Input\FORTRAN_EXEC\#1").value ='      DF = (PROD)/TOTAL      ';
        end
        h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\NSTAGE").value = 10;
        h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\FEED_LOC").value = 5;
        h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\RR").value = 2;
        h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\FEED_LOC").value = 5;
        h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\D_F").value = 0.5;
        h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\COND_TYPE").value = 'TOTAL';
        h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\PTOP").value = 101325;
        h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\PBOT").value = 101325;
        h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\MAXIT").value = 500;
        h.Tree.FindNode("\Data\Blocks\SEP:C:LL\Input\FLASH_MAXIT").value = 2000;
    end
    
else
    haha = h.Tree.FindNode("\Data\Flowsheeting Options\Calculator");
    try
        haha.Elements.Remove('CALC:C');
    catch
    end
    
end




% SEP:A:GL

% FLASH2
if process.order.in(13) + process.order.out(13) ~= 0 && strcmp(process.types{13},'block')
    h.Tree.FindNode("\Data\Blocks\SEP:A:GL\Input\TEMP").value = input.temperature;% [K]
    h.Tree.FindNode("\Data\Blocks\SEP:A:GL\Input\PRES").value = input.pressure;   % [Pa]
end

% SEP:A:GG
if process.order.in(14) + process.order.out(14) ~= 0 && strcmp(process.types{14},'block')
    j=find(process.structure(14,:));
    if j == [16 27]
        
        if length(components.cathode) == 2 &&  length(components.anode) == 2
            temp_materials = {'HYDRO-01';'OXYGE-01';'H+';'WATER';'CARBO-02';'METHY-02';char(materials.ASPEN_NAME(components.cathode(2))); char(materials.ASPEN_NAME(components.anode(2)));  char(materials.raw_materials(components.anode(2)))};
        elseif length(components.cathode) == 1 &&  length(components.anode) == 2
            temp_materials = {'HYDRO-01';'OXYGE-01';'H+';'WATER';'CARBO-02';'METHY-02'; char(materials.ASPEN_NAME(components.anode(2)));  char(materials.raw_materials(components.anode(2)))};
        elseif length(components.cathode) == 2 &&  length(components.anode) == 1
            temp_materials = {'HYDRO-01';'OXYGE-01';'H+';'WATER';'CARBO-02';'METHY-02';char(materials.ASPEN_NAME(components.cathode(2)))};
        elseif length(components.cathode) == 1 &&  length(components.anode) == 1
            temp_materials = {'HYDRO-01';'OXYGE-01';'H+';'WATER';'CARBO-02';'METHY-02'};
        end
        for k = 1:length(temp_materials)
            temp=strjoin(string(['\Data\Blocks\',process.names{14},'\Input\FRACS\OUT:A:G\MIXED\',temp_materials{k}]),'');
            h.Tree.FindNode(temp).value =0;
        end
        temp=strjoin(string(['\Data\Blocks\',process.names{14},'\Input\FRACS\OUT:A:G\MIXED\NITRO-01']),'');
        h.Tree.FindNode(temp).value = 0.9;
        temp=strjoin(string(['\Data\Blocks\',process.names{14},'\Input\FRACS\OUT:A:G\MIXED\OXYGE-01']),'');
        h.Tree.FindNode(temp).value = 0.9;
        
        
        
    end
end

% SEP:A:LL
if process.order.in(15) + process.order.out(15) ~= 0 && strcmp(process.types{15},'block')
    if materials.type(components.anode(2)) == 1 % TYPE 1
        %Distl
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_STREAM\TOTAL").value = 'S13-15';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_VARIABLE\TOTAL").value = 'MOLE-FLOW';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_STREAM\PROD").value = 'S13-15';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_COMPONEN\PROD").value = char(materials.ASPEN_NAME(components.anode(2)));
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_BLOCK\DF").value = 'SEP:A:LL';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_VARIABLE\DF").value = 'D:F';
        
        h.Tree.FindNode("\Data\Blocks\SEP:A:LL\Input\NSTAGE").value = 10;
        h.Tree.FindNode("\Data\Blocks\SEP:A:LL\Input\FEED_LOC").value = 5;
        h.Tree.FindNode("\Data\Blocks\SEP:A:LL\Input\RR").value = 2;
        h.Tree.FindNode("\Data\Blocks\SEP:A:LL\Input\FEED_LOC").value = 5;
        h.Tree.FindNode("\Data\Blocks\SEP:A:LL\Input\D_F").value = 0.5;
        h.Tree.FindNode("\Data\Blocks\SEP:A:LL\Input\COND_TYPE").value = 'PARTIAL';
        
        h.Tree.FindNode("\Data\Blocks\SEP:A:LL\Input\PTOP").value = 101325;
        h.Tree.FindNode("\Data\Blocks\SEP:A:LL\Input\PBOT").value = 101325;
        h.Tree.FindNode("\Data\Blocks\SEP:A:LL\Input\MAXIT").value = 500;
        h.Tree.FindNode("\Data\Blocks\SEP:A:LL\Input\FLASH_MAXIT").value = 2000;
    end
    if materials.type(components.anode(2)) == 2 % TYPE 2
        %SEP
        if length(components.cathode) == 2 &&  length(components.anode) == 2
            temp_materials = {'HYDRO-01';'OXYGE-01';'H+';'WATER';'CARBO-02';'METHY-02';char(materials.ASPEN_NAME(components.cathode(2))); char(materials.ASPEN_NAME(components.anode(2)));  char(materials.raw_materials(components.anode(2)))};
        elseif length(components.cathode) == 1 &&  length(components.anode) == 2
            temp_materials = {'HYDRO-01';'OXYGE-01';'H+';'WATER';'CARBO-02';'METHY-02'; char(materials.ASPEN_NAME(components.anode(2)));  char(materials.raw_materials(components.anode(2)))};
        elseif length(components.cathode) == 2 &&  length(components.anode) == 1
            temp_materials = {'HYDRO-01';'OXYGE-01';'H+';'WATER';'CARBO-02';'METHY-02';char(materials.ASPEN_NAME(components.cathode(2)))};
        elseif length(components.cathode) == 1 &&  length(components.anode) == 1
            temp_materials = {'HYDRO-01';'OXYGE-01';'H+';'WATER';'CARBO-02';'METHY-02'};
        end
        for k = 1:length(temp_materials)
            temp=strjoin(string(['\Data\Blocks\SEP:A:EX\Input\FRACS\SEX-15\MIXED\',temp_materials{k}]),'');
            h.Tree.FindNode(temp).value = 0;
        end
        temp=strjoin(string(['\Data\Blocks\SEP:A:EX\Input\FRACS\SEX-15\MIXED\',materials.ASPEN_NAME(components.anode(2))]),'');
        h.Tree.FindNode(temp).value = 0.9;
        temp=['\Data\Blocks\SEP:A:EX\Input\FRACS\SEX-15\MIXED\METHY-02'];
        h.Tree.FindNode(temp).value = 1;
        
        % Extraction solvent
        h.Tree.FindNode("\Data\Streams\SEX:A\Input\TEMP\MIXED").value...      Temperature [K]
            = input.temperature;
        h.Tree.FindNode("\Data\Streams\SEX:A\Input\PRES\MIXED").value...      Pressure [Pa]
            = input.pressure;
        h.Tree.FindNode('\Data\Streams\SEX:A\Input\FLOW\MIXED\METHY-02').value...Flowrate [kmol/s]
            = input.CO2/5000;
        
        %Distl
        %ANODE
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_STREAM\TOTAL").value = 'SEX-15';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_VARIABLE\TOTAL").value = 'MOLE-FLOW';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_STREAM\PROD").value = 'SEX-15';
        
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_BLOCK\DF").value = 'SEP:A:LL';
        h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_VARIABLE\DF").value = 'D:F';
        
        if materials.dist2(components.anode(2)) == 0 % dist2 == 0 (product is lighter than MTBE)
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_COMPONEN\PROD").value = char(materials.ASPEN_NAME(components.anode(2)));
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FORTRAN_EXEC\#1").value ='      DF = (PROD)/TOTAL      ';
        else
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FVN_COMPONEN\PROD").value = 'METHY-02';
            h.Tree.FindNode("\Data\Flowsheeting Options\Calculator\CALC:A\Input\FORTRAN_EXEC\#1").value ='      DF = (PROD)/TOTAL      ';
        end
        
        h.Tree.FindNode("\Data\Blocks\SEP:A:LL\Input\NSTAGE").value = 10;
        h.Tree.FindNode("\Data\Blocks\SEP:A:LL\Input\FEED_LOC").value = 5;
        h.Tree.FindNode("\Data\Blocks\SEP:A:LL\Input\RR").value = 2;
        h.Tree.FindNode("\Data\Blocks\SEP:A:LL\Input\FEED_LOC").value = 5;
        h.Tree.FindNode("\Data\Blocks\SEP:A:LL\Input\D_F").value = 0.5;
        h.Tree.FindNode("\Data\Blocks\SEP:A:LL\Input\COND_TYPE").value = 'TOTAL';
        
        h.Tree.FindNode("\Data\Blocks\SEP:A:LL\Input\PTOP").value = 101325;
        h.Tree.FindNode("\Data\Blocks\SEP:A:LL\Input\PBOT").value = 101325;
        h.Tree.FindNode("\Data\Blocks\SEP:A:LL\Input\MAXIT").value = 500;
        h.Tree.FindNode("\Data\Blocks\SEP:A:LL\Input\FLASH_MAXIT").value = 2000;
    end
else
    haha = h.Tree.FindNode("\Data\Flowsheeting Options\Calculator");
    try
        haha.Elements.Remove('CALC:A');
    catch
    end
end



%% Define split ratio
% 16,17,18,19,20 FSPLIT

% 'REC:CO2','REC:C:EL','REC:A:EL','REC:A:CH','REC:COP'
for i = [16 17 18 19 20]
    if process.order.in(i) + process.order.out(i) ~= 0 && strcmp(process.types{i},'block')
        j=find(process.structure(i,:));
        temp=strjoin(string(['\Data\Blocks\',process.names{i},'\Input\FRAC\S',num2str(i),'-',num2str(j(1))]),'');
        h.Tree.FindNode(temp).value...
            = input.Ratio(i-15);
    else
    end
end
% 뭔가의 문제로 co2 안들어가면 들어가라고
h.Tree.FindNode('\Data\Streams\INL:CO2\Input\FLOW\MIXED\CARBO-02').value...Flowrate [kmol/s]
    = input.CO2/1000;
% 뭔가의 문제로 co2 안들어가면 들어가라고
h.Tree.FindNode('\Data\Streams\INL:CO2\Input\FLOW\MIXED\CARBO-02').value...Flowrate [kmol/s]
    = input.CO2/1000;

if length(components.cathode) == 2
if components.cathode(2) == 10 ||13
    h.Tree.FindNode("\Data\Convergence\Conv-Options\Input\TOL").value = 1e-5;
end
end

% SPL:EL --> fixed by total INL:EL, EL:C, and EL:A
h.Tree.FindNode("\Data\Blocks\SPL:EL\Input\FRAC\EL:C").value...
    =0.5; % should be changed

%% Run the Aspen simulation
% h.Engine.Run2;
%% Initialize the Aspen simulation
% set(h, 'Visible', 0);
% h.Reinit ;
% fprintf(['Product.Cathode: ',char(materials.name(components.cathode(2))), ',  event occurs at: ',datestr(now),'\n']);set(h, 'Visible', 0);
% fprintf(['event occurs at: ',datestr(now),'\n']);set(h, 'Visible', 0);

% %% Convergence check
% ConvergenceState=h.Tree.FindNode("\Data\Results Summary\Run-Status\Output\UOSSTAT2").value;
