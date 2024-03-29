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

	corepackage_to_folder(additional_args.last(), is_verbose) !
	
}

fn corepackage_to_folder(path string, v bool) ! {
	if !os.is_dir(path) {
		println("Unpacking...\n")
		filebytes := os.read_bytes(path) or { pn(err.msg()) exit(-1) }
		filelen := filebytes.len

		unsafe {
			free(&filebytes)
		}
		
		mut file := os.open(path) or { pn(err.msg()) exit(-1) }


		if file.read_bytes(0x07).bytestr() != "COREPKG" {pn("File is not a corepackage!") exit(-1)}

		file.seek(0x07, os.SeekMode.start) or { pn(err.msg()) exit(-1) }

		json_pointer := file.read_bytes_at(0x0A, 0x07).bytestr()
		language_pointer := file.read_bytes_at(0x0A, 0x11).bytestr()
		package_pointer := file.read_bytes_at(0x0A, 0x1B).bytestr()

		json := file.read_bytes_at(language_pointer.int() - json_pointer.int(), json_pointer.u32())
		language := file.read_bytes_at(package_pointer.int() - language_pointer.int(), language_pointer.u32())
		package := file.read_bytes_at(filelen - package_pointer.int(), package_pointer.u32())

		println("###")
		println(json.bytestr())
		println("###")
		println(language.bytestr())
		println("###")
		println("JSON Address\n$json_pointer\n\nLanguage Metadata Address\n$language_pointer\n\nPackage Address\n$package_pointer\n\n")
		println("Package Length\n\n\n")

		file.close()

		newpath := os.dir(os.dir(path)).replace(".corepackage", "") + "_extracted"

		os.mkdir(newpath) or { pn(err.msg()) exit(-1) }
		mut tempmod := os.create(newpath + "/coremod.temp") or { pn(err.msg()) exit(-1) }
		tempmod.write(package) or { pn(err.msg()) exit(-1) }
		tempmod.close()

		szip.extract_zip_to_dir(newpath + "/coremod.temp", newpath) or { pn(err.msg()) exit(-1) }
		os.rm(newpath + "/coremod.temp") or { pn(err.msg()) exit(-1) }

		sc("Extraction Completed")

	} else { pn("Target path is not a file") exit(-1)}
}

fn pn(msg string) {
	println(crayon.new("PANIC /// $msg".to_upper()).red())
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