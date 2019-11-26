Assets = {}

function Assets.load()
  Assets.fonts = {}
  Assets.fonts.confirmation = DxFont("assets/FiraSansCondensed-Regular.ttf", 36)
  Assets.fonts.text = DxFont("assets/FiraSansCondensed-Medium.ttf", 16)
  Assets.fonts.trackName = DxFont("assets/FiraSansCondensed-Medium.ttf", 24)
  Assets.fonts.bold = DxFont("assets/FiraSansCondensed-Bold.ttf", 24)
  Assets.fonts.time = DxFont("assets/OpenSans-BoldItalic.ttf", 36)
  Assets.fonts.timeSmall = DxFont("assets/OpenSans-BoldItalic.ttf", 18)
end

addEventHandler("onClientResourceStart", resourceRoot, Assets.load)