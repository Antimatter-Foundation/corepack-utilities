import flag
import os
import szip
import crayon

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application("corepack")
	fp.version("0.1")
	fp.allow_unknown_args = false
	fp.usage()
	fp.description("A tool used to create .corepackage files (CORE: FRACTURE modding tool)")
	fp.arguments_description("<folder>")
	fp.limit_free_args(2, 2) or { pn(err.msg()) }
	is_verbose := fp.bool("verbose", `v`, false, "Prints current progress to the CLI")

	additional_args := fp.finalize() ?

	folder_to_corepackage(additional_args.last(), is_verbose) !

}

fn folder_to_corepackage(path string, v bool) ! {
	if os.is_dir(path) {
		if !os.exists("$path/bin") { os.mkdir("$path/bin") or { pn(err.msg()) exit(-1) } }

		szip.zip_folder(path, "$path/bin/coremod.temp") or { pn(err.msg()) exit(-1) }
		bytes := os.read_bytes("$path/bin/coremod.temp") or { pn(err.msg()) exit(-1) }
		mut locbytes := []u8{}
		os.rm("$path/bin/coremod.temp") or { pn(err.msg()) exit(-1) }

		filename := os.file_name(path)
		if os.walk_ext("$path", ".corepackage") != [] { pn("Mod folder contains a mod binaries, remove all of them first before packing your mod") exit(-1) }
		if !os.exists("$path/datapack.json") {
			sample := '{
	"version" : "0.0.0",
	"developer" : "ANON",
	"name" : "Example Mod",
	"description" : "This is an example mod",
	"icon" : "icon.png"
}'
			mut json := os.create("$path/datapack.json") or { pn(err.msg()) exit(-1) }
			json.write_string(sample) or { pn(err.msg()) exit(-1) }
			inf("datapack.json is missing, a dummy file was created at the root of $path, fill it with your information and try again.")
			json.close()
}

		if os.exists("$path/bin/" + filename + ".corepackage") { pn("Package Exists") exit(-1) }

		mut package := os.create("$path/bin/" + filename + ".corepackage") or { pn(err.msg()) exit(-1) }


		if os.exists("$path/loc/text.csv") {
			locbytes = os.read_bytes("$path/loc/text.csv") or { pn(err.msg()) exit(-1) }
		}

		jsonbytes := os.read_bytes("$path/datapack.json") or { pn(err.msg()) exit(-1) }

		//7 - 17 = Metadata Location Pointer
		//17 - 27 = Package Location Pointer

		//27 - Metadata.Length = Metadata
		//Metadata.Length - Length = Package

		json_pointer := u32(0x25).hex_full()
		language_pointer := u32(0x25 + jsonbytes.len).hex_full()
		package_pointer := u32(0x25 + jsonbytes.len + locbytes.len).hex_full()

		package.write_string("COREPKG") or { pn(err.msg()) exit(-1) }

		package.seek(0x07, os.SeekMode.start) or { pn(err.msg()) exit(-1) }
		package.write_string("0x$json_pointer") or { pn(err.msg()) exit(-1) }

		package.seek(0x11, os.SeekMode.start) or { pn(err.msg()) exit(-1) }
		package.write_string("0x$language_pointer") or { pn(err.msg()) exit(-1) }

		package.seek(0x1B, os.SeekMode.start) or { pn(err.msg()) exit(-1) }
		package.write_string("0x$package_pointer") or { pn(err.msg()) exit(-1) }

		package.seek(0x25, os.SeekMode.start) or { pn(err.msg()) exit(-1) }
		package.write(jsonbytes) or { pn(err.msg()) exit(-1) }

		package.seek(0x25 + jsonbytes.len, os.SeekMode.start) or { pn(err.msg()) exit(-1) }
		package.write(locbytes) or { pn(err.msg()) exit(-1) }

		package.seek(0x25 + jsonbytes.len + locbytes.len, os.SeekMode.start) or { pn(err.msg()) exit(-1) }
		package.write(bytes) or { pn(err.msg()) exit(-1) }

		package.close()

		sc("Packed")

	} else { pn("Target path is not a directory") exit(-1)}
}

fn pn(msg string) {
	println(crayon.new("PANIC /// $msg".to_upper()).red())
}

fn inf(msg string) {
	println(crayon.new("INFO /// $msg".to_upper()).yellow())
}

fn sc(msg string) {
	println(crayon.new("SUCCESS /// $msg".to_upper()).green())
}

fn splash() {
	println("
	█▀▀ █▀█ █▀█ █▀▀ ▀   █▀▀ █▀█ ▄▀█ █▀▀ ▀█▀ █░█ █▀█ █▀▀
	█▄▄ █▄█ █▀▄ ██▄ ▄   █▀░ █▀▄ █▀█ █▄▄ ░█░ █▄█ █▀▄ ██▄

	█▀▄▀█ █▀█ █▀▄ █▀▄ █ █▄░█ █▀▀     ▀█▀ █▀█ █▀█ █░░ █▀
	█░▀░█ █▄█ █▄▀ █▄▀ █ █░▀█ █▄█     ░█░ █▄█ █▄█ █▄▄ ▄█\n\n\n")
}