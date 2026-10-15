--!nonstrict
-- Repo-only visual prototype. It deliberately performs no I/O, shell command,
-- network request, service mutation, wallpaper change, or theme write.

local page = "overview"
local mood = "Calm"

local function sectionTitle(glyph, title, detail)
  return ui.row({ gap = 10, align = "center" }, {
    ui.glyph({ name = glyph, size = 18, color = "primary" }),
    ui.column({ gap = 2, flexGrow = 1 }, {
      ui.label({ text = title, fontSize = 16, fontWeight = "bold", color = "on_surface" }),
      ui.label({ text = detail, fontSize = 12, color = "on_surface_variant" }),
    }),
  })
end

local function metric(glyph, label, value, accent)
  return ui.column({
    gap = 8,
    padding = 14,
    radius = 18,
    fill = "surface_variant/0.28",
    border = "outline/0.28",
    flexGrow = 1,
  }, {
    ui.row({ gap = 8, align = "center" }, {
      ui.glyph({ name = glyph, size = 15, color = accent }),
      ui.label({ text = label, fontSize = 12, color = "on_surface_variant", flexGrow = 1 }),
    }),
    ui.label({ text = value, fontSize = 20, fontWeight = "bold", color = "on_surface" }),
  })
end

local function navigationButton(label, glyph, target)
  return ui.button({
    text = label,
    glyph = glyph,
    contentAlign = "start",
    variant = page == target and "primary" or "ghost",
    selected = page == target,
    onClick = function()
      page = target
      render()
    end,
  })
end

local function overviewPage()
  return ui.row({ gap = 18, align = "stretch", flexGrow = 1 }, {
    ui.column({ gap = 16, flexGrow = 2 }, {
      ui.column({
        gap = 18,
        padding = 24,
        radius = 24,
        fill = "surface_variant/0.22",
        border = "outline/0.24",
        flexGrow = 1,
      }, {
        ui.row({ align = "center", justify = "space_between", gap = 16 }, {
          ui.column({ gap = 4, flexGrow = 1 }, {
            ui.label({ text = "A quieter place to begin", fontSize = 28, fontWeight = "bold", color = "on_surface" }),
            ui.label({ text = "The desktop stays restrained; richer context appears only on demand.", color = "on_surface_variant" }),
          }),
          ui.glyph({ name = "sparkles", size = 34, color = "primary" }),
        }),
        ui.column({ gap = 8, padding = 18, radius = 20, fill = "surface/0.62" }, {
          ui.label({ text = "Now playing", fontSize = 12, color = "primary", fontWeight = "bold" }),
          ui.label({ text = "Nothing competing for attention", fontSize = 20, fontWeight = "medium" }),
          ui.label({ text = "Media controls appear here when a player is active.", color = "on_surface_variant" }),
          ui.row({ gap = 8, align = "center" }, {
            ui.button({ glyph = "player-skip-back", variant = "ghost", enabled = false }),
            ui.button({ glyph = "player-play", variant = "primary", enabled = false }),
            ui.button({ glyph = "player-skip-forward", variant = "ghost", enabled = false }),
          }),
        }),
      }),
      ui.row({ gap = 12, align = "stretch" }, {
        metric("cpu", "Compute", "—", "primary"),
        metric("brain", "Llama", "protected", "secondary"),
        metric("temperature", "Thermals", "—", "tertiary"),
      }),
    }),
    ui.column({
      gap = 16,
      padding = 20,
      radius = 24,
      fill = "surface_variant/0.18",
      border = "outline/0.24",
      flexGrow = 1,
    }, {
      sectionTitle("calendar", "Today", "Information without visual noise"),
      ui.separator({ spacing = 2 }),
      ui.label({ text = "No events connected", fontSize = 16, fontWeight = "medium" }),
      ui.label({ text = "Calendar data stays disconnected in this prototype.", color = "on_surface_variant" }),
      ui.separator({ spacing = 2 }),
      sectionTitle("cloud", "Weather", "Designed empty state"),
      ui.label({ text = "Location not requested", fontSize = 16, fontWeight = "medium" }),
      ui.label({ text = "Useful surfaces explain absence instead of filling space with placeholders.", color = "on_surface_variant" }),
    }),
  })
end

local function moodButton(label, detail)
  return ui.button({
    text = label .. " · " .. detail,
    contentAlign = "start",
    selected = mood == label,
    variant = mood == label and "primary" or "ghost",
    onClick = function()
      mood = label
      render()
    end,
  })
end

local function wallpaperPage()
  return ui.row({ gap = 18, align = "stretch", flexGrow = 1 }, {
    ui.column({
      gap = 14,
      padding = 22,
      radius = 24,
      fill = "surface_variant/0.22",
      border = "outline/0.24",
      flexGrow = 2,
    }, {
      sectionTitle("photo", "Wallpaper stage", "Carousel composition will replace this neutral fixture"),
      ui.column({ gap = 12, padding = 28, radius = 22, fill = "surface/0.60", flexGrow = 1 }, {
        ui.glyph({ name = "landscape", size = 54, color = "primary" }),
        ui.label({ text = "Image preview deliberately disconnected", fontSize = 22, fontWeight = "bold" }),
        ui.label({ text = "Browsing may change this surface. Application themes change only after Apply.", color = "on_surface_variant" }),
      }),
      ui.label({ text = "Esc restores the starting wallpaper and mood", fontSize = 12, color = "on_surface_variant" }),
    }),
    ui.column({
      gap = 12,
      padding = 20,
      radius = 24,
      fill = "surface_variant/0.18",
      border = "outline/0.24",
      flexGrow = 1,
    }, {
      sectionTitle("palette", "Theme mood", "Prototype selection only"),
      moodButton("Calm", "soft and low-chroma"),
      moodButton("Vivid", "selective high-chroma accents"),
      moodButton("Mono", "near-monochrome and quiet"),
      ui.separator({ spacing = 4 }),
      ui.label({ text = "Selected: " .. mood, fontWeight = "bold", color = "primary" }),
      ui.label({ text = "No wallpaper, palette, or application file is written by this prototype.", color = "on_surface_variant" }),
      ui.row({ gap = 8, align = "center" }, {
        ui.button({ text = "Cancel", variant = "ghost", enabled = false }),
        ui.button({ text = "Apply", variant = "primary", enabled = false }),
      }),
    }),
  })
end

local function systemPage()
  return ui.column({ gap = 16, flexGrow = 1 }, {
    sectionTitle("activity", "System overview", "Static layout and empty-state study"),
    ui.row({ gap = 12, align = "stretch" }, {
      metric("cpu", "CPU", "not sampled", "primary"),
      metric("device-desktop-analytics", "GPU", "not sampled", "secondary"),
      metric("database", "Memory", "not sampled", "tertiary"),
    }),
    ui.column({ gap = 10, padding = 20, radius = 22, fill = "surface_variant/0.20", border = "outline/0.24" }, {
      ui.label({ text = "Operational boundary", fontSize = 18, fontWeight = "bold" }),
      ui.label({ text = "Quiet Core owns composition. The existing Llama Control plugin remains the owner of model, power, service, and log actions.", color = "on_surface_variant" }),
      ui.label({ text = "This separation prevents a visual prototype from touching the protected workload.", color = "primary" }),
    }),
  })
end

function render()
  local content = overviewPage()
  if page == "wallpaper" then
    content = wallpaperPage()
  elseif page == "system" then
    content = systemPage()
  end

  panel.render(ui.column({ gap = 18, flexGrow = 1 }, {
    ui.row({ align = "center", justify = "space_between", gap = 12 }, {
      ui.row({ gap = 10, align = "center", flexGrow = 1 }, {
        ui.glyph({ name = "sparkles", size = 20, color = "primary" }),
        ui.label({ text = "Quiet Core", fontSize = 20, fontWeight = "bold" }),
        ui.label({ text = "visual prototype", fontSize = 12, color = "on_surface_variant" }),
      }),
      ui.button({ glyph = "close", variant = "ghost", onClick = "onCloseClicked" }),
    }),
    ui.row({ gap = 18, align = "stretch", flexGrow = 1 }, {
      ui.column({
        gap = 8,
        padding = 10,
        radius = 20,
        fill = "surface_variant/0.16",
        border = "outline/0.20",
        width = 176,
      }, {
        navigationButton("Overview", "dashboard", "overview"),
        navigationButton("Wallpaper", "photo", "wallpaper"),
        navigationButton("System", "activity", "system"),
        ui.separator({ spacing = 8 }),
        ui.label({ text = "Dark · wallpaper-led", fontSize = 12, color = "on_surface_variant" }),
        ui.label({ text = "No live actions", fontSize = 12, color = "primary" }),
      }),
      ui.column({ flexGrow = 1 }, { content }),
    }),
  }))
end

function onOpen(_context)
  render()
end

function onCloseClicked()
  panel.close()
end
