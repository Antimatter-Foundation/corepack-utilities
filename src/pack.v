import compress.szip
import flag
import os

const json_dummy := '{
"version" : "0.0.0",
"developer" : "ANON",
"name" : "Example Mod",
"description" : "This is an example mod",
"icon" : "icon.png"}'

fn main() {
	mut flagparser := flag.new_flag_parser(os.args)
	flagparser.allow_unknown_args = false
	args := flagparser.finalize() !
	pack(args.last())!
}

fn pack(root string) ! {
	//Scan root for binaries, abort if found any
	if os.walk_ext("$root", ".corepackage") != [] { pn("Mod contains binaries, remove them before packing your mod (Check /bin/ catalog)") exit(-1) }
	
	filename := os.file_name(root)
	
	if os.is_dir(root) {
		println("$root Is Directory")
		//Check whether /bin exists in the mod directory, create one if it doesn't exist
		if !os.exists("$root/bin") {
			println("/bin is not found in the target directory... Making one now...")
			os.mkdir("$root/bin") or { pn(err.msg()) exit(-1) }
			println("Further binaries will be dropped into /bin/")
		}
		
		//Check wheter mod already exists in /bin/ 
		if os.exists("$root/bin/" + filename + ".corepackage") { pn("Package Exists") exit(-1) }
		mut package := os.create("$root/bin/" + filename + ".corepackage") or { pn(err.msg()) exit(-1) }

		if !os.exists("$root/info.json") {
			mut json := os.create("$root/info.json") or { pn(err.msg()) exit(-1) }
			json.write_string(json_dummy) or { pn(err.msg()) exit(-1) }
			println("info.json is missing, a dummy file was created at the root of $root, fill it with your information and try again.")
			json.close()
}

		//Offset calculation

	}
}

fn pn(msg string) {
	// println(crayon.new("PANIC /// $msg".to_upper()).red())
	print("PANIC! /// $msg".to_upper())
}