# SPDX-FileCopyrightText: : 2023 The PyPSA-Eur Authors
#
# SPDX-License-Identifier: MIT


rule prepare_espeni_generation:
    params:
        elec_config=config["electricity"],
    input:
        espeni_dataset="data/espeni.csv",
        beis_generation_dataset="data/DUKES_5.6.xlsx"
        if config["electricity"]["include_beis"]
        else [],
    output:
        espeni_generation=RESOURCES + "espeni_generation.csv",
        espeni_interconnectors=RESOURCES + "espeni_interconnectors.csv",
        beis_generation=RESOURCES + "beis_generation.csv"
        if config["electricity"]["include_beis"]
        else [],
    log:
        LOGS + "prepare_espeni_generation.log",
    threads: 1
    resources:
        mem_mb=1500,
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/prepare_espeni_generation.py"



if config["enable"].get("prepare_links_p_nom", False):

    rule prepare_links_p_nom:
        output:
            "data/links_p_nom.csv",
        log:
            LOGS + "prepare_links_p_nom.log",
        threads: 1
        resources:
            mem_mb=1500,
        conda:
            "../envs/environment.yaml"
        script:
            "../scripts/prepare_links_p_nom.py"


rule build_electricity_demand_europe:
    params:
        snapshots=config["snapshots"],
        countries=config["countries"],
        load=config["load"],
    input:
        ancient("data/load_raw.csv"),
    output:
        # RESOURCES + "default_load.csv",
        RESOURCES + "load.csv",
    log:
        LOGS + "build_electricity_demand.log",
    resources:
        mem_mb=5000,
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/build_electricity_demand_europe.py"


rule build_temperature_profiles:
    input:
        pop_layout=RESOURCES + "pop_layout_{scope}.nc",
        regions_onshore=RESOURCES + "regions_onshore_elec_s{simpl}_eso.geojson",
        cutout="cutouts/" + CDIR + config["atlite"]["default_cutout"] + ".nc",
    output:
        temp_soil=RESOURCES + "temp_soil_{scope}_elec_s{simpl}_eso.nc",
        temp_air=RESOURCES + "temp_air_{scope}_elec_s{simpl}_eso.nc",
    resources:
        mem_mb=20000,
    threads: 8
    log:
        LOGS + "build_temperature_profiles_{scope}_{simpl}.log",
    benchmark:
        BENCHMARKS + "build_temperature_profiles/{scope}_s{simpl}"
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/build_temperature_profiles.py"


rule build_population_layouts:
    input:
        nuts3_shapes=RESOURCES + "nuts3_shapes.geojson",
        urban_percent="data/urban_percent.csv",
        cutout="cutouts/" + CDIR + config["atlite"]["default_cutout"] + ".nc",
    output:
        pop_layout_total=RESOURCES + "pop_layout_total.nc",
        pop_layout_urban=RESOURCES + "pop_layout_urban.nc",
        pop_layout_rural=RESOURCES + "pop_layout_rural.nc",
    log:
        LOGS + "build_population_layouts.log",
    resources:
        mem_mb=20000,
    benchmark:
        BENCHMARKS + "build_population_layouts"
    threads: 8
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/build_population_layouts.py"


rule build_clustered_population_layouts:
    input:
        pop_layout_total=RESOURCES + "pop_layout_total.nc",
        pop_layout_urban=RESOURCES + "pop_layout_urban.nc",
        pop_layout_rural=RESOURCES + "pop_layout_rural.nc",
        regions_onshore=RESOURCES + "regions_onshore_elec_s{simpl}_eso.geojson",
        cutout="cutouts/" + CDIR + config["atlite"]["default_cutout"] + ".nc",
    output:
        clustered_pop_layout=RESOURCES + "pop_layout_elec_s{simpl}_eso.csv",
    log:
        LOGS + "build_clustered_population_layouts_{simpl}.log",
    resources:
        mem_mb=10000,
    benchmark:
        BENCHMARKS + "build_clustered_population_layouts/s{simpl}"
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/build_clustered_population_layouts.py"


rule build_population_weighted_energy_totals:
    input:
        energy_totals=RESOURCES + "energy_totals.csv",
        clustered_pop_layout=RESOURCES + "pop_layout_elec_s{simpl}_eso.csv",
    output:
        RESOURCES + "pop_weighted_energy_totals_s{simpl}_eso.csv",
    threads: 1
    resources:
        mem_mb=2000,
    log:
        LOGS + "build_population_weighted_energy_totals_s{simpl}.log",
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/build_population_weighted_energy_totals.py"


rule build_transport_demand:
    input:
        clustered_pop_layout=RESOURCES + "pop_layout_elec_s{simpl}_eso.csv",
        pop_weighted_energy_totals=RESOURCES
        + "pop_weighted_energy_totals_s{simpl}_eso.csv",
        transport_data=RESOURCES + "transport_data.csv",
        traffic_data_KFZ="data/emobility/KFZ__count",
        traffic_data_Pkw="data/emobility/Pkw__count",
        temp_air_total=RESOURCES + "temp_air_total_elec_s{simpl}_eso.nc",
        fes_data="data/Data-workbook2022_V006.xlsx",
    output:
        transport_demand=RESOURCES + "transport_demand_s{simpl}_eso.csv",
        transport_data=RESOURCES + "transport_data_s{simpl}_eso.csv",
        avail_profile=RESOURCES + "avail_profile_s{simpl}_eso.csv",
        dsm_profile=RESOURCES + "dsm_profile_s{simpl}_eso.csv",
    threads: 1
    resources:
        mem_mb=2000,
    log:
        LOGS + "build_transport_demand_s{simpl}.log",
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/build_transport_demand.py"


rule build_heat_demands:
    input:
        # pop_layout=RESOURCES + "pop_layout_{scope}.nc",
        pop_layout=RESOURCES + "pop_layout_total.nc",
        regions_onshore=RESOURCES + "regions_onshore_elec_s{simpl}_eso.geojson",
        cutout="cutouts/" + CDIR + config["atlite"]["default_cutout"] + ".nc",
    output:
        # heat_demand=RESOURCES + "heat_demand_{scope}_elec_s{simpl}_{gb_regions}.nc",
        heat_demand=RESOURCES + "heat_demand_total_elec_s{simpl}_eso.nc",
    resources:
        mem_mb=20000,
    threads: 8
    log:
        # LOGS + "build_heat_demands_{scope}_{simpl}_{gb_regions}.loc",
        LOGS + "build_heat_demands_residential_{simpl}.loc",
    benchmark:
        # BENCHMARKS + "build_heat_demands/{scope}_s{simpl}_{gb_regions}"
        BENCHMARKS + "build_heat_demands/residential_s{simpl}"
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/build_heat_demand.py"


rule build_cop_profiles:
    input:
        temp_soil_total=RESOURCES + "temp_soil_total_elec_s{simpl}_eso.nc",
        temp_soil_rural=RESOURCES + "temp_soil_rural_elec_s{simpl}_eso.nc",
        temp_soil_urban=RESOURCES + "temp_soil_urban_elec_s{simpl}_eso.nc",
        temp_air_total=RESOURCES + "temp_air_total_elec_s{simpl}_eso.nc",
        temp_air_rural=RESOURCES + "temp_air_rural_elec_s{simpl}_eso.nc",
        temp_air_urban=RESOURCES + "temp_air_urban_elec_s{simpl}_eso.nc",
    output:
        cop_soil_total=RESOURCES + "cop_soil_total_elec_s{simpl}_eso.nc",
        cop_soil_rural=RESOURCES + "cop_soil_rural_elec_s{simpl}_eso.nc",
        cop_soil_urban=RESOURCES + "cop_soil_urban_elec_s{simpl}_eso.nc",
        cop_air_total=RESOURCES + "cop_air_total_elec_s{simpl}_eso.nc",
        cop_air_rural=RESOURCES + "cop_air_rural_elec_s{simpl}_eso.nc",
        cop_air_urban=RESOURCES + "cop_air_urban_elec_s{simpl}_eso.nc",
    resources:
        mem_mb=20000,
    log:
        LOGS + "build_cop_profiles_s{simpl}.log",
    benchmark:
        BENCHMARKS + "build_cop_profiles/s{simpl}"
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/build_cop_profiles.py"


rule build_biomass_potentials:
    input:
        enspreso_biomass=HTTP.remote(
            "https://cidportal.jrc.ec.europa.eu/ftp/jrc-opendata/ENSPRESO/ENSPRESO_BIOMASS.xlsx",
            keep_local=True,
        ),
        nuts2="data/nuts/NUTS_RG_10M_2013_4326_LEVL_2.geojson",  # https://gisco-services.ec.europa.eu/distribution/v2/nuts/download/#nuts21
        regions_onshore=RESOURCES + "regions_onshore_elec_s{simpl}_eso.geojson",
        nuts3_population=ancient("data/bundle/nama_10r_3popgdp.tsv.gz"),
        swiss_cantons=ancient("data/bundle/ch_cantons.csv"),
        swiss_population=ancient("data/bundle/je-e-21.03.02.xls"),
        country_shapes=RESOURCES + "country_shapes.geojson",
    output:
        biomass_potentials_all=RESOURCES
        + "biomass_potentials_all_s{simpl}.csv",
        biomass_potentials=RESOURCES + "biomass_potentials_s{simpl}_eso.csv",
    threads: 1
    resources:
        mem_mb=1000,
    log:
        LOGS + "build_biomass_potentials_s{simpl}.log",
    benchmark:
        BENCHMARKS + "build_biomass_potentials_s{simpl}"
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/build_biomass_potentials.py"


rule build_powerplants:
    input:
        base_network=RESOURCES + "networks/base.nc",
        custom_powerplants="data/custom_powerplants.csv",
    output:
        RESOURCES + "powerplants.csv",
    log:
        LOGS + "build_powerplants.log",
    threads: 1
    resources:
        mem_mb=5000,
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/build_powerplants.py"


rule build_temperature_profiles_halloran:
    params:
        atlite=config["atlite"],
        heating=config["heating"],
        snapshots=config["snapshots"],
    input:
        regions=RESOURCES + "regions_onshore_elec_s{simpl}_eso.geojson",
        population="data/population_layout/GB_residential_population_2011_1_km.tif",
        cutout="cutouts/" + CDIR + config["atlite"]["default_cutout"] + ".nc",
    output:
        temp_air=RESOURCES + "temp_air_elec_s{simpl}_eso_halloran.nc",
        temp_ground=RESOURCES + "temp_ground_elec_s{simpl}_eso_halloran.nc"
    script:
        "../scripts/build_temperature_profiles_halloran.py"


rule build_heating_profiles_halloran:
    params:
        snapshots=config["snapshots"],
        heating=config["heating"],
    input:
        regions=RESOURCES + "regions_onshore_elec_s{simpl}_eso.geojson",
        population="data/population_layout/GB_residential_population_2011_1_km.tif",
        cutout="cutouts/" + CDIR + config["atlite"]["default_cutout"] + ".nc",
    output:
        profile_air_source_heating=RESOURCES + "load_air_source_heating_elec_s{simpl}_eso.nc",
        profile_ground_source_heating=RESOURCES + "load_ground_source_heating_elec_s{simpl}_eso.nc"
    script:
        "../scripts/build_heating_profiles_halloran.py"


rule base_network:
    input:
        eg_buses="data/entsoegridkit/buses.csv",
        eg_lines="data/entsoegridkit/lines.csv",
        eg_links="data/entsoegridkit/links.csv",
        eg_converters="data/entsoegridkit/converters.csv",
        eg_transformers="data/entsoegridkit/transformers.csv",
        parameter_corrections="data/parameter_corrections.yaml",
        links_p_nom="data/links_p_nom.csv",
        links_tyndp="data/links_tyndp.csv",
        country_shapes=RESOURCES + "country_shapes.geojson",
        offshore_shapes=RESOURCES + "offshore_shapes.geojson",
        europe_shape=RESOURCES + "europe_shape.geojson",
    output:
        RESOURCES + "networks/base.nc",
    log:
        LOGS + "base_network.log",
    benchmark:
        BENCHMARKS + "base_network"
    threads: 1
    resources:
        mem_mb=1500,
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/base_network.py"


rule build_shapes:
    input:
        naturalearth=ancient("data/bundle/naturalearth/ne_10m_admin_0_countries.shp"),
        eez=ancient("data/bundle/eez/World_EEZ_v8_2014.shp"),
        nuts3=ancient("data/bundle/NUTS_2013_60M_SH/data/NUTS_RG_60M_2013.shp"),
        nuts3pop=ancient("data/bundle/nama_10r_3popgdp.tsv.gz"),
        nuts3gdp=ancient("data/bundle/nama_10r_3gdp.tsv.gz"),
        ch_cantons=ancient("data/bundle/ch_cantons.csv"),
        ch_popgdp=ancient("data/bundle/je-e-21.03.02.xls"),
    output:
        country_shapes=RESOURCES + "country_shapes.geojson",
        offshore_shapes=RESOURCES + "offshore_shapes.geojson",
        europe_shape=RESOURCES + "europe_shape.geojson",
        nuts3_shapes=RESOURCES + "nuts3_shapes.geojson",
    log:
        LOGS + "build_shapes.log",
    threads: 1
    resources:
        mem_mb=1500,
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/build_shapes.py"


rule build_bus_regions:
    input:
        country_shapes=RESOURCES + "country_shapes.geojson",
        offshore_shapes=RESOURCES + "offshore_shapes.geojson",
        base_network=RESOURCES + "networks/base.nc",
    output:
        regions_onshore=RESOURCES + "regions_onshore.geojson",
        regions_offshore=RESOURCES + "regions_offshore.geojson",
    log:
        LOGS + "build_bus_regions.log",
    threads: 1
    resources:
        mem_mb=1000,
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/build_bus_regions.py"


if config["enable"].get("build_cutout", False):

    rule build_cutout:
        input:
            regions_onshore=RESOURCES + "regions_onshore.geojson",
            regions_offshore=RESOURCES + "regions_offshore.geojson",
        output:
            protected("cutouts/" + CDIR + "{cutout}.nc"),
        log:
            "logs/" + CDIR + "build_cutout/{cutout}.log",
        benchmark:
            "benchmarks/" + CDIR + "build_cutout_{cutout}"
        threads: ATLITE_NPROCESSES
        resources:
            mem_mb=ATLITE_NPROCESSES * 1000,
        conda:
            "../envs/environment.yaml"
        script:
            "../scripts/build_cutout.py"


    rule build_morocco_cutout:
        output:
            protected("morocco_cutouts/" + CDIR + "{morocco_cutout}.nc"),
        log:
            "logs/" + CDIR + "build_morocco_cutout/{morocco_cutout}.log",
        benchmark:
            "benchmarks/" + CDIR + "build_morocco_cutout_{morocco_cutout}"
        threads: ATLITE_NPROCESSES
        resources:
            mem_mb=ATLITE_NPROCESSES * 1000,
        conda:
            "../envs/environment.yaml"
        script:
            "../scripts/build_morocco_cutout.py"


if config["enable"].get("build_natura_raster", False):

    rule build_natura_raster:
        input:
            natura=ancient("data/bundle/natura/Natura2000_end2015.shp"),
            cutouts=expand("cutouts/" + CDIR + "{cutouts}.nc", **config["atlite"]),
        output:
            RESOURCES + "natura.tiff",
        resources:
            mem_mb=5000,
        log:
            LOGS + "build_natura_raster.log",
        conda:
            "../envs/environment.yaml"
        script:
            "../scripts/build_natura_raster.py"


rule build_ship_raster:
    input:
        ship_density="data/shipdensity_global.zip",
        cutouts=expand(
            "cutouts/" + CDIR + "{cutout}.nc",
            cutout=[
                config["renewable"][k]["cutout"]
                for k in config["electricity"]["renewable_carriers"]
            ],
        ),
    output:
        RESOURCES + "shipdensity_raster.tif",
    log:
        LOGS + "build_ship_raster.log",
    resources:
        mem_mb=5000,
    benchmark:
        BENCHMARKS + "build_ship_raster"
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/build_ship_raster.py"


rule build_renewable_profiles:
    input:
        base_network=RESOURCES + "networks/base.nc",
        corine=ancient("data/bundle/corine/g250_clc06_V18_5.tif"),
        natura=lambda w: (
            RESOURCES + "natura.tiff"
            if config["renewable"][w.technology]["natura"]
            else []
        ),
        gebco=ancient(
            lambda w: (
                "data/bundle/GEBCO_2014_2D.nc"
                if config["renewable"][w.technology].get("max_depth")
                else []
            )
        ),
        ship_density=lambda w: (
            RESOURCES + "shipdensity_raster.tif"
            if "ship_threshold" in config["renewable"][w.technology].keys()
            else []
        ),
        country_shapes=RESOURCES + "country_shapes.geojson",
        offshore_shapes=RESOURCES + "offshore_shapes.geojson",
        regions=lambda w: (
            RESOURCES + "regions_onshore.geojson"
            if w.technology in ("onwind", "solar")
            else RESOURCES + "regions_offshore.geojson"
        ),
        cutout=lambda w: "cutouts/"
        + CDIR
        + config["renewable"][w.technology]["cutout"]
        + ".nc",
    output:
        profile=RESOURCES + "profile_{technology}.nc",
    log:
        LOGS + "build_renewable_profile_{technology}.log",
    benchmark:
        BENCHMARKS + "build_renewable_profiles_{technology}"
    threads: ATLITE_NPROCESSES
    resources:
        mem_mb=ATLITE_NPROCESSES * 5000,
    wildcard_constraints:
        technology="(?!hydro).*",  # Any technology other than hydro
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/build_renewable_profiles.py"


rule build_morocco_renewable_profiles:
    input:
        "data/morocco_shape/Tan-Tan.json",
        "data/morocco_shape/Sidi-Ifni.json",
        "data/morocco_shape/Guelmim.json",
        "data/morocco_shape/Assa-Zag.json",
        cutout="data/morocco-2019-era5.nc"
        # cutout=lambda w: "morocco_cutouts/"
        # + CDIR
        # + config["morocco_renewable"][w.technology]["cutout"]
        # + ".nc",
    output:
        profile=RESOURCES + "profile_morocco_{technology}.nc",
    log:
        LOGS + "build_morocco_renewable_profile_{technology}.log",
    benchmark:
        BENCHMARKS + "build_morocco_renewable_profiles_{technology}"
    threads: ATLITE_NPROCESSES
    resources:
        mem_mb=ATLITE_NPROCESSES * 5000,
    wildcard_constraints:
        technology="(?!hydro).*",  # Any technology other than hydro
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/build_morocco_renewable_profiles.py"


rule build_fes_constraints:
    input:
        fes_table="data/Data-workbook2022_V006.xlsx",
    output:
        capacity_constraints=RESOURCES + "fes_capacity_constraints_{fes}_{year}.csv",
    log:
        LOGS + "build_fes_constraints_{fes}_{year}.log"
    threads: 1
    resources:
        mem_mb=1000,
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/build_fes_constraints.py"


rule build_hydro_profile:
    input:
        country_shapes=RESOURCES + "country_shapes.geojson",
        eia_hydro_generation="data/eia_hydro_annual_generation.csv",
        cutout=f"cutouts/" + CDIR + config["renewable"]["hydro"]["cutout"] + ".nc",
    output:
        RESOURCES + "profile_hydro.nc",
    log:
        LOGS + "build_hydro_profile.log",
    resources:
        mem_mb=5000,
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/build_hydro_profile.py"


rule build_monthly_prices:
    input:
        co2_price_raw="data/validation/emission-spot-primary-market-auction-report-2019-data.xls",
        fuel_price_raw="data/validation/energy-price-trends-xlsx-5619002.xlsx",
    output:
        co2_price=RESOURCES + "co2_price.csv",
        fuel_price=RESOURCES + "monthly_fuel_price.csv",
    log:
        LOGS + "build_monthly_prices.log",
    threads: 1
    resources:
        mem_mb=5000,
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/build_monthly_prices.py"


rule add_electricity:
    params:
        length_factor=config["lines"]["length_factor"],
        scaling_factor=config["load"]["scaling_factor"],
        countries=config["countries"],
        renewable=config["renewable"],
        electricity=config["electricity"],
        conventional=config["conventional"],
        costs=config["costs"],
    input:
        **{
            f"profile_{tech}": RESOURCES + f"profile_{tech}.nc"
            for tech in config["electricity"]["renewable_carriers"]
        },
        **{
            f"conventional_{carrier}_{attr}": fn
            for carrier, d in config.get("conventional", {None: {}}).items()
            if carrier in config["electricity"]["conventional_carriers"]
            for attr, fn in d.items()
            if str(fn).startswith("data/")
        },
        base_network=RESOURCES + "networks/base.nc",
        line_rating=RESOURCES + "networks/line_rating.nc"
        if config["lines"]["dynamic_line_rating"]["activate"]
        else RESOURCES + "networks/base.nc",
        tech_costs=COSTS,
        regions=RESOURCES + "regions_onshore.geojson",
        powerplants=RESOURCES + "powerplants.csv",
        hydro_capacities=ancient("data/bundle/hydro_capacities.csv"),
        geth_hydro_capacities="data/geth2015_hydro_capacities.csv",
        unit_commitment="data/unit_commitment.csv",
        fuel_price=RESOURCES + "monthly_fuel_price.csv"
        if config["conventional"]["dynamic_fuel_price"]
        else [],
        load=RESOURCES + "load.csv",
        nuts3_shapes=RESOURCES + "nuts3_shapes.geojson",
    output:
        RESOURCES + "networks/elec.nc",
    log:
        LOGS + "add_electricity.log",
    benchmark:
        BENCHMARKS + "add_electricity"
    threads: 1
    resources:
        mem_mb=10000,
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/add_electricity.py"


rule simplify_network:
    params:
        simplify_network=config["clustering"]["simplify_network"],
        aggregation_strategies=config["clustering"].get("aggregation_strategies", {}),
        focus_weights=config.get("focus_weights", None),
        renewable_carriers=config["electricity"]["renewable_carriers"],
        max_hours=config["electricity"]["max_hours"],
        length_factor=config["lines"]["length_factor"],
        p_max_pu=config["links"].get("p_max_pu", 1.0),
        costs=config["costs"],   
    input:
        network=RESOURCES + "networks/elec.nc",
        tech_costs=COSTS,
        regions_onshore=RESOURCES + "regions_onshore.geojson",
        regions_offshore=RESOURCES + "regions_offshore.geojson",
    output:
        network=RESOURCES + "networks/elec_s{simpl}.nc",
        regions_onshore=RESOURCES + "regions_onshore_elec_s{simpl}.geojson",
        regions_offshore=RESOURCES + "regions_offshore_elec_s{simpl}.geojson",
        busmap=RESOURCES + "busmap_elec_s{simpl}.csv",
        connection_costs=RESOURCES + "connection_costs_s{simpl}.csv",
    log:
        LOGS + "simplify_network/elec_s{simpl}.log",
    benchmark:
        BENCHMARKS + "simplify_network/elec_s{simpl}"
    threads: 1
    resources:
        mem_mb=4000,
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/simplify_network.py"


rule cluster_network:
    input:
        network=RESOURCES + "networks/elec_s{simpl}.nc",
        busmap="data/custom_busmap_elec_s_eso.csv",
        regions_onshore=RESOURCES + "regions_onshore_elec_s{simpl}.geojson",
        regions_offshore=RESOURCES + "regions_offshore_elec_s{simpl}.geojson",
        target_regions_onshore="data/regions_onshore_eso.geojson",
        tech_costs=COSTS,
    output:
        network=RESOURCES + "networks/elec_s{simpl}_eso.nc",
        regions_onshore=RESOURCES + "regions_onshore_elec_s{simpl}_eso.geojson",
        regions_offshore=RESOURCES + "regions_offshore_elec_s{simpl}_eso.geojson",
        busmap=RESOURCES + "busmap_elec_s{simpl}_eso.csv",
        linemap=RESOURCES + "linemap_elec_s{simpl}_eso.csv",
    log:
        LOGS + "cluster_network/elec_s{simpl}.log",
    benchmark:
        BENCHMARKS + "cluster_network/elec_s{simpl}"
    threads: 1
    resources:
        mem_mb=6000,
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/cluster_network.py"


rule add_extra_components:
    input:
        network=RESOURCES + "networks/elec_s{simpl}_eso.nc",
        tech_costs=COSTS,
    output:
        RESOURCES + "networks/elec_s{simpl}_eso_ec.nc",
    log:
        LOGS + "add_extra_components/elec_s{simpl}.log",
    benchmark:
        BENCHMARKS + "add_extra_components/elec_s{simpl}_ec"
    threads: 1
    resources:
        mem_mb=3000,
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/add_extra_components.py"


rule build_electricity_demand_gb:
    params:
        snapshots=config["snapshots"]
    output:
        espeni_electricity_demand=RESOURCES + "ESPENI_demand_gb.csv",
    log:
        LOGS + "build_electricity_demand_gb.log",
    benchmark:
        BENCHMARKS + "build_electricity_demand_gb"
    threads: 1
    resources:
        mem_mb=2000,
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/build_electricity_demand_gb.py"


rule prepare_network:
    params:
        elec_config=config["electricity"],
        flex_config=config["flexibility"],
        sector_config=config["sector"],
        solving_config=config["solving"],
        cost_config=config["costs"],
        lines=config["lines"],
        links=config["links"],
    input:
        RESOURCES + "networks/elec_s{simpl}_eso_ec.nc",
        overrides="data/override_component_attrs",
        espeni_electricity_demand=RESOURCES + "ESPENI_demand_gb.csv",
        tech_costs=COSTS,
        interconnectors="data/interconnectors_pypsa_gb_future.csv",
        regions_onshore=RESOURCES + "regions_onshore_elec_s{simpl}_eso.geojson",
        biomass_potentials=RESOURCES + "biomass_potentials_s{simpl}_eso.csv",
        capacity_constraints=RESOURCES + "fes_capacity_constraints_{fes}_{year}.csv",
        profile_boiler_heating="data/heat_load_profile_BDEW.csv",
        profile_air_source_heating=RESOURCES + "load_air_source_heating_elec_s{simpl}_eso.nc",
        profile_ground_source_heating=RESOURCES + "load_ground_source_heating_elec_s{simpl}_eso.nc",
        clustered_pop_layout=RESOURCES + "pop_layout_elec_s{simpl}_eso.csv",
        heat_demand=RESOURCES + "heat_demand_total_elec_s{simpl}_eso.nc",
        cop_air_total=RESOURCES + "cop_air_total_elec_s{simpl}_eso.nc",
        cop_ground_total=RESOURCES + "cop_air_total_elec_s{simpl}_eso.nc",
        energy_totals=RESOURCES + "pop_weighted_energy_totals_s{simpl}_eso.csv",
        transport_demand=RESOURCES + "transport_demand_s{simpl}_eso.csv",
        transport_data=RESOURCES + "transport_data_s{simpl}_eso.csv",
        avail_profile=RESOURCES + "avail_profile_s{simpl}_eso.csv",
        dsm_profile=RESOURCES + "dsm_profile_s{simpl}_eso.csv",
        fes_table_2022="data/Data-workbook2022_V006.xlsx",
        fes_table_2023="data/FES 2023 Data Workbook V001.xlsx",
        espeni_interconnectors=RESOURCES + "espeni_interconnectors.csv",
        beis_generation=RESOURCES + "beis_generation.csv"
        if config["electricity"]["include_beis"]
        else [],
        transmission_investment_outlook="data/transmission_investment_outlook.csv",
    output:
        RESOURCES + "networks/elec_s{simpl}_ec_l{ll}_{opts}_{flexopts}_{fes}_{year}.nc",
    log:
        LOGS + "prepare_network/elec_s{simpl}_ec_l{ll}_{opts}_{flexopts}_{fes}_{year}.log",
    benchmark:
        (BENCHMARKS + "prepare_network/elec_s{simpl}_ec_l{ll}_{opts}_{flexopts}_{fes}_{year}")
    threads: 1
    resources:
        mem_mb=4000,
    conda:
        "../envs/environment.yaml"
    script:
        "../scripts/prepare_network.py"