#****************************************************************************
#
# SPDX-License-Identifier: MIT-0
# Copyright(c) 2019-2021 Intel Corporation.
#
#****************************************************************************
#
# This script construct sub system of NiosV for higher level integration
# The GHRD create_ghrd_qsys.tcl will call each of those subsystem construct script
# automatically based on the corresponding parameter argument defined
#
#****************************************************************************

source ./arguments_solver.tcl
source ./utils.tcl
set sub_sys subsys_niosv

package require -exact qsys 19.1

create_system $sub_sys

set_project_property DEVICE_FAMILY $device_family
set_project_property DEVICE $device
set_validation_property AUTOMATIC_VALIDATION false

add_component_param "altera_clock_bridge niosv_clk 
                    IP_FILE_PATH ip/$sub_sys/niosv_clk.ip 
                    EXPLICIT_CLOCK_RATE 100000000 
                    NUM_CLOCK_OUTPUTS 1
                    "

add_component_param "altera_reset_bridge niosv_rst_in 
                    IP_FILE_PATH ip/$sub_sys/niosv_rst_in.ip 
                    ACTIVE_LOW_RESET 1
                    SYNCHRONOUS_EDGES both
                    NUM_RESET_OUTPUTS 1
                    USE_RESET_REQUEST 0
                    "
add_component_param "intel_niosv_m cpu
					IP_FILE_PATH ip/$sub_sys/cpu.ip
					enableDebug 1
					exceptionOffset 32
					exceptionSlave ram.s1
					numGpr 32
					resetOffset 0
					resetSlave ram.s1
					"

add_component_param "altera_avalon_onchip_memory2 ram
					IP_FILE_PATH ip/$sub_sys/ram.ip
					allowInSystemMemoryContentEditor 0
					blockType AUTO
					copyInitFile 0
					dataWidth 32
					dataWidth2 32
					dualPort 0
					ecc_enabled 0
					enPRInitMode 0
					enableDiffWidth 0
					initMemContent 1
					initializationFileName ram.hex
					instanceID NONE
					memorySize 300000.0
					readDuringWriteMode DONT_CARE
					resetrequest_enabled 1
					simAllowMRAMContentsFile 0
					simMemInitOnlyFilename 0
					singleClockOperation 0
					slave1Latency 1
					slave2Latency 1
					useNonDefaultInitFile 0
					useShallowMemBlocks 0
					writable 1
					"

add_component_param "altera_avalon_jtag_uart jtag_uart
					IP_FILE_PATH ip/$sub_sys/jtag_uart.ip
					allowMultipleConnections 0
					hubInstanceID 0
					readBufferDepth 64
					readIRQThreshold 8
					useRegistersForReadBuffer 0
					useRegistersForWriteBuffer 0
					useRelativePathForSimFile 0
					writeBufferDepth 64
					writeIRQThreshold 8
					"
# Connections
# Clocks
connect "	niosv_clk.out_clk cpu.clk
			niosv_clk.out_clk ram.clk1
			niosv_clk.out_clk jtag_uart.clk
			niosv_clk.out_clk niosv_rst_in.clk"
			
# Resets
connect "	niosv_rst_in.out_reset cpu.reset 
			niosv_rst_in.out_reset ram.reset1
			niosv_rst_in.out_reset jtag_uart.reset"
			
# interupts
add_connection cpu.platform_irq_rx/jtag_uart.irq
set_connection_parameter_value cpu.platform_irq_rx/jtag_uart.irq interruptsUsedSysInfo {2}
set_connection_parameter_value cpu.platform_irq_rx/jtag_uart.irq irqNumber {1}

# MM Connections
connect_map "	cpu.instruction_manager ram.s1 0x0000"
connect_map "	cpu.instruction_manager cpu.dm_agent 0x00080000"
connect_map "	cpu.data_manager jtag_uart.avalon_jtag_slave 0x00090078"
connect_map "	cpu.data_manager cpu.timer_sw_agent 0x00090000"
			
# exported interfaces

export niosv_rst_in in_reset reset
export niosv_clk in_clk clk

# interconnect requirements
set_domain_assignment {$system} {qsys_mm.clockCrossingAdapter} {AUTO}
set_domain_assignment {$system} {qsys_mm.maxAdditionalLatency} {1}
set_domain_assignment {$system} {qsys_mm.enableEccProtection} {FALSE}
set_domain_assignment {$system} {qsys_mm.insertDefaultSlave} {FALSE}

sync_sysinfo_parameters 
    
save_system ${sub_sys}.qsys
