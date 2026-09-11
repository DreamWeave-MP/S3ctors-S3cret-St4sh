---@omw-context none

return {
  replacementPrefix = 'misc_soulgem_vsg_',
  variants = {
    {
      setting = 'particles',
      suffix = 'particles',
      models = {
        common = 'meshes/s3/Particles/Misc_Soulgem_Common.nif',
        grand = 'meshes/s3/Particles/Misc_Soulgem_Grand.nif',
        greater = 'meshes/s3/Particles/Misc_Soulgem_Greater.nif',
        lesser = 'meshes/s3/Particles/Misc_Soulgem_Lesser.nif',
        petty = 'meshes/s3/Particles/Misc_Soulgem_Petty.nif',
        black = 'meshes/s3/Particles/Misc_Soulgem_Black.nif',
      },
    },
    {
      setting = 'particles & static glow',
      suffix = 'particles_static_glow',
      models = {
        common = 'meshes/s3/Particles & Static Glow/Misc_Soulgem_Common.nif',
        grand = 'meshes/s3/Particles & Static Glow/Misc_Soulgem_Grand.nif',
        greater = 'meshes/s3/Particles & Static Glow/Misc_Soulgem_Greater.nif',
        lesser = 'meshes/s3/Particles & Static Glow/Misc_Soulgem_Lesser.nif',
        petty = 'meshes/s3/Particles & Static Glow/Misc_Soulgem_Petty.nif',
        black = 'meshes/s3/Particles & Static Glow/Misc_Soulgem_Black.nif',
      },
    },
    {
      setting = 'static glow',
      suffix = 'static_glow',
      models = {
        common = 'meshes/s3/Static Glow/Misc_Soulgem_Common.nif',
        grand = 'meshes/s3/Static Glow/Misc_Soulgem_Grand.nif',
        greater = 'meshes/s3/Static Glow/Misc_Soulgem_Greater.nif',
        lesser = 'meshes/s3/Static Glow/Misc_Soulgem_Lesser.nif',
        petty = 'meshes/s3/Static Glow/Misc_Soulgem_Petty.nif',
        black = 'meshes/s3/Static Glow/Misc_Soulgem_Black.nif',
      },
    },
    {
      setting = 'ultra glow',
      suffix = 'ultra_glow',
      models = {
        common = 'meshes/s3/Ultra Glow/Misc_Soulgem_Common.nif',
        grand = 'meshes/s3/Ultra Glow/Misc_Soulgem_Grand.nif',
        greater = 'meshes/s3/Ultra Glow/Misc_Soulgem_Greater.nif',
        lesser = 'meshes/s3/Ultra Glow/Misc_Soulgem_Lesser.nif',
        petty = 'meshes/s3/Ultra Glow/Misc_Soulgem_Petty.nif',
        black = 'meshes/s3/Ultra Glow/Misc_Soulgem_Black.nif',
      },
    },
  },
  records = {
    {
      sourceId = 'misc_soulgem_common',
      replacementName = 'common',
      modelKey = 'common',
      required = true,
    },
    {
      sourceId = 'misc_soulgem_grand',
      replacementName = 'grand',
      modelKey = 'grand',
      required = true,
    },
    {
      sourceId = 'misc_soulgem_greater',
      replacementName = 'greater',
      modelKey = 'greater',
      required = true,
    },
    {
      sourceId = 'misc_soulgem_lesser',
      replacementName = 'lesser',
      modelKey = 'lesser',
      required = true,
    },
    {
      sourceId = 'misc_soulgem_petty',
      replacementName = 'petty',
      modelKey = 'petty',
      required = true,
    },
    {
      sourceId = 'a_bsg_emptyblackgem',
      replacementName = 'a_bsg_emptyblackgem',
      modelKey = 'black',
    },
    {
      sourceId = 'ab_misc_soulgemblack',
      replacementName = 'ab_misc_soulgemblack',
      modelKey = 'black',
    },
    {
      sourceId = 'misc_soulgem_black',
      replacementName = 'misc_soulgem_black',
      modelKey = 'black',
    },
    {
      sourceId = 'misc_soulgem_blackempty',
      replacementName = 'misc_soulgem_blackempty',
      modelKey = 'black',
    },
  },
}
