Assets = {}

function Assets.load()
  Assets.confirmation = DxFont("assets/FiraSansCondensed-Regular.ttf", 36)
  Assets.text = DxFont("assets/FiraSansCondensed-Medium.ttf", 16)
  Assets.medium = DxFont("assets/FiraSansCondensed-Medium.ttf", 24)
  Assets.bold = DxFont("assets/FiraSansCondensed-Bold.ttf", 24)
  Assets.time = DxFont("assets/OpenSans-BoldItalic.ttf", 36)
end

addEventHandler("onClientResourceStart", resourceRoot, Assets.load)