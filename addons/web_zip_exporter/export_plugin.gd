@tool
extends EditorExportPlugin

# Stores the export output directory captured in _export_begin().
var _export_dir: String = ""


func _get_name() -> String:
	return "WebZipExporter"


func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	# Only activate for Web exports.
	if "web" not in features:
		_export_dir = ""
		return

	_export_dir = path.get_base_dir()
	print("WebZipExporter: Export started → ", _export_dir)


func _export_end() -> void:
	if _export_dir == "":
		return

	# Place the zip inside the export folder itself.
	var zip_path := _export_dir.path_join("web_export.zip")

	print("WebZipExporter: Creating zip → ", zip_path)

	var zip := ZIPPacker.new()
	var err := zip.open(zip_path)
	if err != OK:
		push_error("WebZipExporter: Could not create zip file at '%s' (error %d)" % [zip_path, err])
		_export_dir = ""
		return

	var file_count := _pack_directory(zip, _export_dir, _export_dir)
	zip.close()

	if file_count > 0:
		print("WebZipExporter: Done! Packed %d file(s) into '%s'." % [file_count, zip_path])
		_cleanup_export_dir(_export_dir)
		print("WebZipExporter: Cleaned up export directory, only web_export.zip remains.")
	else:
		push_warning("WebZipExporter: Zip created but no files were packed. Is the export directory empty?")

	_export_dir = ""


# Recursively adds every file inside `current_dir` to `zip`.
# `base_dir` is the root of the export so we can compute relative paths.
# Returns the total number of files packed.
func _pack_directory(zip: ZIPPacker, base_dir: String, current_dir: String) -> int:
	var dir := DirAccess.open(current_dir)
	if dir == null:
		push_error("WebZipExporter: Cannot open directory '%s'." % current_dir)
		return 0

	var count := 0
	dir.list_dir_begin()
	var entry := dir.get_next()

	while entry != "":
		if entry != "." and entry != "..":
			var full_path := current_dir.path_join(entry)

			if dir.current_is_dir():
				# Recurse into sub-directory.
				count += _pack_directory(zip, base_dir, full_path)
			else:
				# Strip the base dir prefix to get the in-zip relative path.
				# +1 to also remove the leading slash/separator.
				var relative_path := full_path.substr(base_dir.length() + 1)

				var data := FileAccess.get_file_as_bytes(full_path)
				if data.is_empty() and FileAccess.get_open_error() != OK:
					push_warning("WebZipExporter: Could not read '%s', skipping." % full_path)
				else:
					zip.start_file(relative_path)
					zip.write_file(data)
					zip.close_file()
					count += 1

		entry = dir.get_next()

	dir.list_dir_end()
	return count


# Recursively deletes all files and subdirectories inside `target_dir`,
# except for web_export.zip at the top level. The folder itself is kept.
func _cleanup_export_dir(target_dir: String, is_root: bool = true) -> void:
	var dir := DirAccess.open(target_dir)
	if dir == null:
		push_error("WebZipExporter: Cannot open directory for cleanup '%s'." % target_dir)
		return

	dir.list_dir_begin()
	var entry := dir.get_next()

	while entry != "":
		if entry != "." and entry != "..":
			var full_path := target_dir.path_join(entry)
			if dir.current_is_dir():
				# Recurse, then remove the now-empty sub-directory.
				_cleanup_export_dir(full_path, false)
				var parent := DirAccess.open(target_dir)
				if parent:
					parent.remove(entry)
			else:
				# At the root level, skip the zip we just created.
				if is_root and entry == "web_export.zip":
					entry = dir.get_next()
					continue
				var err := dir.remove(entry)
				if err != OK:
					push_warning("WebZipExporter: Could not delete '%s' (error %d)." % [full_path, err])
		entry = dir.get_next()

	dir.list_dir_end()
