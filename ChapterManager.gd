extends Node
class_name ChapterManager

signal chapter_changed(chapter_name: String)
signal transition_complete(chapter_index: int)

# --------------------------
# CHAPTER DATA
# --------------------------
var current_chapter := -1

var chapters := [
	"",
	" Something's Breathing in the Walls",
	" Lights That Don’t Remember",
	" Echoes in the Intercom",
	" Hallways Rearranged",
	" The Voice That Knows Your Name",
	" Static Rooms, Shifting Doors",
	" Don’t Recharge It Again",
	" There’s Someone in the Power",
	" Let Go of the Ship"
]

var chapter_images: Array[Texture2D] = [load("res://DemoPlayer/chapter_01_title.png") , load("res://Interaction/Items/PowerCell/mwgot.png") , load("res://DemoPlayer/chapter_02_title.png"), null, null, null, null, null, null, null]
var chapter_videos := [
	"res://cutscenes/ch1.webm", "res://cutscenes/ch2.webm", "res://cutscenes/ch3.webm",
	"res://cutscenes/ch4.webm", "res://cutscenes/ch5.webm", "res://cutscenes/ch6.webm",
	"res://cutscenes/ch7.webm", "res://cutscenes/ch8.webm", "res://cutscenes/ch9.webm",
	"res://cutscenes/ch10.webm"
]
var chapter_voice_paths := [
	"res://audio/ch1.ogg", "res://audio/ch2.ogg", "res://audio/ch3.ogg",
	"res://audio/ch4.ogg", "res://audio/ch5.ogg", "res://audio/ch6.ogg",
	"res://audio/ch7.ogg", "res://audio/ch8.ogg", "res://audio/ch9.ogg",
	"res://audio/ch10.ogg"
]
var chapter_dialogs := [
	["This thing doesn’t come with instructions.", "Just buttons. Blinking. Ticking. Breathing."],
	["Was that... breathing?", "No. Pipes don’t breathe. Houses don’t breathe.", "...right?"],
	["The lights forget where they’re supposed to be.", "They flicker like memories trying to stay alive."],
	["Static’s louder today.", "I think it’s trying to say my name.", "But whose voice is that?"],
	["The hallway’s longer again.", "I walked for a minute and ended up behind myself.", "This place loops when I’m not looking."],
	["They said the ship was unmanned.", "Why does the radio know my childhood nickname?", "And why did it whisper it?"],
	["Doors don’t open anymore. They rearrange.", "Sometimes... they breathe first.", "I’ve stopped knocking."],
	["Something’s wrong with the power cells.", "Each recharge makes it angrier.", "I think the light is learning."],
	["I saw myself on the monitor.", "But the other me smiled first.", "There's someone in the signal, pretending to be me."],
	["The buttons have stopped responding.", "The house... the ship... whatever it is...", "wants me to let go."]
]
var chapter_durations := [
	[2.5, 3.5], [2.0, 3.0, 2.5], [3.0, 3.0], [2.5, 2.5, 2.5], [2.0, 3.0, 3.0],
	[2.0, 3.0, 3.0], [2.5, 2.5, 2.0], [2.5, 3.0, 3.0], [2.5, 3.5, 3.0], [3.0, 2.5, 4.0]
]

@export var fade_in_time := 1.5
@export var title_hold_time := 2.0
@export var crossfade_time := 0.8
@export var fade_out_time := 1.2

@export var show_title_text := true
@export var lock_player_during_transition := true

var _ui_layer: CanvasLayer
var _fade_rect: ColorRect
var _title_image: TextureRect
var _title_label: Label
var _video: VideoStreamPlayer
var _subtitle_label: Label
var _voice_player: AudioStreamPlayer
var _transition_running := false

func _ready():
	_build_ui_once()
	play_first_two_chapter_images()


func _build_ui_once():
	if _ui_layer: return

	_ui_layer = CanvasLayer.new()
	add_child(_ui_layer)
	_ui_layer.layer = 100

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui_layer.add_child(_fade_rect)

	_title_image = TextureRect.new()
	_title_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title_image.visible = false
	_ui_layer.add_child(_title_image)

	_title_label = Label.new()
	_title_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_title_label.add_theme_font_size_override("font_size", 48)
	_title_label.visible = false
	_ui_layer.add_child(_title_label)

	_video = VideoStreamPlayer.new()
	_video.expand = true
	_ui_layer.add_child(_video)

	_subtitle_label = Label.new()
	_subtitle_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_subtitle_label.add_theme_font_size_override("font_size", 20)
	_subtitle_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	_subtitle_label.visible = false
	_ui_layer.add_child(_subtitle_label)

	_voice_player = AudioStreamPlayer.new()
	add_child(_voice_player)

	_ui_layer.hide()

func advance():
	if _transition_running: return
	current_chapter += 1
	if current_chapter >= chapters.size():
		print("✅ All chapters complete.")
		return
	emit_signal("chapter_changed", chapters[current_chapter])
	await _run_transition(current_chapter)
	emit_signal("transition_complete", current_chapter)
	_play_in_game_monologue(current_chapter)

func jump_to(idx: int):
	if _transition_running: return
	current_chapter = clamp(idx - 1, -1, chapters.size() - 1)
	await advance()

func _run_transition(ch_idx: int) -> void:
	_transition_running = true
	if lock_player_during_transition: _pause_player(true)
	_ui_layer.show()
	_fade_rect.modulate.a = 1.0

	_title_image.texture = chapter_images[ch_idx]
	_title_image.visible = chapter_images[ch_idx] != null
	_title_label.text = chapters[ch_idx]
	_title_label.visible = show_title_text

	var t = create_tween()
	t.tween_property(_fade_rect, "modulate:a", 0.0, fade_in_time)
	await t.finished

	await get_tree().create_timer(title_hold_time).timeout

	t = create_tween()
	t.tween_property(_fade_rect, "modulate:a", 1.0, crossfade_time)
	await t.finished

	_title_label.visible = false
	_title_image.visible = false

	var video_ok = _prepare_and_play_video(ch_idx)
	if video_ok:
		t = create_tween()
		t.tween_property(_fade_rect, "modulate:a", 0.0, 0.6)
		await t.finished
		await _wait_for_video_end()
	else:
		await get_tree().create_timer(0.6).timeout

	t = create_tween()
	t.tween_property(_fade_rect, "modulate:a", 1.0, 0.5)
	await t.finished
	_video.stop()
	_video.visible = false

	t = create_tween()
	t.tween_property(_fade_rect, "modulate:a", 0.0, fade_out_time)
	await t.finished

	_ui_layer.hide()
	if lock_player_during_transition: _pause_player(false)
	_transition_running = false

func _prepare_and_play_video(ch_idx: int) -> bool:
	if ch_idx >= chapter_videos.size(): return false
	var path = chapter_videos[ch_idx]
	if not ResourceLoader.exists(path): return false
	var stream = load(path)
	if stream == null: return false
	_video.stream = stream
	_video.visible = true
	_video.play()
	return true

func _wait_for_video_end() -> void:
	if _video.stream and _video.stream.get_length() > 0:
		await get_tree().create_timer(_video.stream.get_length()).timeout
	else:
		await get_tree().create_timer(6.0).timeout
func _play_in_game_monologue(ch_idx: int) -> void:
	if ch_idx >= chapter_dialogs.size() or ch_idx >= chapter_durations.size():
		return

	var lines = chapter_dialogs[ch_idx]
	var durations = chapter_durations[ch_idx]

	if lines.is_empty() or durations.is_empty():
		return

	call_deferred("_monologue_popup_sequence", lines, durations)

func _monologue_popup_sequence(lines: Array[String], durations: Array[float]) -> void:
	for i in lines.size():
		var line = lines[i]
		var d = 2.0
		if i < durations.size():
			d = durations[i]
		if has_node("/root/GameEnhancer"):
			var enhancer = get_node("/root/GameEnhancer")
			if enhancer.has_method("show_popup"):
				enhancer.show_popup(line)
		await get_tree().create_timer(d).timeout



func _show_subtitles_async(lines: Array[String], durations: Array[float]) -> void:
	if lines.is_empty() or durations.is_empty(): return
	_subtitle_label.visible = true
	call_deferred("_subtitle_coroutine", lines, durations)

func _subtitle_coroutine(lines: Array[String], durations: Array[float]) -> void:
	_subtitle_label.text = ""
	for i in lines.size():
		_subtitle_label.text = lines[i]
		var d = 2.0
		if i < durations.size():
			d = durations[i]
		await get_tree().create_timer(d).timeout
	_subtitle_label.text = ""
	_subtitle_label.visible = true

func _pause_player(freeze: bool) -> void:
	if has_node("/root/DemoLevel/Player"):
		var p = get_node("/root/DemoLevel/Player")
		if p.has_variable("can_move_camera"):
			p.can_move_camera = not freeze

# --- Helper: safe mapping (chapter 1 -> image index 0, etc.)
func _get_chapter_tex_for(ch_idx: int) -> Texture2D:
	var i := ch_idx - 1
	if i >= 0 and i < chapter_images.size():
		return chapter_images[i]
	return null

# --- Show only the title card (image + optional label), then fade out
func _run_title_only(ch_idx: int) -> void:
	if _transition_running:
		return
	if ch_idx < 0 or ch_idx >= chapters.size():
		push_warning("Title-only skip: bad chapter index %s" % ch_idx)
		return

	_transition_running = true
	if lock_player_during_transition:
		_pause_player(true)

	_ui_layer.show()
	_fade_rect.modulate.a = 1.0

	var tex := _get_chapter_tex_for(ch_idx)
	_title_image.texture = tex
	_title_image.visible = tex != null

	_title_label.text = chapters[ch_idx]
	_title_label.visible = show_title_text

	var t = create_tween()
	t.tween_property(_fade_rect, "modulate:a", 0.0, fade_in_time)
	await t.finished

	await get_tree().create_timer(title_hold_time).timeout

	t = create_tween()
	t.tween_property(_fade_rect, "modulate:a", 1.0, crossfade_time)
	await t.finished

	_title_label.visible = false
	_title_image.visible = false

	t = create_tween()
	t.tween_property(_fade_rect, "modulate:a", 0.0, fade_out_time)
	await t.finished

	_ui_layer.hide()
	if lock_player_during_transition:
		_pause_player(false)
	_transition_running = false

# --- Public: play Chapter 1 then Chapter 2 title images back-to-back
func play_first_two_chapter_images() -> void:
	await _run_title_only(1)
	await _run_title_only(2)
	await _run_title_only(3)
