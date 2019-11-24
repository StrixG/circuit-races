Assets = {}

function Assets.load()
  Assets.confirmation = DxFont("assets/FiraSansCondensed-Regular.ttf", 36)
  Assets.text = DxFont("assets/FiraSansCondensed-Medium.ttf", 16)
  Assets.trackName = DxFont("assets/FiraSansCondensed-Medium.ttf", 24)
  Assets.bold = DxFont("assets/FiraSansCondensed-Bold.ttf", 24)
  Assets.time = DxFont("assets/OpenSans-BoldItalic.ttf", 36)
  Assets.timeSmall = DxFont("assets/OpenSans-BoldItalic.ttf", 18)
end

addEventHandler("onClientResourceStart", resourceRoot, Assets.load)