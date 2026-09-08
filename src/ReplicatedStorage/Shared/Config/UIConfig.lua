local UIConfig = {}

UIConfig.Colors = {
	Ocean = Color3.fromHex("#164A63"),
	Seafoam = Color3.fromHex("#72C7B5"),
	Gold = Color3.fromHex("#F5C95B"),
	Danger = Color3.fromHex("#E66A5C"),
	Success = Color3.fromHex("#65B875"),
	Background = Color3.fromHex("#F7F3EA"),
	Text = Color3.fromHex("#18252B"),
	Muted = Color3.fromHex("#64757A"),
	White = Color3.fromHex("#FFFFFF"),
	Black = Color3.fromHex("#000000"),
	DarkOverlay = Color3.fromHex("#00000080"),
}

UIConfig.Spacing = {
	XS = 4,
	SM = 8,
	MD = 12,
	LG = 16,
	XL = 24,
	XXL = 32,
}

UIConfig.CornerRadii = {
	SM = 8,
	MD = 12,
	LG = 16,
}

UIConfig.TouchTarget = {
	MinSize = 44,
	PreferredSize = 48,
}

UIConfig.Fonts = {
	Header = Enum.Font.GothamBold,
	Body = Enum.Font.Gotham,
	Button = Enum.Font.GothamMedium,
	Mono = Enum.Font.Code,
}

UIConfig.TextSizes = {
	HeaderLarge = 24,
	Header = 18,
	Subheader = 14,
	Body = 12,
	Small = 10,
}

UIConfig.FreshnessColors = {
	Fresh = Color3.fromHex("#65B875"),
	Chilled = Color3.fromHex("#5BA8D6"),
	Aging = Color3.fromHex("#F5C95B"),
	Spoiled = Color3.fromHex("#E66A5C"),
}

UIConfig.RarityColors = {
	Common = Color3.fromHex("#9E9E9E"),
	Uncommon = Color3.fromHex("#65B875"),
	Rare = Color3.fromHex("#5BA8D6"),
	Strange = Color3.fromHex("#B065E6"),
}

UIConfig.TimeOfDayColors = {
	Morning = Color3.fromHex("#FFB74D"),
	Day = Color3.fromHex("#FFD54F"),
	Evening = Color3.fromHex("#FF8A65"),
	Night = Color3.fromHex("#5C6BC0"),
	LateNight = Color3.fromHex("#3F51B5"),
	Dawn = Color3.fromHex("#CE93D8"),
}

return UIConfig
