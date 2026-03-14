@tool
extends EditorPlugin

var _export_plugin: AndroidExportPlugin

func _enter_tree():
	_export_plugin = AndroidExportPlugin.new()
	add_export_plugin(_export_plugin)

func _exit_tree():
	remove_export_plugin(_export_plugin)
	_export_plugin = null


class AndroidExportPlugin extends EditorExportPlugin:
	var _plugin_name = "GoogleSignIn"

	func _supports_platform(platform):
		if platform is EditorExportPlatformAndroid:
			return true
		return false

	func _get_android_libraries(_platform, _debug):
		if _debug:
			return PackedStringArray(["addons/google_sign_in/bin/GoogleSignIn.aar"])
		else:
			return PackedStringArray(["addons/google_sign_in/bin/GoogleSignIn.aar"])

	func _get_android_dependencies(_platform, _debug):
		return PackedStringArray([
			"androidx.credentials:credentials:1.3.0",
			"androidx.credentials:credentials-play-services-auth:1.3.0",
			"com.google.android.libraries.identity.googleid:googleid:1.1.1",
			"org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3",
		])

	func _get_android_dependencies_maven_repos(_platform, _debug):
		return PackedStringArray([
			"https://maven.google.com",
			"https://repo1.maven.org/maven2",
		])

	func _get_name():
		return _plugin_name
