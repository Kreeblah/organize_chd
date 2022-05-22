#!/usr/bin/env zsh

function do_compress_chd {
	if ! type "chdman"; then
		echo "chdman must be in your path to create CHD files"
		exit 1
	fi

	num_cpus=$([ $(uname) = 'Linux' ] && nproc || sysctl -n hw.ncpu)

	if [[ -z "$num_cpus" ]]; then
		echo "Unable to determine number of CPUs"
		exit 1
	fi

	for i in "${disc_directory[2]}"/**/*.cue;
	do
		tmpcue="${i:r}"
		if [[ ! -f "${tmpcue}.chd" ]]; then
			echo "Processing: ${tmpcue}.cue"
			chdman createcd -np ${num_cpus} -i "${tmpcue}.cue" -o "${tmpcue}.chd"
			if [[ $? -ne 0 ]]; then
				if [[ -f "${tmpcue}.chd" ]]; then
					rm -f "${tmpcue}.chd"
				fi
				echo "Error processing: ${tmpcue}.cue"
				exit 1
			elif [[ ! -f "${tmpcue}.chd" ]]; then
				echo "Error creating: ${tmpcue}.chd"
				exit 1
			fi
		else
			echo "Found: ${tmpcue}.chd"
			echo "Skipping: ${tmpcue}.cue"
		fi
	done;
}

function do_delete_source_image {
	echo "Removing .cue files"
	find "${disc_directory[2]}" -name "*.cue" -type f -delete

	echo "Removing .bin files"
	find "${disc_directory[2]}" -name "*.bin" -type f -delete

	echo "Removing empty directories"
	find "${disc_directory[2]}" -empty -type d -delete
}

function do_organize_single_region {
	find_command_str="find \"${disc_directory[2]}\" -type d \("
	existing_find_str=0
	console_region_dir="${disc_directory[2]}/${@[$#]}"
	for i in "${@:1:#-1}";
	do
		if [[ ${existing_find_str} -ne 0 ]]; then
			find_command_str=${find_command_str}" -or"
		else
			existing_find_str=1
		fi

		find_command_str=${find_command_str}" -name \"*\(${i}*\""
	done;

	find_command_str=${find_command_str}" \)"

	if [[ ! -d "${console_region_dir}" ]]; then
		echo "Creating: ${console_region_dir}"
		mkdir -p "${console_region_dir}"
	fi

	eval ${find_command_str} | while read found_regioned_dir;
	do
		echo "Moving ${found_regioned_dir} to ${console_region_dir}"
		mv "${found_regioned_dir}" "${console_region_dir}"
	done;
}

function do_organize_regions {
	do_organize_single_region "Brazil" "USA" "NTSC-U"
	do_organize_single_region "Japan" "NTSC-J"
	do_organize_single_region "Australia" "Denmark" "Europe" "Finland" "France" "Germany" "Italy" "Netherlands" "Norway" "Poland" "Portugal" "Russia" "Spain" "Sweden" "UK" "PAL"
}

function do_merge_disc_numbers {
	find -E "${disc_directory[2]}" -regex '.* \(Disc [0-9]+\).*\.chd' | while read found_chd; do
    	echo "Found CHD: ${found_chd}"
    	folder_to_move_to=$(echo "${found_chd}" | sed -E -e 's/(.*)( \(Disc [0-9]+\))(.*)\/.*\.chd/\1\3/')
    	mkdir -p "${folder_to_move_to}"
    	echo "Created folder ${folder_to_move_to}"
    	mv "${found_chd}" "${folder_to_move_to}/."
    	echo "Moved CHD ${found_chd} to ${folder_to_move_to}"
    	folder_to_remove=$(echo "${found_chd}" | sed -E -e 's/(.*)\/.*\.chd/\1/')
    	rm -r "${folder_to_remove}"
    	echo "Removed folder ${folder_to_remove}"
	done
}

zmodload zsh/zutil
autoload is-at-least

if ! is-at-least 5.8 ${ZSH_VERSION}; then
  eerror "zsh 5.8 is required for option parsing in this script, but zsh version ${ZSH_VERSION} was used"
  exit 1
fi

unset disc_directory
unset compress_chd
unset organize_regions
unset merge_disc_numbers
unset delete_source_image

zparseopts -D -E -F - d:=disc_directory -disc-directory:=disc_directory c=compress_chd -compress-chd=compress_chd r=organize_regions -organize-regions=organize_regions n=merge_disc_numbers -merge-disc-numbers=merge_disc_numbers s=delete_source_image -delete-source-image=delete_source_image || exit 1

end_opts=$@[(i)(--|-)]
set -- "${@[0,end_opts-1]}" "${@[end_opts+1,-1]}"

if [[ -z ${disc_directory} ]]; then
	echo "Must specify disc directory"
	exit 1
fi

if [[ ! -d "${disc_directory[2]}" ]]; then
	echo "Cannot find directory: ${disc_directory[2]}"
	exit 1
fi

if [[ ! -z ${compress_chd} ]]; then
	do_compress_chd
fi

if [[ ! -z ${organize_regions} ]]; then
	do_organize_regions
fi

if [[ ! -z ${merge_disc_numbers} ]]; then
	do_merge_disc_numbers
fi

if [[ ! -z ${delete_source_image} ]]; then
	do_delete_source_image
fi
