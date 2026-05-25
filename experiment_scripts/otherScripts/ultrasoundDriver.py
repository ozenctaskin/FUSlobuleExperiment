#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue May 12 23:20:53 2026

@author: ozzy
"""

import tkinter as tk
import time, serial
import serial.tools.list_ports
import numpy as np

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

        isppa_label.grid_configure(row=10)
        isppa.grid_configure(row=10)

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

        isppa_label.grid_configure(row=9)
        isppa.grid_configure(row=9)

##################### Main functions ########################################

def save_function():

    # Disable start button while saving
    start_button.config(state="disabled")
    root.update()

    selected_TPO = TPO_default.get()
    selected_timer = timer.get()
    selected_depth = depth.get()
    
    # Get protocol variables based on whether custom mode was set or bult-in 
    # protocols are used. TPO accepts microseconds for PRP and burstLength, 
    # but for custom we will take ms and convert. 
    if check_D_var.get():
        PRP = int(custom_prp_entry.get()) * 1000
        burst_length = int(custom_burst_entry.get()) * 1000
    else:
        selected_protocol = protocol_default.get()
        
    
        if selected_protocol == '5Hz (tbTUS) - 10% DC':
            burst_length = 20000
            PRP = 200000
            
        elif selected_protocol == '7.7Hz - 30% DC':
            burst_length = 2300
            PRP = 7700

        elif selected_protocol == '10Hz - 30% DC':
            burst_length = 30000
            PRP = 100000
    
        elif selected_protocol == '100Hz - 10% DC':
            burst_length = 1000
            PRP = 10000

        elif selected_protocol == '100Hz - 30% DC':
            burst_length = 3000
            PRP = 10000
            
        elif selected_protocol == '1000Hz (online) - 30% DC':
            burst_length = 300 
            PRP = 1000

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

            time.sleep(3)

        # Set the trigger mode and transducer type
        root.NeuroFUS.write(b'TRIGGERMODE=1\r')
        
        tx = Transducer_default.get()  
        if tx == "CTX_500":
            root.NeuroFUS.write(f"xdrselect={1 if check_A_var.get() else 0}\r".encode())
        
        elif tx == "DPX_500":
            root.NeuroFUS.write(f"xdrselect={3 if check_A_var.get() else 2}\r".encode())         

        # Put it into a red development mode 
        root.NeuroFUS.write(('ENFORCELIMITS=0\r').encode())
        
        # Calculate power from ISPPA, do some fine tuning to linear constant
        selected_isppa = int(isppa.get())
        if tx == "CTX_500" and not check_A_var.get():
            Power = selected_isppa / 14.54 * 1000
        elif tx == "CTX_500" and check_A_var.get():
            Power = selected_isppa / 11.075 * 1000
        elif tx == "DPX_500" and not check_A_var.get():
            Power = selected_isppa / 4.949 * 1000
        elif tx == "DPX_500" and check_A_var.get():
            Power = selected_isppa / 3.36 * 1000
        
        # Go from 500ms everytime because software has weird limits
        root.NeuroFUS.write((f'BURST={1}\r').encode())
        root.NeuroFUS.write((f'PERIOD={1}\r').encode())

        time.sleep(0.5)

        root.NeuroFUS.write((f'GLOBALPOWER={Power}\r').encode())
        root.NeuroFUS.write((f'GLOBALFREQ={xdrCenterFreq}\r').encode())
        root.NeuroFUS.write((f'FOCUS={int(selected_depth)*1000}\r').encode())
        root.NeuroFUS.write((f'TIMER={int(selected_timer)*1000000}\r').encode())
        root.NeuroFUS.write((f'PERIOD={PRP}\r').encode())
        root.NeuroFUS.write((f'BURST={burst_length}\r').encode())

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

        # Calculate power from ISPPA for 2 channel using calibration table
        selected_isppa = int(isppa.get())
        depths = [35,40,45,50,55,60,65,70,75,80,85,90,95]
        max_intensities = [6.690029719,10.65335428,13.65227765,15.44741492,16.73497048,
                           17.29794313,17.76305019,17.55870846,17.10673748,16.66934595,
                           16.45149282,15.76634466,15.54487496]
        Power = round(selected_isppa*5/np.interp(selected_depth, depths, max_intensities))
        
        # Send to device
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
    "5Hz (tbTUS) - 10% DC",
    "7.7Hz - 30% DC",
    '10Hz - 30% DC',
    "100Hz - 10% DC",
    '100Hz - 30% DC',
    "1000Hz (online) - 30% DC"
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

# Req ISPPA in water 
isppa_label = tk.Label(root, text="Req. ISPPA in water W/cm^2:")
isppa_label.grid(row=9, column=0, padx=5, pady=5, sticky="e")

isppa_default = tk.StringVar(value="30")
isppa = tk.Entry(root, textvariable=isppa_default)
isppa.grid(row=9, column=1, padx=5, pady=5, sticky="w")

# Update transducer state when TPO changes
TPO_default.trace_add("write", update_transducer_state)
TPO_default.trace_add("write", update_confirm_visibility)
update_transducer_state()
update_confirm_visibility()

# Instructions
instructions_label = tk.Label(
    root,
    text="Save = sends settings to device (Confirm on the TPO display after saving!)\n\n*Sonication starts 3 seconds after the start button is pressed",
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

####################### Mock display #########################################

# ---------- SCALE ----------
SCALE = 0.8

def sx(x):
    return int(x * SCALE)

def sf(x):
    return max(8, int(x * SCALE))

# ---------- COLORS ----------
DISPLAY_BG = "#7a0000"
DISPLAY_YELLOW = "#ffe600"
DISPLAY_WHITE = "white"
DISPLAY_GREEN = "#39ff14"
DISPLAY_BUTTON = "#b30000"

######################## PANEL ###############################################

display_outer = tk.Frame(
    root,
    bg="black",
    bd=4,
    relief="raised"
)

display_outer.grid(
    row=0,
    column=3,
    rowspan=20,
    padx=10,
    pady=10,
    sticky="n"
)

display_frame = tk.Frame(
    display_outer,
    bg=DISPLAY_BG,
    width=sx(650),
    height=sx(300)
)

display_frame.pack()
display_frame.pack_propagate(False)

# ---------- TITLE ----------
display_title = tk.Label(
    display_frame,
    text="COMPARE THESE TO ACTUAL DISPLAY AFTER PRESSING SAVE\n (OK IF ISSPA AND POWER ARE CLOSE BUT NOT EXACT)",
    fg="white",
    bg=DISPLAY_BG,
    font=("Helvetica", sf(18), "bold")
)

display_title.place(x=sx(50), y=sx(10))

######################## POWER ###############################################

power_max_label = tk.Label(
    display_frame,
    text="0.009 W max     Power/Ch.",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=("Helvetica", sf(16), "bold")
)
power_max_label.place(x=sx(20), y=sx(60))

power_actual_label = tk.Label(
    display_frame,
    text="not shown          PACTUAL",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=("Helvetica", sf(16))
)
power_actual_label.place(x=sx(20), y=sx(95))

isppa_display = tk.Label(
    display_frame,
    text="30.00 W/cm²    ISPPA",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=("Helvetica", sf(16), "bold")
)
isppa_display.place(x=sx(20), y=sx(130))

ispta_display = tk.Label(
    display_frame,
    text="not shown          ISPTA",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=("Helvetica", sf(16))
)
ispta_display.place(x=sx(20), y=sx(165))

######################## FREQUENCY ###########################################

freq_title = tk.Label(
    display_frame,
    text="Freq.",
    fg=DISPLAY_YELLOW,
    bg=DISPLAY_BG,
    font=("Helvetica", sf(28))
)
freq_title.place(x=sx(330), y=sx(70))

freq_value = tk.Label(
    display_frame,
    text="500.00 kHz",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=("Helvetica", sf(26))
)
freq_value.place(x=sx(280), y=sx(120))

######################## FOCUS ###############################################

focus_title = tk.Label(
    display_frame,
    text="Focus",
    fg=DISPLAY_YELLOW,
    bg=DISPLAY_BG,
    font=("Helvetica", sf(28))
)
focus_title.place(x=sx(550), y=sx(70))

focus_value = tk.Label(
    display_frame,
    text="65.000 mm",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=("Helvetica", sf(24))
)
focus_value.place(x=sx(500), y=sx(120))

######################## BURST ###############################################

burst_title = tk.Label(
    display_frame,
    text="Burst",
    fg=DISPLAY_YELLOW,
    bg=DISPLAY_BG,
    font=("Helvetica", sf(28))
)
burst_title.place(x=sx(20), y=sx(200))

burst_value = tk.Label(
    display_frame,
    text="20.000 ms",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=("Helvetica", sf(24))
)
burst_value.place(x=sx(40), y=sx(250))

######################## PERIOD ##############################################

period_title = tk.Label(
    display_frame,
    text="Period",
    fg=DISPLAY_YELLOW,
    bg=DISPLAY_BG,
    font=("Helvetica", sf(28))
)
period_title.place(x=sx(320), y=sx(200))

period_value = tk.Label(
    display_frame,
    text="200.000 ms",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=("Helvetica", sf(24))
)
period_value.place(x=sx(300), y=sx(250))

######################## TIMER ###############################################

timer_title_display = tk.Label(
    display_frame,
    text="Timer",
    fg=DISPLAY_YELLOW,
    bg=DISPLAY_BG,
    font=("Helvetica", sf(28))
)
timer_title_display.place(x=sx(560), y=sx(200))

timer_value_display = tk.Label(
    display_frame,
    text="120.0 s",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=("Helvetica", sf(24))
)
timer_value_display.place(x=sx(530), y=sx(250))


######################## LIVE UPDATE #########################################

def update_live_display():

    try:

        # Frequency
        freq_value.config(text="500.00 kHz")

        # Depth / Focus
        if depth.get():
            focus_value.config(
                text=f"{float(depth.get()):.3f} mm"
            )

        # Timer
        if timer.get():
            timer_value_display.config(
                text=f"{float(timer.get()):.1f} s"
            )

        # ISPPA
        if isppa.get():

            current_isppa = float(isppa.get())
            current_tx = Transducer_default.get()  
            
            if current_tx == "CTX_500" and not check_A_var.get():
                Power = round(current_isppa / 14.54, 2)
            elif current_tx == "CTX_500" and check_A_var.get():
                Power = round(current_isppa / 11.075, 2)
            elif current_tx == "DPX_500" and not check_A_var.get():
                Power = round(current_isppa / 4.949, 2)
            elif current_tx == "DPX_500" and check_A_var.get():
                Power = round(current_isppa / 3.36, 2)

            # Fake power estimate
            power_max_label.config(
                text=f"{Power} W max      Power/Ch."
            )

            isppa_display.config(
                text=f"{current_isppa:.2f} W/cm²     ISPPA"
            )

            # # Fake ISPTA estimate
            # ispta_display.config(
            #     text=f"{current_isppa * 0.1:.2f} W/cm²"
            # )


        # Protocol display
        if check_D_var.get():

            if custom_burst_entry.get():
                burst_value.config(
                    text=f"{float(custom_burst_entry.get()):.3f} ms"
                )

            if custom_prp_entry.get():
                period_value.config(
                    text=f"{float(custom_prp_entry.get()):.3f} ms"
                )

        else:

            selected_protocol = protocol_default.get()

            if selected_protocol == '5Hz (tbTUS) - 10% DC':
                burst_value.config(text="20.000 ms")
                period_value.config(text="200.000 ms")

            elif selected_protocol == '7.7Hz - 30% DC':
                burst_value.config(text="2.300 ms")
                period_value.config(text="7.700 ms")

            elif selected_protocol == '10Hz - 30% DC':
                burst_value.config(text="30.000 ms")
                period_value.config(text="100.000 ms")

            elif selected_protocol == '100Hz - 10% DC':
                burst_value.config(text="1.000 ms")
                period_value.config(text="10.000 ms")

            elif selected_protocol == '100Hz - 30% DC':
                burst_value.config(text="3.000 ms")
                period_value.config(text="10.000 ms")

            elif selected_protocol == '1000Hz (online) - 30% DC':
                burst_value.config(text="0.300 ms")
                period_value.config(text="1.000 ms")

    except:
        pass

    root.after(200, update_live_display)

# Start updating
update_live_display()

# Run app
root.mainloop()