#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue May 12 23:20:53 2026

@author: ozzy
"""

import tkinter as tk
import time, serial
import serial.tools.list_ports

# Install pyserial. Don't use the standard serial

# Version check
version = 'v2.0'

##################### Helper functions #######################################

def sniff_port_based_on_deviceID(vid, pid):
    for p in serial.tools.list_ports.comports():
        if p.vid == vid and p.pid == pid:
            return p.device
    return None

def update_start_state():
    """Enable Start only if A and B are checked."""
    if check_B_var.get() and check_C_var.get():
        start_button.config(state="normal")
    else:
        start_button.config(state="disabled")

def update_transducer_state(*args):
    global Transducer

    # remove old widget
    Transducer.grid_forget()
    
    if TPO_default.get() == "2_channel":
        Transducer = tk.Label(root, text="h264")
    else:
        Transducer = tk.OptionMenu(root, Transducer_default, "DPX_500", "CTX_500")

    Transducer.grid(row=2, column=1, padx=5, pady=5, sticky="w")

def update_confirm_visibility(*args):
    if TPO_default.get() == "2_channel":
        check_A.grid_remove()
        check_B.grid_remove()
        check_C.grid_remove()
        check_and_confirm_label.grid_remove()
    else:
        check_and_confirm_label.grid()
        check_A.grid()
        check_B.grid()
        check_C.grid()
        
def update_protocol_mode():

    if check_D_var.get():  # CUSTOM MODE

        protocol_label.grid_remove()
        protocol_menu.grid_remove()

        # Align exactly like Timer / Depth
        custom_prp_label.grid(row=6, column=0, padx=5, pady=5, sticky="e")
        custom_prp_entry.grid(row=6, column=1, padx=5, pady=5, sticky="w")

        custom_burst_label.grid(row=7, column=0, padx=5, pady=5, sticky="e")
        custom_burst_entry.grid(row=7, column=1, padx=5, pady=5, sticky="w")

        # shift Timer/Depth down
        timer_label.grid_configure(row=8)
        timer.grid_configure(row=8)

        depth_label.grid_configure(row=9)
        depth.grid_configure(row=9)

        zero_power_checkbox.grid_configure(row=10)

    else:  # NORMAL MODE

        protocol_label.grid()
        protocol_menu.grid(row=6, column=1, padx=5, pady=5, sticky="w")

        custom_prp_label.grid_remove()
        custom_prp_entry.grid_remove()
        custom_burst_label.grid_remove()
        custom_burst_entry.grid_remove()

        # restore original layout
        timer_label.grid_configure(row=7)
        timer.grid_configure(row=7)

        depth_label.grid_configure(row=8)
        depth.grid_configure(row=8)

        zero_power_checkbox.grid_configure(row=9)

##################### Main functions ########################################

def save_function():

    # Disable start button while saving
    start_button.config(state="disabled")
    root.update()

    selected_TPO = TPO_default.get()
    selected_timer = timer.get()
    selected_depth = depth.get()

    # Set power
    if zero_power_var.get():
        Power = 0
    else:
        Power = 30000

    # Get protocol variables based on whether custom mode was set or bult-in 
    # protocols are used. TPO accepts microseconds for PRP and burstLength, 
    # but for custom we will take ms and convert. 
    if check_D_var.get():
        PRP = int(custom_prp_entry.get())
        burst_length = int(custom_burst_entry.get()) * 1000
    else:
        selected_protocol = protocol_default.get() * 1000
        
        if selected_protocol == 'Online(1000Hz)':
            burst_length = 300 
            PRP = 1000
    
        elif selected_protocol == '5Hz (tbTUS) - 10% DC':
            burst_length = 20000
            PRP = 200000
    
        elif selected_protocol == '100Hz - 10% DC':
            burst_length = 1000
            PRP = 10000

    # Center frequency
    xdrCenterFreq = 500000  # Hz

    # The port p-ID the same for both 2ch and 4ch
    port = sniff_port_based_on_deviceID(9025, 61)

    # 4-channel
    if selected_TPO == '4_channel':

        if hasattr(root, "NeuroFUS"):
            print("Already connected")

        else:
            root.NeuroFUS = serial.Serial(
                port=port,
                baudrate=115200,
                bytesize=serial.EIGHTBITS,
                stopbits=serial.STOPBITS_ONE,
                timeout=1,
            )

            time.sleep(2)

        # Set the trigger mode and transducer type
        root.NeuroFUS.write(b'TRIGGERMODE=1\r')
        
        if Transducer_default.get() == 'CTX_500':
            if not check_A_var.get():
                root.NeuroFUS.write(('xdrselect=1\r').encode())
            else:
                root.NeuroFUS.write(('xdrselect=2\r').encode())
        elif Transducer_default.get() == 'DTX_500':
            if not check_A_var.get():
                root.NeuroFUS.write(('xdrselect=3\r').encode())
            else:
                root.NeuroFUS.write(('xdrselect=4\r').encode())            

        # Go from 500ms everytime because software has weird limits
        root.NeuroFUS.write((f'PERIOD={50000}\r').encode())
        root.NeuroFUS.write((f'BURST={50000}\r').encode())

        time.sleep(0.5)

        root.NeuroFUS.write((f'GLOBALPOWER={Power}\r').encode())
        root.NeuroFUS.write((f'GLOBALFREQ={xdrCenterFreq}\r').encode())
        root.NeuroFUS.write((f'FOCUS={int(selected_depth)*1000}\r').encode())
        root.NeuroFUS.write((f'TIMER={int(selected_timer)*1000000}\r').encode())
        root.NeuroFUS.write((f'BURST={burst_length}\r').encode())
        root.NeuroFUS.write((f'PERIOD={PRP}\r').encode())

    # 2-channel
    elif selected_TPO == '2_channel':

        if hasattr(root, "NeuroFUS"):
            print("Already connected")

        else:
            root.NeuroFUS = serial.Serial(
                port=port,
                baudrate=9600,
                bytesize=serial.EIGHTBITS,
                stopbits=serial.STOPBITS_ONE,
                timeout=1,
            )

            time.sleep(4)

        root.NeuroFUS.write(("LOCAL=NO\r\n").encode("ascii"))
        root.NeuroFUS.write((f"POWER={int(round(Power))/1000}\r\n").encode("ascii"))
        root.NeuroFUS.write((f"FREQ={int(round(xdrCenterFreq))/1000}\r\n").encode("ascii"))
        root.NeuroFUS.write((f"DEPTH={int(selected_depth)}\r\n").encode("ascii"))
        root.NeuroFUS.write((f"TIME={int(selected_timer)*100}\r\n").encode("ascii"))
        root.NeuroFUS.write((f"BURST={int(round(burst_length))}\r\n").encode("ascii"))
        root.NeuroFUS.write((f"RATE={1e6 / int(round(PRP))}\r\n").encode("ascii"))

    # Re-check checkbox state after saving
    update_start_state()

def start_function():
    selected_TPO = TPO_default.get()

    if not hasattr(root, "NeuroFUS"):
        print("You need to click Save first")
        return

    time.sleep(3)
    
    if selected_TPO == '4_channel':
        root.NeuroFUS.write(b'START\r')

    elif selected_TPO == '2_channel':
        root.NeuroFUS.write(("START\r\n").encode("ascii"))

########################## GUI ###############################################

root = tk.Tk()
root.title("Ultrasound Driver " + version)
#root.geometry("750x450")

# TPO selection
TPO_label = tk.Label(root, text="TPO:")
TPO_label.grid(row=1, column=0, padx=5, pady=5, sticky="e")

TPO_default = tk.StringVar(value="4_channel")
TPO = tk.OptionMenu(root, TPO_default, "4_channel", "2_channel")
TPO.grid(row=1, column=1, padx=5, pady=5, sticky="w")

# Transducer selection
Transducer_label = tk.Label(root, text="Transducer:")
Transducer_label.grid(row=2, column=0, padx=5, pady=5, sticky="e")

Transducer_default = tk.StringVar(value="DPX_500")
Transducer = tk.OptionMenu(root, Transducer_default, "DPX_500", "CTX_500")
Transducer.grid(row=2, column=1, padx=5, pady=5, sticky="w")

# Checkbox defaults
check_A_var = tk.BooleanVar(value=False)
check_B_var = tk.BooleanVar(value=False)
check_C_var = tk.BooleanVar(value=False)
check_D_var = tk.BooleanVar(value=False)

# MRI mode
check_A = tk.Checkbutton(
    root,
    text="MRI mode (Simultaneous MRI-TUS)",
    variable=check_A_var,
    command=update_start_state,
    wraplength=100
)
check_A.grid(row=1, column=2, padx=5, pady=5, sticky="w")

# Check and confirm label
check_and_confirm_label = tk.Label(root, text="Checklist (!!!)\nConfirm and check the boxes:")
check_and_confirm_label.grid(row=3, column=0, padx=5, pady=5, sticky='e')

# Checkboxes at top
check_B = tk.Checkbutton(
    root,
    text="The transducer selected above matches the one physically connected to TPO.",
    variable=check_B_var,
    command=update_start_state,
    wraplength=300
)

check_B.grid(row=3, column=1, padx=5, pady=5, sticky='w')

check_C = tk.Checkbutton(
    root,
    text="The cables are connected to TPO in the right order (see transducer cables and ports. Both are numbered and labeled).",
    variable=check_C_var,
    command=update_start_state,
    wraplength=300
)

check_C.grid(row=4, column=1, padx=5, pady=5, sticky='w')

# Protocol

protocol_label = tk.Label(root, text="Lab Protocols:")
protocol_label.grid(row=6, column=0, padx=5, pady=5, sticky="e")

protocol_default = tk.StringVar(value="5Hz (tbTUS) - 10% DC")

protocol_default = tk.StringVar(value="5Hz (tbTUS) - 10% DC")

protocol_menu = tk.OptionMenu(
    root,
    protocol_default,
    "tbTUS (5Hz) - 10% DC",
    "100Hz - 10% DC",
    "Online(1000Hz)"
)
protocol_menu.grid(row=6, column=1, padx=5, pady=5, sticky="w")

# Custom protocol function
check_D = tk.Checkbutton(
    root,
    text="Custom Protocol",
    variable=check_D_var,
    command=update_protocol_mode,
    wraplength=300
)
check_D.grid(row=6, column=1, padx=5, pady=5, sticky='e')

custom_prp_label = tk.Label(root, text="PRP (ms):")
custom_prp_entry = tk.Entry(root, width=10)

custom_burst_label = tk.Label(root, text="Burst Length (ms):")
custom_burst_entry = tk.Entry(root, width=10)

# Timer
timer_label = tk.Label(root, text="Timer (seconds):")
timer_label.grid(row=7, column=0, padx=5, pady=5, sticky="e")

timer = tk.Entry(root)
timer.grid(row=7, column=1, padx=5, pady=5, sticky="w")

# Depth
depth_label = tk.Label(root, text="Depth (mm):")
depth_label.grid(row=8, column=0, padx=5, pady=5, sticky="e")

depth = tk.Entry(root)
depth.grid(row=8, column=1, padx=5, pady=5, sticky="w")

# Zero power
zero_power_var = tk.BooleanVar(value=False)

zero_power_checkbox = tk.Checkbutton(
    root,
    text="0W power",
    variable=zero_power_var
)

zero_power_checkbox.grid(row=9, column=1, sticky="w", padx=5)

# Update transducer state when TPO changes
TPO_default.trace_add("write", update_transducer_state)
TPO_default.trace_add("write", update_confirm_visibility)
update_transducer_state()
update_confirm_visibility()

# Instructions
instructions_label = tk.Label(
    root,
    text="Save = sends settings to device (always confirm on the display)\n\nSonication starts 3 seconds after the start button is pressed",
    wraplength=400,
    justify="left"
)
instructions_label.grid(row=11, column=1, pady=10, sticky='w')

# Buttons
save_button = tk.Button(root, text="Save", command=save_function)
save_button.grid(row=12, column=0, pady=10)

start_button = tk.Button(
    root,
    text="Start sonication (Click save first!)",
    command=start_function,
    state="disabled"
)

start_button.grid(row=12, column=1, pady=10)

# Run app
root.mainloop()