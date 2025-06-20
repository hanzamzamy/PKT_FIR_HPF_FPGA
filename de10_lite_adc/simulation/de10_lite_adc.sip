set_global_assignment -entity "de10_lite_adc" -library "lib_de10_lite_adc" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "de10_lite_adc" -library "lib_de10_lite_adc" -name IP_TOOL_VERSION "21.1"
set_global_assignment -entity "de10_lite_adc" -library "lib_de10_lite_adc" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_de10_lite_adc" -name SPD_FILE [file join $::quartus(sip_path) "../de10_lite_adc.spd"]
set_global_assignment -library "lib_de10_lite_adc" -name MISC_FILE [file join $::quartus(sip_path) "../../de10_lite_adc.qsys"]

set_global_assignment -library "lib_de10_lite_adc" -name MISC_FILE [file join $::quartus(sip_path) "de10_lite_adc.v"]
set_global_assignment -library "lib_de10_lite_adc" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_up_avalon_adv_adc.v"]
set_global_assignment -library "lib_de10_lite_adc" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_modular_adc_control.v"]
set_global_assignment -library "lib_de10_lite_adc" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_modular_adc_control_avrg_fifo.v"]
set_global_assignment -library "lib_de10_lite_adc" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_modular_adc_control_fsm.v"]
set_global_assignment -library "lib_de10_lite_adc" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_modular_adc_sample_store.v"]
set_global_assignment -library "lib_de10_lite_adc" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_modular_adc_sample_store_ram.v"]
set_global_assignment -library "lib_de10_lite_adc" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_modular_adc_sequencer.v"]
set_global_assignment -library "lib_de10_lite_adc" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_modular_adc_sequencer_csr.v"]
set_global_assignment -library "lib_de10_lite_adc" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_modular_adc_sequencer_ctrl.v"]
set_global_assignment -library "lib_de10_lite_adc" -name MISC_FILE [file join $::quartus(sip_path) "submodules/chsel_code_converter_sw_to_hw.v"]
set_global_assignment -library "lib_de10_lite_adc" -name MISC_FILE [file join $::quartus(sip_path) "submodules/DE10_Lite_ADC_Core_modular_adc_0.v"]
set_global_assignment -library "lib_de10_lite_adc" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fiftyfivenm_adcblock_primitive_wrapper.v"]
set_global_assignment -library "lib_de10_lite_adc" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fiftyfivenm_adcblock_top_wrapper.v"]
set_global_assignment -library "lib_de10_lite_adc" -name MISC_FILE [file join $::quartus(sip_path) "submodules/de10_lite_adc_adc_mega_0.v"]
