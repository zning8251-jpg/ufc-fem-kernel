# PorousFoam（T1: POR）

- **镜像路径**: `L3_MD/Material/POR/` ↔ `L4_PH/Material/POR/`
- **L3**: 孔洞金属、可压碎泡沫等 **Desc**（自 Plastic Core 逐步迁入）。
- **L4**: Gurson、泡沫等多孔/胞元类本构核。
- **禁止**: L3 热路径求值；L4 材料卡真相源。
- **真源**: [`../_inv/MAT_TAXONOMY.md`](../_inv/MAT_TAXONOMY.md) §2
