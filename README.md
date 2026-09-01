# Regional digital divide in European Union agriculture with a focus on Croatia

Replication package for the paper presented at the 8th International Scientific and Professional Conference **"Innovation and Agribusiness"** (Croatian Society of Agricultural Economists, Osijek, 27 November 2026).

**Authors:** Vedran Uroš (University of Zagreb, Faculty of Organization and Informatics, Varaždin) · Sandra Mandinić (University of Applied Sciences "Marko Marulić" of Knin)

## What the paper does

Using the first harmonised EU data on farm digitalisation (Farm Structure Survey 2023, Eurostat dataset `ef_mp_digi`, published June 2026), the paper quantifies the regional digital divide across **125 NUTS 2 regions of 19 EU member states**, derives a three-cluster typology of regions and positions the Croatian regions within it, complemented by 2019–2025 trends in rural connectivity and digital skills.

## Repository structure

```
├── data/
│   ├── ef_mp_digi_total.csv     # filtered FSS 2023 adoption data (country + NUTS 2 totals)
│   ├── isoc_r_iacc_h.csv        # households with internet, NUTS 2 (Eurostat export)
│   ├── isoc_ci_in_h.csv         # households with internet, countries (Eurostat export)
│   ├── isoc_digskills.csv       # digital skills, filtered (I_DSK2_BAB)
│   ├── ef_mp_digi.csv           # raw FSS 2023 Eurostat export (full)
│   ├── nuts2_master.csv         # analysis-ready table, 125 NUTS 2 regions (built)
│   └── country_master.csv       # analysis-ready table, 20 countries (built)
├── matlab/
│   ├── build_dataset.m          # builds master tables from the filtered Eurostat CSVs
│   ├── analiza.m                # full statistical analysis (Tables 1–3, Figures 1–2, regressions)
│   └── analiza_trend.m          # 2019–2025 trend analysis (Table 4)
└── download_eurostat.ps1        # raw data acquisition from the Eurostat API (PowerShell)
```

The repository contains the analysis code and data only; the manuscript is not distributed here.

Two large raw Eurostat exports (`ef_mp_digicr.csv`, 109 MB — not used in the paper; `isoc_sk_dskl_i21.csv`, 57 MB — its filtered subset `isoc_digskills.csv` is tracked) are **not** in the repository due to GitHub file-size limits; they can be re-downloaded with `download_eurostat.ps1`. The full pipeline is reproducible from the files included here.

## How to reproduce

Requires MATLAB with the **Statistics and Machine Learning Toolbox**.

```matlab
cd matlab
build_dataset    % rebuilds data/nuts2_master.csv and data/country_master.csv
analiza          % descriptives, Spearman, PCA, k-means, Kruskal-Wallis, OLS+HC3, figures
analiza_trend    % Table 4: internet access and digital skills 2019-2025
```

`rng(42)` is set in `analiza.m`, so the k-means clustering is fully reproducible.

## Data sources

All data are open Eurostat data (© European Union, reused under the [Eurostat reuse policy](https://ec.europa.eu/eurostat/about-us/policies/copyright)): `ef_mp_digi`, `isoc_r_iacc_h`, `isoc_ci_in_h`, `isoc_sk_dskl_i21` (accessed August 2026).

## Citation

Uroš V., Mandinić S. (2026). Regional digital divide in European Union agriculture with a focus on Croatia. In: Proceedings of the 8th International Scientific and Professional Conference "Innovation and Agribusiness", Osijek, Croatia.

## License

Code (MATLAB and PowerShell scripts): MIT. Data: © European Union / Eurostat, see above.
