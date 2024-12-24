@icon("res://addons/papershot/papershot.svg")
class_name Papershot
extends Node
## A node that takes screenshots of its viewport.

signal screenshot_saved(image: Image, path: String)
signal io_error(error: Error, path: String)

enum FileFormat {
	## Lossy compression, smaller file size for complex images.
	JPG,
	## Lossless compression, smaller file size for simple images where the
	## colors don't vary as much.
	PNG
}
const JPG = FileFormat.JPG
const PNG = FileFormat.PNG

## Folder to save screenshots in.
@export var folder: String:
	set(value):
		folder = value
		if not folder.ends_with("/"):
			folder += "/"

## Shortcut for taking a screenshot.
@export var shortcut: Shortcut

## Format to save screenshots in.
@export var file_format: FileFormat = JPG


func _input(event: InputEvent) -> void:
	if not shortcut:
		return

	for shortcut_event: InputEvent in shortcut.events:
		if shortcut_event.is_match(event):
			get_viewport().set_input_as_handled()

			if event.is_pressed() and not event.is_echo():
				take_screenshot()


func take_screenshot() -> Error:
	var path: String = _get_path()
	var image: Image = get_viewport().get_texture().get_image()

	var err: Error
	match file_format:
		JPG: err = image.save_jpg(path, 0.9)
		PNG: err = image.save_png(path)

	if err:
		io_error.emit(err, path)
	else:
		screenshot_saved.emit(image, path)
	return err


func _get_path() -> String:
	var datetime: String = Time.get_datetime_string_from_system(false, true).replace(":", "-")
	var millis: String = str(roundi(fmod(Time.get_unix_time_from_system(), 1.0) * 1000.0))

	var extension: String
	match file_format:
		JPG: extension = ".jpg"
		PNG: extension = ".png"

	return folder + "Screenshot " + datetime + "-" + millis + extension
