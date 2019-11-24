Assets = {}

function Assets.load()
  Assets.medium = DxFont("assets/FiraSansCondensed-Medium.ttf", 24)
  Assets.bold = DxFont("assets/FiraSansCondensed-Bold.ttf", 24)
  Assets.boldItalic = DxFont("assets/FiraSansCondensed-BoldItalic.ttf", 36)
end

addEventHandler("onClientResourceStart", resourceRoot, Assets.load)