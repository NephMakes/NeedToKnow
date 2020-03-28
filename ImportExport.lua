-- Import and export bar settings as concise string

local addonName, addonTable = ...

NEEDTOKNOW.SHORTENINGS= {
    Enabled         = "On",
    AuraName        = "Aura",
    --Unit            = "Unit",
    BuffOrDebuff    = "Typ",
    OnlyMine        = "Min",
    BarColor        = "Clr",
    MissingBlink    = "BCl",
    TimeFormat      = "TF",
    vct_enabled     = "VOn",
    vct_color       = "VCl",
    vct_spell       = "VSp",
    vct_extra       = "VEx",
    bDetectExtends  = "Ext",
    show_text       = "sTx",
    show_count      = "sCt",
    show_time       = "sTm",
    show_spark      = "sSp",
    show_icon       = "sIc",
    show_mypip      = "sPp",
    show_all_stacks = "All",
    show_charges    = "Chg",
    show_text_user  = "sUr",
    show_ttn1       = "sN1",
    show_ttn2       = "sN2",
    show_ttn3       = "sN3",
    blink_enabled   = "BOn",
    blink_ooc       = "BOC",
    blink_boss      = "BBs",
    blink_label     = "BTx",
    buffcd_duration = "cdd",
    buffcd_reset_spells = "cdr",
    usable_duration = "udr",
    append_cd       = "acd",
    append_usable   = "aus",
    --NumberBars       = "NmB",
    --Scale            = "Scl",
    --Width            = "Cx",
    --Bars             = "Brs",
    --Position         = "Pos",
    --FixedDuration    = "FxD", 
    --Version       = "Ver",
    --OldVersion  = "OVr",
    --Profiles    = "Pfl",
    --Chars       = "Chr",
    --Specs       = "Spc",
    --Locked      = "Lck",
    --name        = "nam",
    --nGroups     = "nGr",
    --Groups      = "Grp",
    --BarTexture  = "Tex",
    --BarFont     = "Fnt",
    --BkgdColor   = "BgC",
    --BarSpacing  = "BSp",
    --BarPadding  = "BPd",
    --FontSize    = "FSz",
    --FontOutline = "FOl",
}

NEEDTOKNOW.LENGTHENINGS= {
   On = "Enabled",
   Aura = "AuraName",
--   Unit = "Unit",
   Typ = "BuffOrDebuff",
   Min = "OnlyMine",
   Clr = "BarColor",
   BCl = "MissingBlink",
   TF  = "TimeFormat",
   VOn = "vct_enabled",
   VCl = "vct_color",
   VSp = "vct_spell",
   VEx = "vct_extra",
   Ext = "bDetectExtends",
   sTx = "show_text",
   sCt = "show_count",
   sN1 = "show_ttn1",
   sN2 = "show_ttn2",
   sN3 = "show_ttn3",
   sTm = "show_time",
   sSp = "show_spark",
   sIc = "show_icon",
   sPp = "show_mypip",
   All = "show_all_stacks",
   Chg = "show_charges",
   sUr = "show_text_user",
   BOn = "blink_enabled",
   BOC = "blink_ooc",
   BBs = "blink_boss",
   BTx = "blink_label",
   cdd = "buffcd_duration",
   cdr = "buffcd_reset_spells",
   udr = "usable_duration",
   acd = "append_cd",
   aus = "append_usable",
    --NumberBars       = "NmB",
    --Scale            = "Scl",
    --Width            = "Cx",
    --Bars             = "Brs",
    --Position         = "Pos",
    --FixedDuration    = "FxD", 
    --Version       = "Ver",
    --OldVersion  = "OVr",
    --Profiles    = "Pfl",
    --Chars       = "Chr",
    --Specs       = "Spc",
    --Locked      = "Lck",
    --name can't be compressed since it's used even when not the active profile
    --nGroups     = "nGr",
    --Groups      = "Grp",
    --BarTexture  = "Tex",
    --BarFont     = "Fnt",
    --BkgdColor   = "BgC",
    --BarSpacing  = "BSp",
    --BarPadding  = "BPd",
    --FontSize    = "FSz",
    --FontOutline = "FOl";
}

function NeedToKnowIE.CombineKeyValue(key,value)
    local vClean = value
    if type(vClean) == "string" and value:byte(1) ~= 123 then
        if (tostring(tonumber(vClean)) == vClean) or vClean == "true" or vClean == "false" then
            vClean = '"' .. vClean .. '"'
        elseif (vClean:find(",") or vClean:find("}") or vClean:byte(1) == 34) then
            vClean = '"' .. tostring(value):gsub('"', '\\"') .. '"'
        end
    end

    if key then
        -- not possible for key to contain = right now, so we don't have to sanitize it
        return key .. "=" .. tostring(vClean)
    else
        return vClean
    end
end

function NeedToKnowIE.TableToString(v)
    local i = 1
    local ret= "{"
    for index, value in pairs(v) do
        if i ~= 1 then
            ret = ret .. ","
        end
        local k
        if index ~= i then
            k = NEEDTOKNOW.SHORTENINGS[index] or index 
        end
        if  type(value) == "table" then
            value = NeedToKnowIE.TableToString(value)
        end
        ret = ret .. NeedToKnowIE.CombineKeyValue(k, value)
        i = i+1;
    end
    ret = ret .. "}"
    return ret
end

function NeedToKnowIE.ExportBarSettingsToString(barSettings)
    local pruned = CopyTable(barSettings)
    NeedToKnow.RemoveDefaultValues(pruned, NEEDTOKNOW.BAR_DEFAULTS)
    return 'bv1:' .. NeedToKnowIE.TableToString(pruned);
end

--[[ Test Cases
/script MemberDump( NeedToKnowIE.StringToTable( '{a,b,c}' ) )
    members
      1 a
      2 b
      3 c

/script MemberDump( NeedToKnowIE.StringToTable( '{Aura=Frost Fever,Unit=target,Clr={g=0.4471,r=0.2784},Typ=HARMFUL}' ) )
    members
      BuffOrDebuff HARMFUL
      BarColor table: 216B04C0
      |  g 0.4471
      |  r 0.2784
      AuraName Frost Fever
      Unit target

/script MemberDump( NeedToKnowIE.StringToTable( '{"a","b","c"}' ) )
    members
      1 a
      2 b
      3 c

/script MemberDump( NeedToKnowIE.StringToTable( '{"a,b","b=c","{c={d}}"}' ) )
    members
      1 a,b
      2 b=c
      3 {c={d}}

/script local t = {'\\",\'','}'} local p = NeedToKnowIE.TableToString(t) print (p) MemberDump( NeedToKnowIE.StringToTable( p ) )
    {"\\",'","}"}
    members
      1 \",'
      2 }

/script local p = NeedToKnowIE.TableToString( {} ) print (p) MemberDump( NeedToKnowIE.StringToTable( p ) )
    {}
    members

    I don't think this can come up, but might as well be robust
/script local p = NeedToKnowIE.TableToString( {{{}}} ) print (p) MemberDump( NeedToKnowIE.StringToTable( p ) )
    {{{}}}
    members
      1 table: 216A2428
      |  1 table: 216A0510

    I don't think this can come up, but might as well be robust
/script local p = NeedToKnowIE.TableToString( {{{"a"}}} ) print (p) MemberDump( NeedToKnowIE.StringToTable( p ) )
    {{{a}}}
    members
      1 table: 27D68048
      |  1 table: 27D68098
      |  |  1 a

    User Error                                   1234567890123456789012
/script MemberDump( NeedToKnowIE.StringToTable( '{"a,b","b=c","{c={d}}",{' ) )
    Unexpected end of string
    nil

    User Error                                   1234567890123456789012
/script MemberDump( NeedToKnowIE.StringToTable( '{"a,b","b=c""{c={d}}"' ) )
    Illegal quote at 12
    nil
]]--

function NeedToKnowIE.StringToTable(text, ofs)
    local cur = ofs or 1

    if text:byte(cur+1) == 125 then
        return {},cur+1
    end

    local i = 0
    local ret = {}
    while text:byte(cur) ~= 125 do
        if not text:byte(cur) then
            print("Unexpected end of string")
            return nil,nil
        end
        i = i + 1
        cur = cur + 1 -- advance past the { or ,
        local hasKey, eq, delim
        -- If it's not a quote or a {, it should be a key+equals or value+delimeter
        if text:byte(cur) ~= 34 and text:byte(cur) ~= 123 then 
            eq = text:find("=", cur)
            local comma = text:find(",", cur) 
            delim = text:find("}", cur) or comma
            if comma and delim > comma then
                delim = comma 
            end

            if not delim then 
                print("Unexpected end of string")
                return nil, nil
            end
            hasKey = (eq and eq < delim)
        end

        local k,v
        if not hasKey then
            k = i
        else
            k = text:sub(cur,eq-1)
            k = NEEDTOKNOW.LENGTHENINGS[k] or k
            if not k or k == "" then
                print("Error parsing key at", cur)
                return nil,nil
            end
            cur = eq+1
        end

        if not text:byte(cur) then 
            print("Unexpected end of string")
            return nil,nil
        elseif text:byte(cur) == 123 then -- '{'
            v, cur = NeedToKnowIE.StringToTable(text, cur)
            if not v then return nil,nil end
            cur = cur+1
        else
            if text:byte(cur) == 34 then -- '"'
                -- find the closing quote
                local endq = cur
                delim=nil
                while not delim do
                    endq = text:find('"', endq+1)
                    if not endq then
                        print("Could not find closing quote begun at", cur)
                        return nil, nil
                    end
                    if text:byte(endq-1) ~= 92 then -- \
                        delim = endq+1
                        if text:byte(delim) ~= 125 and text:byte(delim) ~= 44 then
                            print("Illegal quote at", endq)
                            return nil, nil
                        end
                    end
                end
                v = text:sub(cur+1,delim-2)
                v = gsub(v, '\\"', '"')
            else
                v = text:sub(cur,delim-1)
                local n = tonumber(v)
                if tostring(n) == v  then
                    v = n
                elseif v == "true" then
                    v = true
                elseif v == "false" then
                    v = false
                end
            end
            if v==nil or v == "" then
                print("Error parsing value at",cur)
            end
            cur = delim
        end

        ret[k] = v
    end

    return ret,cur
end

function NeedToKnowIE.ImportBarSettingsFromString(text, bars, barID)
    local pruned
    if text and text ~= "" then
        local ver, packed = text:match("bv(%d+):(.*)")
        if not ver then
            print("Could not find bar settings header")
        elseif not packed then
            print("Could not find bar settings")
        end
        pruned = NeedToKnowIE.StringToTable(packed)
    else
        pruned = {}
    end

    if pruned then
        NeedToKnow.AddDefaultsToTable(pruned, NEEDTOKNOW.BAR_DEFAULTS)
        bars[barID] = pruned
    end
end
