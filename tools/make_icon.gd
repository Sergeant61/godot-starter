extends SceneTree
## Renders the launcher icons out of one source picture:
##   Godot --headless -s tools/make_icon.gd
##
## The source is art/icon/source.png: the one thing the icon shows, at its native pixel size, on a
## transparent background. Without these files the game ships under Godot's robot, which is what
## Hivebreaker was about to send to Play.
##
## An icon is read at about the size of a fingernail, so it holds one thing and no text.
##
## Android's adaptive icon is two 432x432 layers the launcher moves against each other and crops to
## whatever shape the phone likes - a circle, a squircle, a rounded square. Only the middle 66% is
## certain to survive that crop, so the subject is kept well inside it. The 192 icon is the flat one
## for older phones, the 128 is the project icon, and the 512 is what the Play listing shows.
##
## The layers go in art/ because the export presets point at them by res:// path; the store icon is
## build output and lands in build/covers/.

const SOURCE := "res://art/icon/source.png"
const LAYERS := "res://art/icon/"
const STORE := "res://build/covers/"
## The background wash. Make it the game's own sky, so the icon and the first screen agree.
const TOP := Color(0.10, 0.06, 0.16)
const BOTTOM := Color(0.02, 0.01, 0.04)
## How tall the subject stands in each frame. The adaptive layer gets the smallest share because
## it is the one that gets cropped; the flat icons can fill more because nothing eats their edges.
const ADAPTIVE_SHARE := 0.40
const FLAT_SHARE := 0.56


func _init() -> void:
	_go.call_deferred() ## Autoloads and the class table are not up during _init.


func _go() -> void:
	for dir: String in [LAYERS, STORE]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var subject := _read(SOURCE)
	subject = subject.get_region(subject.get_used_rect()) ## Size by what is drawn, not the frame.
	_save(_layer(432, subject, ADAPTIVE_SHARE, false), LAYERS + "icon_foreground.png")
	_save(_layer(432, null, 0.0, true), LAYERS + "icon_background.png")
	_save(_layer(192, subject, FLAT_SHARE, true), LAYERS + "icon.png")
	_save(_layer(128, subject, FLAT_SHARE, true), LAYERS + "icon_small.png")
	_save(_layer(512, subject, FLAT_SHARE, true), STORE + "icon_store.png")
	quit()


func _save(image: Image, path: String) -> void:
	image.save_png(ProjectSettings.globalize_path(path))
	print("%-42s %dx%d" % [path, image.get_width(), image.get_height()])


## One frame: the sky if it wants one, then the subject blown up by a whole number and centred.
## A whole number so pixel art stays crisp; a photo-like source would rather be resized smoothly.
func _layer(side: int, subject: Image, share: float, sky: bool) -> Image:
	var canvas := Image.create(side, side, false, Image.FORMAT_RGBA8)
	if sky:
		_sky(canvas)
	if subject == null:
		return canvas
	var blow := maxi(int(round(side * share / float(subject.get_height()))), 1)
	var big := Image.create(subject.get_width(), subject.get_height(), false, Image.FORMAT_RGBA8)
	big.blend_rect(subject, Rect2i(Vector2i.ZERO, subject.get_size()), Vector2i.ZERO)
	big.resize(big.get_width() * blow, big.get_height() * blow, Image.INTERPOLATE_NEAREST)
	_stamp(canvas, big, Vector2i((side - big.get_width()) / 2, (side - big.get_height()) / 2))
	return canvas


func _read(path: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	image.convert(Image.FORMAT_RGBA8)
	return image


## A vertical wash from the top colour down to the bottom one.
func _sky(canvas: Image) -> void:
	var height := canvas.get_height()
	for y in height:
		var row := TOP.lerp(BOTTOM, float(y) / float(height - 1))
		for x in canvas.get_width():
			canvas.set_pixel(x, y, row)


func _stamp(canvas: Image, piece: Image, at: Vector2i) -> void:
	for y in piece.get_height():
		for x in piece.get_width():
			var pixel := piece.get_pixel(x, y)
			if pixel.a <= 0.01:
				continue
			var to := at + Vector2i(x, y)
			if to.x < 0 or to.y < 0 or to.x >= canvas.get_width() or to.y >= canvas.get_height():
				continue
			var under := canvas.get_pixel(to.x, to.y)
			canvas.set_pixel(to.x, to.y, under.lerp(Color(pixel.r, pixel.g, pixel.b, 1.0), pixel.a))
