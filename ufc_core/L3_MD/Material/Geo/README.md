# Geotech（T1: PLG）

- **镜像路径**: `L3_MD/Material/PLG/` ↔ `L4_PH/Material/PLG/`
- **L3**: 岩土与水泥基塑性 **Desc**（`MD_Mat_PLG_GeoMatCore`、`MD_Mat_Plast_Geotech_Desc`、分模型 **`MD_Mat_PLG_DruckerPrager` / `MD_Mat_PLG_MohrCoulomb` / `MD_Mat_PLG_CamClay` / `MD_Mat_PLG_Cap` / `MD_Mat_PLG_SoftRock` / `MD_Mat_PLG_Joint` / `MD_Mat_PLG_Geotech`** 等）。
- **L4**: DP、MC、Cam-Clay、Cap、软岩、节理、Geotech 占位等与 `Geotech/*.f90` 镜像。
- **禁止**: L3 步内本构热路径；L4 Desc 真相源。
- **真源**: [`../_inv/MAT_TAXONOMY.md`](../_inv/MAT_TAXONOMY.md) §2
