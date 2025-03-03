--[[
from:
name = "[CESapi] Custom Entity Shaders API BETA"
description = 
Custom Entity Shaders API is a tool designed to give modders more control over entity shaders.
CESapi allows you to create custom uniform variables and samplers and pass them into entity shaders.

This API is still in BETA so some bugs may be showing!

author = "LukaS"
version = "0.1.0"
forumthread = ""
icon_atlas = "icon.xml"
icon = "icon.tex"
client_only_mod = true -- Custom shaders should always be created and loaded locally
all_clients_require_mod = false
dst_compatible = true
reign_of_giants_compatible = false
dont_starve_compatible = false
priority = 999999999 -- Load as early as possible
api_version = 10
]]

local _G = GLOBAL
local old_CreateEntity = _G.CreateEntity
_G.CreateEntity = function(name, ...)
    local ent = old_CreateEntity(name, ...)

    if name == "TheGlobalInstance" then
        local ent_metatable_index = _G.getmetatable(ent.entity).__index
        local old_AddPostProcessor = ent_metatable_index.AddPostProcessor
        ent_metatable_index.AddPostProcessor = function(...)
            local postprocessor = old_AddPostProcessor(...)
            local postprocessor_metatable_index = _G.getmetatable(postprocessor).__index
            local old_SetBloomSamplerParams = postprocessor_metatable_index.SetBloomSamplerParams
            postprocessor_metatable_index.SetBloomSamplerParams = function(self, sampler_size, size_x, size_w, sampler_colour_mode, ...)
                if sampler_size == _G.SamplerSizes.Relative then
                    size_x = 1
                    size_w = 1
                end

                sampler_colour_mode = _G.SamplerColourMode.RGBA

                return old_SetBloomSamplerParams(self, sampler_size, size_x, size_w, sampler_colour_mode, ...)
            end

            return postprocessor
        end

        _G.CreateEntity = old_CreateEntity
    end

    return ent
end

table.insert(Assets, Asset("SHADER", "shaders/CESBloom.ksh"))
table.insert(Assets, Asset("SHADER", "shaders/postprocess_CESBloom.ksh"))

AddModShadersInit(function()
    _G.SamplerEffects["CESBloomSampler"] = _G.PostProcessor:AddSamplerEffect(_G.resolvefilepath("shaders/postprocess_CESBloom.ksh"), _G.SamplerSizes.Relative, 1, 1, _G.SamplerColourMode.RGB, _G.SamplerEffectBase.BloomSampler)
    _G.PostProcessor:AddSampler(_G.SamplerEffects["CESBloomSampler"], _G.SamplerEffectBase.PostProcessSampler)
    _G.PostProcessor:SetEffectUniformVariables(_G.SamplerEffects["CESBloomSampler"], _G.UniformVariables.SAMPLER_PARAMS)
    _G.PostProcessor:SetSamplerEffectFilter(_G.SamplerEffects["CESBloomSampler"], _G.FILTER_MODE.LINEAR, _G.FILTER_MODE.LINEAR, _G.MIP_FILTER_MODE.NONE)

    _G.SamplerEffects.CESBlurH = _G.PostProcessor:AddSamplerEffect("shaders/blurh.ksh", _G.SamplerSizes.Relative, 0.25, 0.25, _G.SamplerColourMode.RGB, _G.SamplerEffectBase.Shader, _G.SamplerEffects["CESBloomSampler"])
    _G.PostProcessor:SetEffectUniformVariables(_G.SamplerEffects.CESBlurH, _G.UniformVariables.SAMPLER_PARAMS)

    _G.SamplerEffects.CESBlurV = _G.PostProcessor:AddSamplerEffect("shaders/blurv.ksh", _G.SamplerSizes.Relative, 0.25, 0.25, _G.SamplerColourMode.RGB, _G.SamplerEffectBase.Shader, _G.SamplerEffects.CESBlurH)
    _G.PostProcessor:SetEffectUniformVariables(_G.SamplerEffects.CESBlurV, _G.UniformVariables.SAMPLER_PARAMS)

    _G.PostProcessor:SetSamplerEffectFilter(_G.SamplerEffects.CESBlurV, _G.FILTER_MODE.LINEAR, _G.FILTER_MODE.LINEAR, _G.MIP_FILTER_MODE.NONE)

    _G.PostProcessorEffects.CESBloom = _G.PostProcessor:AddPostProcessEffect("shaders/postprocess_bloom.ksh")
    _G.PostProcessor:AddSampler(_G.PostProcessorEffects.CESBloom, _G.SamplerEffectBase.Shader, _G.SamplerEffects.CESBlurV)
end)

AddModShadersSortAndEnable(function()
    _G.PostProcessor:SetPostProcessEffectBefore(_G.PostProcessorEffects.CESBloom, _G.PostProcessorEffects.Bloom)
    _G.PostProcessor:EnablePostProcessEffect(_G.PostProcessorEffects.CESBloom, true)
end)

_G.CESAPI_BASE_ENTITY_MASK_SHADER_NAME = "entitymask_base"
_G.CESAPI_BASE_POSTPROCESS_MASKED_SHADER_NAME = "postprocess_entitymasked_base"

local CESAPI_ENTITY_SHADER_BASE_COLOR_INDEX = { 0.01, 0.01, 0.01 } -- 0.01 is the minimum, 1.0 is reserved for bloom
_G.CESAPI_ENTITY_SHADER_MAX_INDEX = 99 * 99 * 99 -- 970299 different unique masks, should be enough

CESAPI_ENTITY_MASKING_SHADERS = {
    ["bloommask"] = {
        i = 0,
        color = { 1.0, 1.0, 1.0 }
    }
}

local function GetColorIndex(i)
    i = i - 1 -- Covering for the index offset
    local i1 = 1 + i % 100
    local i2 = 1 + math.floor(i / 100)
    local i3 = 1 + math.floor(i / 10000)

    return {CESAPI_ENTITY_SHADER_BASE_COLOR_INDEX[1] * i1,CESAPI_ENTITY_SHADER_BASE_COLOR_INDEX[2] * i2, CESAPI_ENTITY_SHADER_BASE_COLOR_INDEX[3] * i3 }
end

local ENTITY_SHADER_INDEX = 0

GenerateEntityMaskingShaders = function(maskshadername, postprocess_maskedshadername)

    _G.assert(postprocess_maskedshadername ~= nil,"Missing postprocess masking shader name!")
    _G.assert(ENTITY_SHADER_INDEX < _G.CESAPI_ENTITY_SHADER_MAX_INDEX, "Reached the max ("..tostring(_G.CESAPI_ENTITY_SHADER_MAX_INDEX)..") number of entity masking shaders!")

    local color_index

    -- Entity masking shader
    ENTITY_SHADER_INDEX = ENTITY_SHADER_INDEX + 1
    color_index = GetColorIndex(ENTITY_SHADER_INDEX)

    CESAPI_ENTITY_MASKING_SHADERS[maskshadername] = {
        i = ENTITY_SHADER_INDEX,
        color = color_index
    }

    table.insert(Assets, Asset("SHADER", "shaders/"..maskshadername..".ksh"))
    table.insert(Assets, Asset("SHADER", "shaders/"..postprocess_maskedshadername..".ksh"))

    AddModShadersInit(function()
        _G.SamplerEffects[postprocess_maskedshadername] = _G.PostProcessor:AddSamplerEffect(MODROOT.."shaders/"..postprocess_maskedshadername..".ksh", _G.SamplerSizes.Relative, 1, 1, _G.SamplerColourMode.RGBA, _G.SamplerEffectBase.BloomSampler)
        _G.PostProcessor:AddSampler(_G.SamplerEffects[postprocess_maskedshadername], _G.SamplerEffectBase.PostProcessSampler)
        _G.PostProcessor:SetEffectUniformVariables(_G.SamplerEffects[postprocess_maskedshadername], _G.UniformVariables.SAMPLER_PARAMS)
        _G.PostProcessor:SetSamplerEffectFilter(_G.SamplerEffects[postprocess_maskedshadername], _G.FILTER_MODE.LINEAR, _G.FILTER_MODE.LINEAR, _G.MIP_FILTER_MODE.NONE)
    end)

end


table.insert(Assets, Asset("SHADER", "shaders/CESBloom.ksh"))
table.insert(Assets, Asset("SHADER", "shaders/postprocess_CESBloom.ksh"))

AddModShadersInit(function()
    _G.SamplerEffects["CESBloomSampler"] = _G.PostProcessor:AddSamplerEffect(MODROOT.."shaders/postprocess_CESBloom.ksh", _G.SamplerSizes.Relative, 1, 1, _G.SamplerColourMode.RGB, _G.SamplerEffectBase.BloomSampler)
    _G.PostProcessor:AddSampler(_G.SamplerEffects["CESBloomSampler"], _G.SamplerEffectBase.PostProcessSampler)
    _G.PostProcessor:SetEffectUniformVariables(_G.SamplerEffects["CESBloomSampler"], _G.UniformVariables.SAMPLER_PARAMS)
    _G.PostProcessor:SetSamplerEffectFilter(_G.SamplerEffects["CESBloomSampler"], _G.FILTER_MODE.LINEAR, _G.FILTER_MODE.LINEAR, _G.MIP_FILTER_MODE.NONE)

    _G.SamplerEffects.CESBlurH = _G.PostProcessor:AddSamplerEffect("shaders/blurh.ksh", _G.SamplerSizes.Relative, 0.25, 0.25, _G.SamplerColourMode.RGB, _G.SamplerEffectBase.Shader, _G.SamplerEffects["CESBloomSampler"])
    _G.PostProcessor:SetEffectUniformVariables(_G.SamplerEffects.CESBlurH, _G.UniformVariables.SAMPLER_PARAMS)

    _G.SamplerEffects.CESBlurV = _G.PostProcessor:AddSamplerEffect("shaders/blurv.ksh", _G.SamplerSizes.Relative, 0.25, 0.25, _G.SamplerColourMode.RGB, _G.SamplerEffectBase.Shader, _G.SamplerEffects.CESBlurH)
    _G.PostProcessor:SetEffectUniformVariables(_G.SamplerEffects.CESBlurV, _G.UniformVariables.SAMPLER_PARAMS)

    _G.PostProcessor:SetSamplerEffectFilter(_G.SamplerEffects.CESBlurV, _G.FILTER_MODE.LINEAR, _G.FILTER_MODE.LINEAR, _G.MIP_FILTER_MODE.NONE)

    _G.PostProcessorEffects.CESBloom = _G.PostProcessor:AddPostProcessEffect("shaders/postprocess_bloom.ksh")
    _G.PostProcessor:AddSampler(_G.PostProcessorEffects.CESBloom, _G.SamplerEffectBase.Shader, _G.SamplerEffects.CESBlurV)
end)

AddModShadersSortAndEnable(function()
    _G.PostProcessor:SetPostProcessEffectBefore(_G.PostProcessorEffects.CESBloom, _G.PostProcessorEffects.Bloom)
    _G.PostProcessor:EnablePostProcessEffect(_G.PostProcessorEffects.CESBloom, true)
end)