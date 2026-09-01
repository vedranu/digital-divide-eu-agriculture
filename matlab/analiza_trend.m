%% analiza_trend.m
% Dinamika infrastrukturnog sloja i digitalnih vještina 2019.-2025.
% (Tablica 4 u radu): pristup internetu kućanstava (ukupno i ruralno)
% te ruralne digitalne vještine, Hrvatska i EU-27.
%
% Ulaz (mapa ../data): isoc_ci_in_h.csv (puni Eurostat izvoz),
%                      isoc_digskills.csv (filtrirano: I_DSK2_BAB, PC_IND)
%
% Autori: Vedran Uroš, Sandra Mandinić, 2026.

clear; clc;
dataDir = fullfile(fileparts(mfilename('fullpath')), '..', 'data');
years  = [2019 2021 2023 2025];
geos   = ["EU27_2020", "HR"];

%% 1) Kućanstva s internetom (ukupno i ruralna), isoc_ci_in_h
R = readtable(fullfile(dataDir, 'isoc_ci_in_h.csv'), 'TextType', 'string', ...
    'VariableNamingRule', 'preserve');
R.Properties.VariableNames = matlab.lang.makeValidName(R.Properties.VariableNames);
R = R(R.unit == "PC_HH", :);

fprintf('%-46s %6d %6d %6d %6d\n', 'Pokazatelj', years);
for h = ["TOTAL", "HH_DEG3"]
    for g = geos
        v = nan(size(years));
        for i = 1:numel(years)
            idx = R.hhtyp == h & R.geo == g & R.TIME_PERIOD == years(i);
            if any(idx), v(i) = R.OBS_VALUE(find(idx, 1)); end
        end
        lbl = sprintf('Kucanstva s internetom (%s) - %s', h, g);
        fprintf('%-46s %6.1f %6.1f %6.1f %6.1f\n', lbl, v);
    end
end

%% 2) Ruralne digitalne vještine (I_DSK2_BAB), isoc_digskills
S = readtable(fullfile(dataDir, 'isoc_digskills.csv'), 'TextType', 'string');
for g = geos
    v = nan(size(years));
    for i = 1:numel(years)
        idx = S.ind_type == "IND_DEG3" & S.geo == g & S.year == years(i);
        if any(idx), v(i) = S.value(find(idx, 1)); end
    end
    lbl = sprintf('Ruralne dig. vjestine (IND_DEG3) - %s', g);
    fprintf('%-46s %6.1f %6.1f %6.1f %6.1f\n', lbl, v);
end
fprintf('\nNapomena: digitalne vjestine mjere se od 2021. (za 2019. NaN).\n');
