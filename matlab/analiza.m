%% analiza.m
% Statistička analiza usvajanja digitalnih tehnologija u poljoprivredi EU
% na razini NUTS2 regija, s posebnim osvrtom na Hrvatsku.
%
% Rad za: VIII. međunarodni znanstveno-stručni skup "Inovacije i agrobiznis",
%         Osijek, 27.11.2026.
% Zahtijeva: Statistics and Machine Learning Toolbox
% Prethodno pokrenuti: build_dataset.m
%
% Analize:
%   1) Deskriptivna statistika + pozicija Hrvatske
%   2) Spearmanove korelacije (usvajanje ~ strukturni čimbenici)
%   3) PCA (glavne komponente usvajanja)
%   4) K-means klasteriranje regija (tipologija digitalizacije)
%   5) Kruskal-Wallis test razlika među klasterima
%   6) Višestruka regresija (fitlm) za odabrane tehnologije
%
% Autor: Vedran Uroš, 2026.

clear; clc; close all;
rng(42);                                   % reproducibilnost k-means

dataDir = fullfile(fileparts(mfilename('fullpath')), '..', 'data');
outDir  = fullfile(fileparts(mfilename('fullpath')), '..', 'rezultati');
if ~exist(outDir, 'dir'), mkdir(outDir); end

T  = readtable(fullfile(dataDir, 'nuts2_master.csv'), 'TextType', 'string');
CN = readtable(fullfile(dataDir, 'country_master.csv'), 'TextType', 'string');

techCols  = ["ACS_INET_pct", "MIS_USE_pct", "MAC_PFRM_pct", "MAC_ROB_pct", "MAC_LSM_pct"];
techNames = ["Internet", "FMIS", "Precizna polj.", "Roboti", "Prać. stoke"];
covCols   = ["avg_ha", "avg_eur_th", "lsu_per_farm", "hh_internet"];
covNames  = ["Prosj. površina (ha)", "Ekon. veličina (tis. EUR)", ...
             "LSU po gospodarstvu", "Kućanstva s internetom (%)"];

X = T{:, techCols};                        % n x 5 stope usvajanja
C = T{:, covCols};
isHR = startsWith(T.geo, "HR");
fprintf('n = %d NUTS2 regija, od toga hrvatskih: %d (%s)\n\n', ...
    height(T), nnz(isHR), strjoin(T.geo(isHR), ', '));

%% 1) Deskriptivna statistika i pozicija Hrvatske
fprintf('=== 1) Deskriptivna statistika (NUTS2, n=%d) ===\n', height(T));
desc = table(techNames', median(X)', quantile(X, .25)', quantile(X, .75)', ...
    'VariableNames', {'Tehnologija', 'Medijan', 'Q1', 'Q3'});
disp(desc);
fprintf('Hrvatske regije:\n');
disp(T(isHR, ["geo", techCols, "avg_ha", "avg_eur_th"]));

% Percentilni rang hrvatskih regija po svakoj tehnologiji
fprintf('Percentilni rang hrvatskih regija (0-100):\n');
for j = 1:numel(techCols)
    pr = 100 * sum(X(:, j) < X(isHR, j)', 1) / height(T);
    fprintf('  %-15s: %s\n', techNames(j), ...
        strjoin(compose('%s=%.0f', T.geo(isHR), pr'), ', '));
end

%% 2) Spearmanove korelacije
fprintf('\n=== 2) Spearman rho (usvajanje ~ strukturni čimbenici) ===\n');
[RHO, PVAL] = corr(X, C, 'Type', 'Spearman');
for j = 1:numel(covCols)
    fprintf('%-28s:', covNames(j));
    for t = 1:numel(techCols)
        s = ''; p = PVAL(t, j);
        if p < .001, s = '***'; elseif p < .01, s = '**'; elseif p < .05, s = '*'; end
        fprintf('  %s rho=%.2f%s', techNames(t), RHO(t, j), s);
    end
    fprintf('\n');
end
writetable(array2table([RHO, PVAL], 'RowNames', cellstr(techNames), ...
    'VariableNames', [cellstr("rho_" + covCols), cellstr("p_" + covCols)]), ...
    fullfile(outDir, 'korelacije.csv'), 'WriteRowNames', true);

%% 3) PCA
fprintf('\n=== 3) PCA na standardiziranim stopama usvajanja ===\n');
Z = zscore(X);
[coeff, score, ~, ~, explained] = pca(Z);
fprintf('Objašnjena varijanca PC1-PC3: %.1f%%, %.1f%%, %.1f%%\n', explained(1:3));
fprintf('Opterećenja PC1: %s\n', strjoin(compose('%s=%.2f', techNames', coeff(:,1)), ', '));

%% 4) K-means klasteriranje (izbor k silhouette metodom)
fprintf('\n=== 4) K-means tipologija regija ===\n');
maxK = 6; sil = nan(maxK, 1);
for k = 2:maxK
    idx = kmeans(Z, k, 'Replicates', 50);
    sil(k) = mean(silhouette(Z, idx));
    fprintf('  k=%d: prosj. silhouette = %.3f\n', k, sil(k));
end
k = 3;                                     % interpretabilna tipologija (vidi rad)
idx = kmeans(Z, k, 'Replicates', 50);
% Preimenuj klastere po rastućem prosjeku usvajanja (1=najniži)
[~, ord] = sort(grpstats(mean(X, 2), idx, 'mean'));
newIdx = zeros(size(idx));
for c = 1:k, newIdx(idx == ord(c)) = c; end
T.cluster = newIdx;
fprintf('Profili klastera (prosjeci):\n');
disp(grpstats(T, 'cluster', 'mean', 'DataVars', [techCols, "avg_ha", "avg_eur_th", "hh_internet"]));
fprintf('Hrvatske regije po klasterima:\n');
disp(T(isHR, ["geo", "cluster"]));

%% 5) Kruskal-Wallis: razlike među klasterima
fprintf('\n=== 5) Kruskal-Wallis (razlike klastera po tehnologijama) ===\n');
for t = 1:numel(techCols)
    p = kruskalwallis(X(:, t), T.cluster, 'off');
    fprintf('  %-15s: p = %.2e\n', techNames(t), p);
end

%% 6) Višestruka regresija (log-transformirane veličine)
fprintf('\n=== 6) Regresijski modeli (fitlm) ===\n');
Reg = table(log(T.avg_eur_th), log(T.avg_ha), T.hh_internet, ...
    'VariableNames', {'log_ekon_velicina', 'log_povrsina', 'internet_kuc'});
for t = ["MAC_PFRM_pct", "MIS_USE_pct"]
    Reg.y = T.(t);
    mdl = fitlm(Reg, 'y ~ log_ekon_velicina + log_povrsina + internet_kuc');
    fprintf('\n--- Zavisna varijabla: %s ---\n', t); disp(mdl);
    % HC3 robusne standardne pogreške (na heteroskedastičnost) - kao u radu
    Xd = [ones(height(T),1), Reg.log_ekon_velicina, Reg.log_povrsina, Reg.internet_kuc];
    y  = Reg.y; n = size(Xd,1); k = size(Xd,2);
    b  = Xd \ y; e = y - Xd*b;
    XtXi = inv(Xd'*Xd); h = sum((Xd*XtXi).*Xd, 2);          % leverage
    V  = XtXi * (Xd' * diag((e./(1-h)).^2) * Xd) * XtXi;    % HC3
    se = sqrt(diag(V)); tst = b./se; p = 2*tcdf(-abs(tst), n-k);
    fprintf('HC3: '); fprintf('b=%.3f (p=%.4f)  ', [b p]'); fprintf('\n');
end

%% 7) Grafovi
% (a) HR vs. medijan EU regija
f1 = figure('Position', [100 100 760 420]);
b = bar([median(X); X(T.geo == "HR03", :); X(T.geo == "HR05", :); X(T.geo == "HR06", :)]');
set(gca, 'XTickLabel', techNames); ylabel('% poljoprivrednih gospodarstava');
legend({'Medijan EU regija', 'HR03 Jadranska', 'HR05 Grad Zagreb', 'HR06 Sjeverna'}, ...
    'Location', 'northeast');
title('Usvajanje digitalnih tehnologija: hrvatske regije i EU (FSS 2023)');
grid on; saveas(f1, fullfile(outDir, 'slika1_HR_vs_EU.png'));

% (b) PCA biplot s klasterima
f2 = figure('Position', [100 100 700 520]);
gscatter(score(:,1), score(:,2), T.cluster); hold on;
plot(score(isHR,1), score(isHR,2), 'kp', 'MarkerSize', 14, 'MarkerFaceColor', 'y');
text(score(isHR,1)+.1, score(isHR,2), T.geo(isHR));
xlabel(sprintf('PC1 (%.0f%%)', explained(1))); ylabel(sprintf('PC2 (%.0f%%)', explained(2)));
title('Tipologija digitalizacije poljoprivrede EU regija (k-means, k=3)');
legend({'Klaster 1 (niska)', 'Klaster 2 (umjerena)', 'Klaster 3 (visoka)', 'HR regije'});
grid on; saveas(f2, fullfile(outDir, 'slika2_PCA_klasteri.png'));

% (c) Odnos ekonomske veličine i precizne poljoprivrede
f3 = figure('Position', [100 100 700 480]);
scatter(T.avg_eur_th, T.MAC_PFRM_pct, 30, T.cluster, 'filled'); hold on;
plot(T.avg_eur_th(isHR), T.MAC_PFRM_pct(isHR), 'kp', 'MarkerSize', 14, 'MarkerFaceColor', 'y');
set(gca, 'XScale', 'log');
xlabel('Ekonomska veličina gospodarstva (tis. EUR SO, log)');
ylabel('Precizna poljoprivreda (% gospodarstava)');
title(sprintf('Ekonomska veličina i precizna poljoprivreda (Spearman rho=%.2f)', ...
    corr(T.avg_eur_th, T.MAC_PFRM_pct, 'Type', 'Spearman')));
grid on; saveas(f3, fullfile(outDir, 'slika3_velicina_precizna.png'));

writetable(T, fullfile(outDir, 'nuts2_s_klasterima.csv'));
fprintf('\nRezultati i slike spremljeni u mapu "rezultati".\n');
