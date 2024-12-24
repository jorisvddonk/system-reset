extends Control
@export var showLicenseButton: bool = false
var licenseTextGodot = 'This game uses Godot Engine, available under the following license:'
var licenseAlsoText = 'It also uses (parts from) the following third party software, available under the following license:\n--------------------'

# Called when the node enters the scene tree for the first time.
func _ready():
	if showLicenseButton:
		$Button.show()
	else:
		$Button.hide()
	$Button.connect("button_down", close_button_pressed)
	%LicenseText.text = licenseTextGodot + '\n\n' + Engine.get_license_text() + '\n\n' + licenseAlsoText + '\n'
	
	var noctislicensefile = FileAccess.open("res://addons/feltyrion-godot/LICENSE.md", FileAccess.READ)
	if noctislicensefile != null:
		var noctislicensecontent = noctislicensefile.get_as_text()
		%LicenseText.text += noctislicensecontent + "\n--------------------\n"
	else:
		%LicenseText.text += "This software includes parts of Noctis IV, licensed under the WTOF Public License - https://github.com/jorisvddonk/feltyrion-godot/blob/main/LICENSE.md\n--------------------\n"
	
	var licenses = Engine.get_license_info()
	for ci in Engine.get_copyright_info():
		var parts = ci.get('parts')
		%LicenseText.text += '[b]' + ci.get('name') + "[/b]\n"
		for part in parts:
			for cname in part.get('copyright', ['']):
				%LicenseText.text += "[i]Copyright (c) [/i]" + cname + '\n'
			var lic = part.get('license', '')
			%LicenseText.text += licenses.get(lic, lic) + '\n'
		%LicenseText.text += "--------------------\n"
		
func close_button_pressed():
	self.queue_free()
