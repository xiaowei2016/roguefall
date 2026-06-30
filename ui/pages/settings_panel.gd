extends Control

@onready var master_label: Label = $Card/SettingsScroll/Options/MasterVolumeLabel
@onready var master_slider: HSlider = $Card/SettingsScroll/Options/MasterVolumeSlider
@onready var music_label: Label = $Card/SettingsScroll/Options/MusicVolumeLabel
@onready var music_slider: HSlider = $Card/SettingsScroll/Options/MusicVolumeSlider
@onready var sfx_label: Label = $Card/SettingsScroll/Options/SfxVolumeLabel
@onready var sfx_slider: HSlider = $Card/SettingsScroll/Options/SfxVolumeSlider


func _ready() -> void:
	_ensure_audio_bus("Music")
	_ensure_audio_bus("SFX")
	_setup_slider(master_slider, master_label, "主音量", "Master")
	_setup_slider(music_slider, music_label, "背景音乐", "Music")
	_setup_slider(sfx_slider, sfx_label, "音效", "SFX")


func _setup_slider(slider: HSlider, label: Label, title: String, bus_name: String) -> void:
	slider.value_changed.connect(func(value: float) -> void:
		_apply_volume(label, title, bus_name, value)
	)
	_apply_volume(label, title, bus_name, slider.value)


func _apply_volume(label: Label, title: String, bus_name: String, value: float) -> void:
	label.text = title + " " + str(int(value)) + "%"
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	var normalized := clampf(value / 100.0, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, normalized <= 0.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(normalized, 0.001)))


func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var bus_index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, "Master")
