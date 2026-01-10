#!/bin/sh

set -x

function eddyng_message(){
  top_line
  title 'EddyNG' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Installs vvuk/eddy-ng functionality via Vsevolod-Volkov K1-Klipper-Eddy ${white}│"
  echo -e " │ ${cyan}using (Guilouz) Creality Helper Script as a framework          ${white}│"
  hr
  bottom_line
}
function install_eddyng(){
  eddyng_message
  local yn
	while true; do 
    	install_msg "Install EddyNG" yn
		case "${yn}" in
      		Y|y)
        	echo -e "${white}"
        	if [ -f "$EDDYNG_CFG"]; then
          		rm -f "$EDDYNG_CFG" 
        	fi
        echo
        	if [ "$model" = "K1" ]; then 
          		local printer_choice
          		while true; do 
            		read -p " ${white}Do you want install it for ${yellow}K1${white} or ${yellow}K1 Max${white}? (${yellow}k1${white}/${yellow}k1max${white}): ${yellow}" printer_choice
            		case "${printer_choice}" in
              			K1|k1)
                			echo -e "${white}"
                			echo -e "Info: Copying file..."
							mkdir -p "$EDDYNG_FOLDER"
                			cp -f "$EDDYNG_K1_URL" "$EDDYNG_FOLDER"/eddyng.cfg
				 			cp -f "$EHS_CONFIGS/fan_control.cfg" "$EDDY_FOLDER"/fan_control.cfg
				 			rsync --verbose --recursive $EDDYNG_KLIPPY $EDDYNG_KLIPPER_FOLDER
               		 	break;;
              			K1MAX|k1max)
                			echo -e "${white}"
                			echo -e "Info: Copying files..."
							mkdir -p "$EDDYNG_FOLDER"
                			cp -f "$EDDYNG_K1M_URL" "$EDDYNG_FOLDER"/eddyng.cfg
							cp -f "$EHS_CONFIGS/fan_control.cfg" "$EDDYNG_FOLDER"/fan_control.cfg
                			rsync --verbose --recursive $EDDYNG_KLIPPY $EDDYNG_KLIPPER_FOLDER
                		break;;
              			*)
                			error_msg "Please select a correct choice!";;
					esac
		          done 
        	else
          		echo -e "Shouldn't get this..."
       		fi
        
        if grep -q "include Eddy-Helper/eddyng/eddyng.cfg" "$PRINTER_CFG" ; then
          echo -e "Info: EddyNG configurations are already enabled in printer.cfg file..."
        else
        	echo -e "Info: Adding EddyNG configurations in printer.cfg file..."
        	sed -i '/\[include printer_params\.cfg\]/a \[include Eddy-Helper/eddyng/eddyng\.cfg\]' "$PRINTER_CFG"
	  		sed -i '/\[include printer_params\.cfg\]/a \[include Eddy-Helper/eddyng/fan_control\.cfg\]' "$PRINTER_CFG"
			sed -i '/\[mcu leveling_mcu\]/,/restart_method: command/s/^/#/' "$PRINTER_CFG"
	  		sed -i '/endstop_pin: tmc2209_stepper_z:virtual_endstop/s/^[ \t]*[^#]/#&/' "$PRINTER_CFG"
	  		sed -i '/\#endstop_pin: tmc2209_stepper_z:virtual_endstop/a endstop_pin: probe:z_virtual_endstop' "$PRINTER_CFG"
			sed -i '/position_endstop: 0/s/^/#/' "$PRINTER_CFG"
			sed -i '/\[mcu leveling_mcu\]/,/restart_method: command/s/^/#/' "$PRINTER_CFG"
	  		sed -i '/\[prtouch_v2\]/,/\[display_status\]/{ /\[display_status\]/!s/^/#/ }' "$PRINTER_CFG"
			sed -i "s|^serial: /dev/serial/by-id/usb-Klipper_rp2040_.*|serial: $EDDYNG_MCU|" "$EDDYNG_FOLDER/eddyng.cfg"
	  		#sed -i '/\[prtouch_v2\]/,/\[verify_heater extruder\]/{ /\[verify_heater extruder\]/!s/^/#/ }' "$PRINTER_CFG"
	  		sed -i 's/\bG28\b/G0028/g' "$PRINTER_DATA_FOLDER/config/sensorless.cfg"
	  		sed -i '/^\[mcu\]/i [force_move]\
	  		enable_force_move: True' "$PRINTER_CFG"
	  		FILE_PATH="/usr/data/printer_data/config/sensorless.cfg"
	  		TEMP_FILE=$(mktemp)
	  		cat <<'EOF' > "$TEMP_FILE"
[gcode_macro G28]
rename_existing: G0028
gcode:
    SET_KINEMATIC_POSITION Z=0
    G91
    G0 Z5 F600
    G90
    {% set center_x = printer.configfile.settings['stepper_x'].position_max / 2 %}
    {% set center_y = printer.configfile.settings['stepper_y'].position_max / 2 %}
    {% set home_all = 'X' not in rawparams and 'Y' not in rawparams and 'Z' not in rawparams %}
    {% if home_all or 'X' in rawparams or 'Y' in rawparams %}
        G0028 X Y
    {% endif %}
    {% if home_all or 'Z' in rawparams %}
        G90                                 
        G0 X{center_x} Y{center_y} F6000     
        G0028 Z                             
        G0 Z2 F1000                        
        G4 S1                              
        M400                                
        PROBE_EDDY_NG_PROBE_STATIC HOME_Z=1 
        G0 Z5 F1000                         
    {% endif %}

[gcode_macro _IF_HOME_Z]
EOF
	 		sed -i -e '\|\[gcode_macro _IF_HOME_Z\]|!b' -e "r $TEMP_FILE" -e 'd' -e 'G' "$FILE_PATH"
	 		rm "$TEMP_FILE"
			FILE_PATH="/usr/data/printer_data/config/gcode_macro.cfg"
	  		TEMP_FILE=$(mktemp)
	  		cat <<'EOF' > "$TEMP_FILE"
[gcode_macro FAKE_HOME]
gcode:
	# Caution: This command is for debugging only. Do not use it
	# during normal operations or printing.
 	RESPOND MSG="!! Setting kinematic position to X=150 Y=150 Z=100 !!"
 	SET_KINEMATIC_POSITION X=150 Y=150 Z=100

[gcode_macro LOAD_MATERIAL_CLOSE_FAN2]
EOF
sed -i -e '\|\[gcode_macro LOAD_MATERIAL_CLOSE_FAN2]|!b' -e "r $TEMP_FILE" -e 'd' -e 'G' "$FILE_PATH"
        fi

        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Eddy installed successfully....I hope!"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;; # Exit the function if canceled

      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}