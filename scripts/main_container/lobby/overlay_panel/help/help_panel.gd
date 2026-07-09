class_name HelpPanel extends Panel

const TAB_HOW_TO_PLAY := &"how_to_play"
const TAB_FFA := &"ffa"
const TAB_SD := &"sd"

const TAB_TITLE_KEYS := {
	TAB_HOW_TO_PLAY: "HELP_TAB_HOW_TO_PLAY",
	TAB_FFA: "HELP_TAB_FFA",
	TAB_SD: "HELP_TAB_SD",
}

@onready var _tab_how_to_play: Button = $Content/HBoxContainer/TabsPanel/VBoxContainer/HowToPlayBtn
@onready var _tab_ffa: Button = $Content/HBoxContainer/TabsPanel/VBoxContainer/FfaBtn
@onready var _tab_sd: Button = $Content/HBoxContainer/TabsPanel/VBoxContainer/SdBtn
@onready var _content_label: RichTextLabel = $Content/HBoxContainer/ContentArea/ScrollContainer/ContentLabel
@onready var _content_title: Label = $Content/HBoxContainer/ContentArea/Title

var _active_tab: StringName = TAB_HOW_TO_PLAY


func _ready() -> void:
	_tab_how_to_play.pressed.connect(func(): _select_tab(TAB_HOW_TO_PLAY))
	_tab_ffa.pressed.connect(func(): _select_tab(TAB_FFA))
	_tab_sd.pressed.connect(func(): _select_tab(TAB_SD))
	visibility_changed.connect(_on_visibility_changed)
	LocaleManager.locale_changed.connect(func(_locale): _refresh_active_tab())
	_select_tab(TAB_HOW_TO_PLAY)


func _on_visibility_changed() -> void:
	if visible:
		_select_tab(TAB_HOW_TO_PLAY)


func _select_tab(tab: StringName) -> void:
	_active_tab = tab
	_refresh_active_tab()
	_tab_how_to_play.button_pressed = (tab == TAB_HOW_TO_PLAY)
	_tab_ffa.button_pressed = (tab == TAB_FFA)
	_tab_sd.button_pressed = (tab == TAB_SD)


func _refresh_active_tab() -> void:
	_content_title.text = tr(TAB_TITLE_KEYS.get(_active_tab, ""))
	_content_label.text = _build_content(_active_tab)


func _build_content(tab: StringName) -> String:
	match tab:
		TAB_HOW_TO_PLAY:
			return _build_how_to_play()
		TAB_FFA:
			return _build_ffa()
		TAB_SD:
			return _build_sd()
	return ""


func _build_how_to_play() -> String:
	return "[b]%s[/b]\n• %s\n• %s\n• %s\n• %s\n• %s\n• %s\n\n[b]%s[/b]\n%s\n\n[b]%s[/b]\n• %s\n• %s\n• %s" % [
		tr("HELP_HTP_CONTROLS_TITLE"),
		tr("HELP_HTP_MOVEMENT"),
		tr("HELP_HTP_JUMP"),
		tr("HELP_HTP_DROP"),
		tr("HELP_HTP_FIRE"),
		tr("HELP_HTP_THROW"),
		tr("HELP_HTP_SWITCH"),
		tr("HELP_HTP_GOAL_TITLE"),
		tr("HELP_HTP_GOAL_BODY"),
		tr("HELP_HTP_TIPS_TITLE"),
		tr("HELP_HTP_TIPS_1"),
		tr("HELP_HTP_TIPS_2"),
		tr("HELP_HTP_TIPS_3"),
	]


func _build_ffa() -> String:
	return "%s\n\n[b]%s[/b]\n• %s\n• %s\n• %s\n\n[b]%s[/b]\n%s\n\n[b]%s[/b]\n• %s\n• %s\n• %s" % [
		tr("HELP_FFA_INTRO"),
		tr("HELP_FFA_WIN_TITLE"),
		tr("HELP_FFA_WIN_1"),
		tr("HELP_FFA_WIN_2"),
		tr("HELP_FFA_WIN_3"),
		tr("HELP_FFA_KB_TITLE"),
		tr("HELP_FFA_KB_BODY"),
		tr("HELP_FFA_RW_TITLE"),
		tr("HELP_FFA_RW_WIN"),
		tr("HELP_FFA_RW_LOSE"),
		tr("HELP_FFA_RW_FORFEIT"),
	]


func _build_sd() -> String:
	return "%s\n\n[b]%s[/b]\n• %s\n• %s\n%s\n\n[b]%s[/b]\n• %s\n• %s\n\n[b]%s[/b]\n%s\n\n[b]%s[/b]\n• %s\n• %s\n• %s" % [
		tr("HELP_SD_INTRO"),
		tr("HELP_SD_ROLES_TITLE"),
		tr("HELP_SD_ROLE_ATT"),
		tr("HELP_SD_ROLE_DEF"),
		tr("HELP_SD_ROLES_NOTE"),
		tr("HELP_SD_WINR_TITLE"),
		tr("HELP_SD_WINR_ATT"),
		tr("HELP_SD_WINR_DEF"),
		tr("HELP_SD_WINM_TITLE"),
		tr("HELP_SD_WINM_BODY"),
		tr("HELP_SD_AUDIO_TITLE"),
		tr("HELP_SD_AUDIO_1"),
		tr("HELP_SD_AUDIO_2"),
		tr("HELP_SD_AUDIO_3"),
	]
