--!nonstrict
-- Inert entry point for the repo-only Quiet Core visual prototype.

local function render()
  barWidget.setGlyph("sparkles")
  barWidget.setText("")
  barWidget.setTooltip("Open the Quiet Core dashboard prototype")
end

function update()
  noctalia.setUpdateInterval(60000)
  render()
end

function onClick()
  noctalia.togglePanel("samh/quiet-core:dashboard")
end
