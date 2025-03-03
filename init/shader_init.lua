--GenerateEntityMaskingShaders("adamantitepulse_mask", "postprocess_adamantitepulse_masked")
--GenerateEntityMaskingShaders("mirror_mask", "postprocess_mirror_masked")

--local SamplerEffectBase = GLOBAL.SamplerEffectBase
--local SamplerEffects = GLOBAL.SamplerEffects

AddModShadersInit(function()
    local PostProcessorEffects = GLOBAL.PostProcessorEffects
    local PostProcessor = GLOBAL.PostProcessor
    PostProcessorEffects.HALLUC = PostProcessor:AddPostProcessEffect(MODROOT.."shaders/misc.ksh")

    

    --PostProcessorEffects.AdamantitePulse = PostProcessor:AddPostProcessEffect(MODROOT.."shaders/adamantitepulse.ksh") -- Creates the shader
    --PostProcessor:AddSampler(PostProcessorEffects.AdamantitePulse, SamplerEffectBase.Shader, SamplerEffects["postprocess_adamantitepulse_masked"]) -- Adds the "masked" shader as a sampler indexed 1

    --PostProcessorEffects.Mirror = PostProcessor:AddPostProcessEffect(MODROOT.."shaders/mirror.ksh") -- Creates the shader
    --PostProcessor:AddSampler(PostProcessorEffects.Mirror, SamplerEffectBase.Shader, SamplerEffects["postprocess_mirror_masked"]) -- Adds the "masked" shader as a sampler indexed 1

end)


AddModShadersSortAndEnable(function()
    local PostProcessorEffects = GLOBAL.PostProcessorEffects
    local PostProcessor = GLOBAL.PostProcessor
    PostProcessor:SetPostProcessEffectAfter(PostProcessorEffects.HALLUC, PostProcessorEffects.Lunacy)
    PostProcessor:EnablePostProcessEffect(PostProcessorEffects.HALLUC, false)

    --PostProcessor:SetPostProcessEffectBefore(PostProcessorEffects.AdamantitePulse,PostProcessorEffects.Bloom) -- Always set your shader to run before Bloom
    --PostProcessor:EnablePostProcessEffect(PostProcessorEffects.AdamantitePulse, false) -- Enables the shader

    --PostProcessor:SetPostProcessEffectBefore(PostProcessorEffects.Mirror,PostProcessorEffects.Bloom) -- Always set your shader to run before Bloom
    --PostProcessor:EnablePostProcessEffect(PostProcessorEffects.Mirror, false) -- Enables the shader
end)