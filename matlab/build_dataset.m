%% build_dataset.m
% Gradi analitičke tablice iz filtriranih Eurostat CSV datoteka.
% Ulaz  (mapa ../data): ef_mp_digi_total.csv, isoc_r_iacc_h.csv
% Izlaz (mapa ../data): nuts2_master.csv, country_master.csv
%
% Izvori podataka (Eurostat, pristup: kolovoz 2026.):
%   ef_mp_digi    - Farms using digital technologies (FSS 2023)
%   isoc_r_iacc_h - Households with access to the internet at home (NUTS2)
%
% Autor: Vedran Uroš, 2026.

clear; clc;

dataDir = fullfile(fileparts(mfilename('fullpath')), '..', 'data');

%% 1) Učitaj filtrirani ef_mp_digi (geo, agr_inp, unit, value)
D = readtable(fullfile(dataDir, 'ef_mp_digi_total.csv'), 'TextType', 'string');

techs = ["ACS_INET", "MIS_USE", "MAC_PFRM", "MAC_ROB", "MAC_LSM"];
geos  = unique(D.geo);
nG    = numel(geos);

% Pomoćna funkcija: vrijednost za (geo, agr_inp, unit), NaN ako nema
getv = @(g, a, u) local_get(D, g, a, u);

M = table();
M.geo = geos;
for t = 1:numel(techs)
    col = nan(nG, 1);
    for i = 1:nG
        hld_t   = getv(geos(i), techs(t), "HLD");
        hld_tot = getv(geos(i), "TOTAL",  "HLD");
        col(i)  = 100 * hld_t / hld_tot;
    end
    M.(techs(t) + "_pct") = col;
end

avg_ha  = nan(nG,1); avg_eur = nan(nG,1); lsu_pf = nan(nG,1); n_farms = nan(nG,1);
for i = 1:nG
    hld = getv(geos(i), "TOTAL", "HLD");
    avg_ha(i)  = getv(geos(i), "TOTAL", "HA")  / hld;
    avg_eur(i) = getv(geos(i), "TOTAL", "EUR") / hld / 1000;   % tis. EUR SO po gospodarstvu
    lsu_pf(i)  = getv(geos(i), "TOTAL", "LSU") / hld;
    n_farms(i) = hld;
end
M.avg_ha = avg_ha; M.avg_eur_th = avg_eur; M.lsu_per_farm = lsu_pf; M.n_farms = n_farms;

%% 2) Kućanstva s internetom (NUTS2) - zadnja dostupna godina 2023-2025
R = readtable(fullfile(dataDir, 'isoc_r_iacc_h.csv'), 'TextType', 'string', ...
    'VariableNamingRule', 'preserve');
R.Properties.VariableNames = matlab.lang.makeValidName(R.Properties.VariableNames);
R = R(R.TIME_PERIOD >= 2023 & R.unit == "PC_HH", :);
R = sortrows(R, 'TIME_PERIOD');           % zadnja godina pobjeđuje
hh = containers.Map();
for i = 1:height(R)
    hh(char(R.geo(i))) = R.OBS_VALUE(i);
end
hh_int = nan(nG,1);
for i = 1:nG
    if isKey(hh, char(geos(i))), hh_int(i) = hh(char(geos(i))); end
end
M.hh_internet = hh_int;

%% 3) Podjela na NUTS2 i države, spremanje
len = strlength(M.geo);
N2 = M(len == 4, :);                       % NUTS2 regije
CN = M(len == 2, :);                       % države
N2 = rmmissing(N2);                        % samo potpuni slučajevi
CN = rmmissing(CN);

writetable(N2, fullfile(dataDir, 'nuts2_master.csv'));
writetable(CN, fullfile(dataDir, 'country_master.csv'));

fprintf('NUTS2 regija (potpuni slučajevi): %d\n', height(N2));
fprintf('Država: %d\n', height(CN));
fprintf('Hrvatske regije: %s\n', strjoin(N2.geo(startsWith(N2.geo, "HR")), ', '));

%% ---- lokalna funkcija ----
function v = local_get(D, g, a, u)
    idx = D.geo == g & D.agr_inp == a & D.unit == u;
    if any(idx), v = D.value(find(idx, 1)); else, v = NaN; end
end
