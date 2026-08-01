-- Deutsch für Pokémon Gelbe Edition in Gen1Recomp.
--
-- Translates the imported US Pokémon Yellow dataset without modifying or
-- redistributing the player's ROM.
return function(mod)
  local GameVersion = require("src.core.GameVersion")
  if GameVersion.get() ~= "yellow" then
    mod.log:info("Deutsch für Pokémon Gelb: in dieser Edition nicht aktiv")
    return
  end

  -- mod:read is the supported way into your own directory; the catalogs are
  -- plain Lua tables, so read and run them rather than require()ing them.
  local function catalog(name)
    local rel = "lang/" .. name .. ".lua"
    local body = mod:read(rel)
    if not body then return {} end
    local chunk, err = loadstring(body, rel)
    if not chunk then
      mod.log:warn("%s has a syntax error: %s", rel, tostring(err))
      return {}
    end
    local ok, table_ = pcall(chunk)
    if not ok or type(table_) ~= "table" then
      mod.log:warn("%s did not return a table: %s", rel, tostring(table_))
      return {}
    end
    return table_
  end

  -- An empty value means "not translated yet", never "translate to blank".
  local function each(name, apply)
    local n = 0
    for key, value in pairs(catalog(name)) do
      if type(value) == "string" and value ~= "" then
        apply(key, value)
        n = n + 1
      end
    end
    return n
  end

  -- The mod override supplies the complete original German ROM font.  These
  -- mappings expose its native umlaut and international character slots.
  local germanCharmap = catalog("charmap")
  local germanStatusLabels = catalog("status_labels")
  for seq, code in pairs(germanCharmap) do
    mod.content.font:register("charmap:" .. seq, { seq = seq, code = code })
  end

  -- ---- text ---------------------------------------------------------
  local counts = {}
  counts.dialogue = each("dialogue", function(id, value)
    mod.content.text:override(id, value)
  end)
  counts.dialogueAliases = each("dialogue_aliases", function(id, value)
    mod.content.text:register(id, value)
  end)
  local germanStrings = catalog("strings")
  counts.strings = 0
  for source, value in pairs(germanStrings) do
    if type(value) == "string" and value ~= "" then
      mod.content.strings:override(source, value)
      counts.strings = counts.strings + 1
    end
  end
  local runtimeText = catalog("runtime_text")
  local runtimeNames = {
    ["Yellow"] = "Gelb",
    ["YELLOW"] = "GELB",
    ["Pokemon Yellow"] = "Pokémon Gelbe Edition",
    ["Pokémon Yellow"] = "Pokémon Gelbe Edition",
    ["Yellow (alpha)"] = "Gelbe Edition",
    ["Yellow Version"] = "Gelbe Edition",
    ["YELLOW VERSION"] = "GELBE EDITION",
    ["Yellow Edition"] = "Gelbe Edition",
    ["YELLOW EDITION"] = "GELBE EDITION",
    ["POKéMON YELLOW"] = "POKéMON GELBE EDITION",
    ["Oak"] = "Eich",
    ["OAK"] = "EICH",
    ["PROF.OAK"] = "PROF.EICH",
  }
  for source, value in pairs(runtimeNames) do
    if germanStrings[source] == nil then
      mod.content.strings:register(source, value)
    end
  end
  counts.runtimeNames = 0
  for _ in pairs(runtimeNames) do
    counts.runtimeNames = counts.runtimeNames + 1
  end
  counts.runtimeText = 0
  for _ in pairs(runtimeText) do
    counts.runtimeText = counts.runtimeText + 1
  end
  local function localizeRuntimeText(text)
    if type(text) ~= "string" then return text end
    text = runtimeText[text] or germanStrings[text] or runtimeNames[text] or text
    text = text:gsub("^(.-) got\n(.-)!$", "%1 erhält\n%2!")
    text = text:gsub("^(.-) got a\nMAGIKARP!$", "%1 erhält ein\nKARPADOR!")
    text = text:gsub("^(.-) received\na NUGGET!$", "%1 erhält\nein NUGGET!")
    text = text:gsub(
      "^Oh, that's a\nBIKE VOUCHER!\f(.-) exchanged\nit for a BICYCLE!$",
      "Oh, ein\nRAD-COUPON!\f%1 tauscht den\nRAD-COUPON gegen\vdas FAHRRAD!")
    text = text:gsub("^(.-) exchanged\nit for a BICYCLE!$",
      "%1 tauscht den\nRAD-COUPON gegen\vdas FAHRRAD!")
    text = text:gsub("^(.-)\npopped out!$", "%1\nkommt heraus!")
    text = text:gsub("%f[%a]PROF%.OAK%f[%A]", "PROF.EICH")
    text = text:gsub("%f[%a]OAK%f[%A]", "EICH")
    text = text:gsub("%f[%a]Oak%f[%A]", "Eich")
    text = text:gsub("%f[%a]YELLOW EDITION%f[%A]", "GELBE EDITION")
    text = text:gsub("%f[%a]Yellow Edition%f[%A]", "Gelbe Edition")
    text = text:gsub("%f[%a]YELLOW VERSION%f[%A]", "GELBE EDITION")
    text = text:gsub("%f[%a]Yellow Version%f[%A]", "Gelbe Edition")
    text = text:gsub("%f[%a]POKéMON YELLOW%f[%A]", "POKéMON GELBE EDITION")
    text = text:gsub("%f[%a]YELLOW%f[%A]", "GELB")
    text = text:gsub("%f[%a]Yellow%f[%A]", "Gelb")
    text = text:gsub("HM(%d%d)", "VM%1")
    text = text:gsub("%f[%a]HITMONLEE%f[%A]", "KICKLEE")
    text = text:gsub("%f[%a]HITMONCHAN%f[%A]", "NOCKCHAN")
    return text
  end

  -- The launcher and title fallback draw edition metadata directly instead
  -- of going through Strings().  Keep all visible Yellow names German once
  -- this edition's translation mod is active.
  local yellowInfo = GameVersion.VERSIONS.yellow
  yellowInfo.label = "Gelb"
  yellowInfo.displayName = "Pokémon Gelbe Edition"
  yellowInfo.launcherName = "Gelbe Edition"

  -- Hand-ported scripts can pass raw literals straight to TextBox.new().
  -- Translate exact reviewed rows and dynamic proper names at that final
  -- display seam, without modifying save data or the imported US dataset.
  local TextBox = require("src.render.TextBox")
  if not TextBox.__deutschOriginalNew then
    TextBox.__deutschOriginalNew = TextBox.new
    TextBox.new = function(game, text, onDone, opts)
      return TextBox.__deutschOriginalNew(
        game, localizeRuntimeText(text), onDone, opts)
    end
  end
  -- These labels are generated dynamically by the naming screen and are
  -- therefore not present in the engine-string extraction worksheet.
  mod.content.strings:register("lower case", "klein")
  mod.content.strings:register("UPPER CASE", "GROSS")
  counts.namingLabels = 2
  counts.species = each("species_names", function(id, value)
    mod.content.pokemon:patch(id, { name = value })
  end)
  counts.dexKinds = each("dex_kinds", function(id, value)
    mod.content.pokemon:patch(id, { dexEntry = { kind = value } })
  end)
  counts.moves = each("move_names", function(id, value)
    mod.content.moves:patch(id, { name = value })
  end)
  counts.items = each("item_names", function(id, value)
    mod.content.items:patch(id, { name = value })
  end)
  counts.trainers = each("trainer_names", function(id, value)
    mod.content.trainers:patch(id, { name = value })
  end)
  counts.statuses = each("status_labels", function(id, value)
    mod.content.statuses:patch(id, { label = value, hudLabel = value })
  end)
  counts.types = each("type_names", function(id, value)
    mod.content.type_chart:patch(id, { name = value })
  end)

  -- Town Map names are ROM data but not part of the generator's standard
  -- translation catalogs, so patch the imported location records directly.
  local locations = {}
  counts.maps = each("map_names", function(id, value)
    locations[id] = { name = value }
  end)
  if next(locations) then
    mod.content.field:patch("townMap", { locations = locations })
  end

  -- Pokémon Yellow has no separate version ribbon: "GELBE EDITION" is baked
  -- into the logo tile sheet.  The later Pika bubble is also edition-specific
  -- because its rectangular ROM update contains surrounding logo tiles.
  mod.content.field:patch("title", {
    logo = {
      path = mod.path .. "/overrides/title/pokemon_logo.png",
      width = 128,
      height = 56,
    },
    pikaBubble = {
      path = mod.path .. "/overrides/title/pika_bubble.png",
      width = 56,
      height = 40,
    },
  })

  -- Battle modules reproduce the US ROM's PlaceMoveUsersName behavior by
  -- inserting "Enemy " after the string catalog has already been applied.
  -- They also pass the English stat-name table as dynamic text.  Localize
  -- those engine-generated fragments centrally, then enforce the original
  -- two-line/18-glyph battle-box layout for every composed message.
  local Font = require("src.render.Font")
  local BattleState = require("src.battle.BattleState")

  -- Battle HUDs read the translated statuses registry, but the party and
  -- summary menus draw mon.status (the internal PSN/SLP/etc. id) directly.
  -- Translate those exact status ids at the final font seam so every menu
  -- displays the German three-letter label without changing save/mechanics.
  if not Font.__deutschOriginalDraw then
    Font.__deutschOriginalDraw = Font.draw
    Font.draw = function(text, x, y)
      if type(text) == "string" and germanStatusLabels[text] then
        text = germanStatusLabels[text]
      end
      text = localizeRuntimeText(text)
      return Font.__deutschOriginalDraw(text, x, y)
    end
  end

  -- The imported US charmap already maps "é" to $BA, while the German ROM
  -- stores it at $BC.  Registry rows are merged beside the original row and
  -- Font.load sorts equal-length sequences without a deterministic tie-break,
  -- so the US code could still win and draw the German $BA glyph ("à").  Pin
  -- every German sequence to its verified German-ROM slot after splitting.
  if not Font.__deutschOriginalSplit then
    Font.__deutschOriginalSplit = Font.split
    Font.split = function(text)
      local spans = Font.__deutschOriginalSplit(text)
      for _, span in ipairs(spans) do
        local seq = text:sub(span.from, span.to)
        local code = germanCharmap[seq]
        if code then span.code = code end
      end
      return spans
    end
  end

  local battleTerms = {
    ["ATTACK"] = "ANGR",
    ["DEFENSE"] = "VERT",
    ["SPEED"] = "INIT",
    ["SPECIAL"] = "SPEZ",
    ["ACCURACY"] = "GENA",
    ["EVADE"] = "FLU",
    ["FOE"] = "GEGNER",
    ["OLD MAN"] = "ALTER MANN",
  }

  local function generatedBattleTerms(text)
    text = localizeRuntimeText(text)
    text = text:gsub("Enemy ", "Gegn. ")
    for source, translated in pairs(battleTerms) do
      text = text:gsub("%f[%a]" .. source .. "%f[%A]", translated)
    end
    return text
  end

  local function wrapBattleLine(line)
    local result = {}
    line = line:gsub("^ +", ""):gsub(" +$", "")
    while #Font.split(line) > 18 do
      local spans = Font.split(line)
      local cut, nextSpan = 18, 19
      for i = 18, 2, -1 do
        if line:sub(spans[i].from, spans[i].to) == " " then
          cut, nextSpan = i - 1, i + 1
          break
        end
      end
      result[#result + 1] = line:sub(spans[1].from, spans[cut].to)
      line = nextSpan <= #spans and line:sub(spans[nextSpan].from) or ""
      line = line:gsub("^ +", "")
    end
    result[#result + 1] = line
    return result
  end

  local function localizeBattleText(text)
    if type(text) ~= "string" then return text end
    -- Safety net for the trainer-switch fragment. In the normal path
    -- sayChoice rejoins it with the following Pokémon name, but if another
    -- mod displays the row early it must still never leak English.
    text = text:gsub("^(.-) is\nabout to use$", "%1 wird nun\neinsetzen:")
    text = text:gsub("^(.-) is about to use$", "%1 wird nun\neinsetzen:")
    text = generatedBattleTerms(text)
    local result, pos, lineNumber = {}, 1, 0
    while true do
      local controlAt = text:find("[\n\v\f]", pos)
      local line = controlAt and text:sub(pos, controlAt - 1)
                                or text:sub(pos)
      local wrapped = wrapBattleLine(line)
      for index, part in ipairs(wrapped) do
        if index > 1 then
          result[#result + 1] = lineNumber == 0 and "\n" or "\v"
          lineNumber = lineNumber + 1
        end
        result[#result + 1] = part
      end
      if not controlAt then break end
      local control = text:sub(controlAt, controlAt)
      if control == "\f" then
        result[#result + 1] = control
        lineNumber = 0
      else
        -- A third physical line uses the ROM's CONT behavior so it scrolls
        -- into the two-line box instead of appearing outside of it.
        result[#result + 1] =
          control == "\n" and lineNumber > 0 and "\v" or control
        lineNumber = lineNumber + 1
      end
      pos = controlAt + 1
    end
    return table.concat(result)
  end

  if not BattleState.__deutschOriginalStartMessage then
    BattleState.__deutschOriginalStartMessage = BattleState.startMessage
    BattleState.startMessage = function(self, item)
      if item and item.text then
        item.text = localizeBattleText(item.text)
      end
      return BattleState.__deutschOriginalStartMessage(self, item)
    end
  end

  -- EnemySendOutFirstMon builds _TrainerAboutToUseText as three independent
  -- English queue entries ("TRAINER is / about to use", "MON!", then the
  -- switch question).  Rejoin those fragments before they are displayed so
  -- the result follows the German ROM's complete sentence:
  --   TRAINER wird / MON in den / Kampf schicken!
  if not BattleState.__deutschOriginalSayChoice then
    BattleState.__deutschOriginalSayChoice = BattleState.sayChoice
    BattleState.sayChoice = function(self, text, onChoose)
      local queue = self.queue or {}
      local trainerName = self.trainer and self.trainer.name

      -- Find the last two text rows instead of assuming they are the final
      -- two queue entries. Animation/wait rows may be inserted between them
      -- by the battle flow or another compatible presentation mod.
      local monIndex, aboutIndex
      for index = #queue, 1, -1 do
        if type(queue[index].text) == "string" then
          if not monIndex then
            monIndex = index
          else
            aboutIndex = index
            break
          end
        end
      end
      local about = aboutIndex and queue[aboutIndex] or nil
      local mon = monIndex and queue[monIndex] or nil
      local nextName = mon and mon.text:match("^(.-)!$") or nil
      local aboutText = about and about.text
      local isSwitchQuestion = type(text) == "string"
        and (text:find("change POKéMON", 1, true)
          or text:find("POKéMON wechseln", 1, true))
      local isTrainerSwitch = type(aboutText) == "string"
        and type(trainerName) == "string"
        and isSwitchQuestion
        and (aboutText:find("about to use", 1, true)
          or aboutText:find("einsetzen:", 1, true)
          or aboutText:find("setzt gleich ein:", 1, true))
      if isTrainerSwitch and nextName and nextName ~= "" then
        about.text = trainerName .. " wird\n" .. nextName
          .. " in den\vKampf schicken!"
        table.remove(queue, monIndex)
        text = "Möchtest Du das\nPOKéMON wechseln?"
      end
      return BattleState.__deutschOriginalSayChoice(self, text, onChoose)
    end
  end

  -- German defaults for a new game. Player-entered names and existing saves
  -- remain untouched.
  mod.content.field:patch("boot", {
    playerName = "GELB",
    rivalName = "BLAU",
  })

  -- ---- name entry ---------------------------------------------------
  -- The naming screen's letter grid.  Leave lang/naming.lua returning nil
  -- to keep the English alphabet.
  local grid = catalog("naming")
  if grid.upper then
    mod.hooks:wrap("ui.naming.grid", function(next, base, ctx)
      base = next(base, ctx)
      local want = ctx.lower and grid.lower or grid.upper
      return want or base
    end)
  end

  mod.events:on("game.ready", function()
    local total = 0
    for _, n in pairs(counts) do total = total + n end
    mod.log:info("Deutsch: %d Einträge geladen", total)
  end)
end
