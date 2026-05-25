#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue May 12 23:20:53 2026

@author: ozzy
"""

# Import functions. # Install pyserial. Don't use the standard serial
import tkinter as tk
import time, serial, platform
import serial.tools.list_ports
import numpy as np
from tkinter import filedialog
import json

# Version check
version = 'v4.0'

# Protocol placeholder. Will be replaced after a JSON file is loaded
loaded_protocol = {
    "PRP(ms)": None,
    "BurstLength(ms)": None,
    "protocol_name": None
}

# Platform specific text

##################### Helper functions #######################################

# Load json protocol. This needs to have floowing variables protocol_name, 
# BurstLength(ms), PRP(ms), Description. Parantheses need to be included in 
# JSON variables. The last variable Description is optional.
def load_protocol_json():
    global loaded_protocol

    file_path = filedialog.askopenfilename(
        title="Select Protocol JSON",
        filetypes=[("JSON files", "*.json")]
    )

    if not file_path:
        return

    with open(file_path, "r") as f:
        data = json.load(f)

    loaded_protocol["PRP(ms)"] = data.get("PRP(ms)")
    loaded_protocol["BurstLength(ms)"] = data.get("BurstLength(ms)")
    loaded_protocol["protocol_name"] = data.get("protocol_name")

    name = loaded_protocol.get("protocol_name")
    
    if name:
        protocol_name_var.set('Loaded: ' + name)
    else:
        protocol_name_var.set("No protocol loaded")

    print("Loaded protocol:", loaded_protocol)

# Function to find the TPO from pID 
def sniff_port_based_on_deviceID(vid, pid):
    for p in serial.tools.list_ports.comports():
        if p.vid == vid and p.pid == pid:
            return p.device
    return None

# Function to make Start button available only if the checkboxes are checked. 
def update_start_state():
    """Enable Start depending on selected TPO."""
    
    if TPO_default.get() == "2_channel":
        start_button.config(state="normal")
    
    elif TPO_default.get() == "4_channel":
        if check_B_var.get() and check_C_var.get():
            start_button.config(state="normal")
        else:
            start_button.config(state="disabled")

# Update transducer options
def update_transducer_state(*args):
    global Transducer

    # remove old widget
    Transducer.grid_forget()
    
    if TPO_default.get() == "2_channel":
        Transducer = tk.Label(root, text="h264")
    else:
        Transducer = tk.OptionMenu(root, Transducer_default, "DPX_500", "CTX_500")

    Transducer.grid(row=2, column=1, padx=5, pady=5, sticky="w")

# If user selects 2 channel, hide a bunch of stuff related to 4 channel
def update_confirm_visibility(*args):

    if TPO_default.get() == "2_channel":

        check_A.grid_remove()
        check_B.grid_remove()
        check_C.grid_remove()
        check_and_confirm_label.grid_remove()

        # Hide BOTH display panels
        display_outer.grid_remove()
        display_outer_2.grid_remove()

        # Keep depth limit visible
        depth_limit_label.grid()

    else:

        check_and_confirm_label.grid()
        check_A.grid()
        check_B.grid()
        check_C.grid()
        depth_limit_label.grid()

        # Show BOTH display panels again
        display_outer.grid()
        display_outer_2.grid()
        
    update_depth_limit_label()
    update_start_state()

def update_depth_limit_label(*args):
    tx = Transducer_default.get()
    tpo = TPO_default.get()
    
    if tpo == '2_channel':
        depth_limit_var.set("2_channel limits: 20–100 mm")
    elif tpo == '4_channel':
        if tx == "CTX_500":
            depth_limit_var.set("CTX limits: 25–69 mm")
        elif tx == "DPX_500":
            depth_limit_var.set("DPX limits: 55–120 mm")
        else:
            depth_limit_var.set("")
        
def calculate_mi_from_isppa(isppa_w_cm2):
    rho = 1000      # kg/m3, water
    c = 1500        # m/s, water
    freq_mhz = 0.5  # 500 kHz

    intensity_w_m2 = isppa_w_cm2 * 10000
    pressure_pa = np.sqrt(2 * rho * c * intensity_w_m2)
    pressure_mpa = pressure_pa / 1e6

    mi = pressure_mpa / np.sqrt(freq_mhz)
    return mi

##################### Main functions ########################################

# Save button functionality. This is called Init in the program. 
def save_function():

    # Disable start button while saving
    start_button.config(state="disabled")
    root.update()

    # Get TPO, timer and depth specified
    selected_TPO = TPO_default.get()
    selected_timer = timer.get()
    selected_depth = depth.get()
    
    # Get PRP and burst length from JSON files
    PRP = loaded_protocol["PRP(ms)"]
    burst_length = loaded_protocol["BurstLength(ms)"]
    
    # If Init is pressed before filling everything in, don't do anything. Print
    # on the console.
    if PRP is None or burst_length is None:
        print("No protocol loaded. Please select a JSON file first.")
        return
    
    if not selected_timer or not selected_depth:
        print("No timer or depth was selected.")
        return

    # Validate depth based on selected transducer
    try:
        selected_depth_float = float(selected_depth)
    except ValueError:
        print("Depth must be a number.")
        return
    
    tx = Transducer_default.get()
    
    if selected_TPO == '4_channel':
        if tx == "CTX_500" and not (25 <= selected_depth_float <= 69):
            print("CTX depth must be between 25 and 69 mm.")
            return
        
        if tx == "DPX_500" and not (55 <= selected_depth_float <= 120):
            print("DPX depth must be between 55 and 120 mm.")
            return
    elif selected_TPO == '2_channel':
        if not (20 <= selected_depth_float <= 100):
            print("2_channel depth must be between 20 and 100 mm.")
    
    # Calculate mechanical index from requested ISPPA
    try:
        selected_isppa_float = float(isppa.get())
    except ValueError:
        print("ISPPA must be a number.")
        return
    
    mechanical_index = calculate_mi_from_isppa(selected_isppa_float)
    
    if mechanical_index > 1.5:
        mi_warning_label.config(
            text=f"WARNING: Estimated MI in water = {mechanical_index:.2f}, Limit in the brain is 1.9. Do modelling to make sure the values are acceptable in the brain"
        )
    else:
        mi_warning_label.config(
            text=""
        )
    
    # Convert PRP and Burst length to microseconds. This is how TPO wants them.
    PRP = float(PRP) * 1000
    burst_length = float(burst_length) * 1000

    # Center frequency. We hard code this. We can't do anything else. 
    xdrCenterFreq = 500000  # Hz

    # Get the port from pID using our function. It's the same for both 2 and 4_ch 
    port = sniff_port_based_on_deviceID(9025, 61)

    # 4-channel conditions
    if selected_TPO == '4_channel':

        # If a connection is opened don't open it again. Else open it.
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

        # Put the device into ENFORCELIMIT off mode (red mode) 
        root.NeuroFUS.write(('ENFORCELIMITS=0\r').encode())
        
        # Calculate power from ISPPA with constants. 
        selected_isppa = selected_isppa_float
        if tx == "CTX_500" and not check_A_var.get():
            Power = selected_isppa / 14.54 * 1000
        elif tx == "CTX_500" and check_A_var.get():
            Power = selected_isppa / 11.075 * 1000
        elif tx == "DPX_500" and not check_A_var.get():
            Power = selected_isppa / 4.949 * 1000
        elif tx == "DPX_500" and check_A_var.get():
            Power = selected_isppa / 3.36 * 1000
        
        # Set Burst and Period to lowest first. Otherwise we can run into device
        # limits (e.g if we set burst length higher than PRP). Sleep for 0.5s
        root.NeuroFUS.write((f'BURST={1}\r').encode())
        root.NeuroFUS.write((f'PERIOD={1}\r').encode())
        time.sleep(0.5)

        # Set variables to what is requested
        root.NeuroFUS.write((f'GLOBALPOWER={Power}\r').encode())
        root.NeuroFUS.write((f'GLOBALFREQ={xdrCenterFreq}\r').encode())
        root.NeuroFUS.write((f'FOCUS={int(selected_depth)*1000}\r').encode())
        root.NeuroFUS.write((f'TIMER={int(selected_timer)*1000000}\r').encode())
        root.NeuroFUS.write((f'PERIOD={PRP}\r').encode())
        root.NeuroFUS.write((f'BURST={burst_length}\r').encode())

    # 2-channel
    elif selected_TPO == '2_channel':

        # If a connection is opened don't open it again. Else open it.
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

        # Calculate power from ISPPA for 2 channel using Paul's calibration table
        # Round to the nearest power as decimals are not allowed
        selected_isppa = selected_isppa_float
        depths = [35,40,45,50,55,60,65,70,75,80,85,90,95]
        max_intensities = [6.690029719,10.65335428,13.65227765,15.44741492,16.73497048,
                           17.29794313,17.76305019,17.55870846,17.10673748,16.66934595,
                           16.45149282,15.76634466,15.54487496]
        Power = round(selected_isppa*5/np.interp(selected_depth, depths, max_intensities)) * 1000
        
        print('burst length is ' + str(burst_length))
        # Set variables to what is requested
        root.NeuroFUS.write(("LOCAL=NO\r\n").encode("ascii"))
        root.NeuroFUS.write((f"POWER={int(Power)/1000}\r\n").encode("ascii"))
        root.NeuroFUS.write((f"FREQ={int(xdrCenterFreq)/1000}\r\n").encode("ascii"))
        root.NeuroFUS.write((f"DEPTH={int(selected_depth)}\r\n").encode("ascii"))
        root.NeuroFUS.write((f"TIME={int(selected_timer)*100}\r\n").encode("ascii"))
        root.NeuroFUS.write((f"BURST={int(burst_length)}\r\n").encode("ascii"))
        root.NeuroFUS.write((f"RATE={1e6 / int(round(PRP))}\r\n").encode("ascii"))

    # Re-check checkbox state after saving
    update_start_state()

# Function to start treatment
def start_function():
    selected_TPO = TPO_default.get()

    if not hasattr(root, "NeuroFUS"):
        print("You need to click Init first")
        return

    # Sleep for 3 seconds before starting
    time.sleep(3)
    
    if selected_TPO == '4_channel':
        root.NeuroFUS.write(b'START\r')

    elif selected_TPO == '2_channel':
        root.NeuroFUS.write(("START\r\n").encode("ascii"))
        
######################### Mock Display Functions #############################

#### Functions for transducer selection and live update 
def get_selected_transducer_display_name():
    tx = Transducer_default.get()
    mri = check_A_var.get()

    if tx == "DPX_500":
        return "DPX-500-058B" if mri else "DPX-500-058A"

    elif tx == "CTX_500":
        return "CTX-500-130B" if mri else "CTX-500-130A"

    return "-----"

def update_live_display():

    try:

        # Frequency
        freq_value.config(text="500.00 kHz")

        # Transducer config
        selected_transducer_value.config(text=get_selected_transducer_display_name())

        # Depth / Focus
        depth_val = depth.get().strip()
        
        if depth_val:
            focus_value.config(
                text=f"{float(depth_val):.3f} mm"
            )
        else:
            focus_value.config(
                text="----- mm"
            )

        # Timer
        timer_val = timer.get().strip()
        
        if timer_val:
            timer_value_display.config(
                text=f"{float(timer_val):.3f} s"
            )
        else:
            timer_value_display.config(
                text="------- s"
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
                text=f"{Power:.3f} W max     Power/Ch."
            )

            # # Fake PACTUAL
            # power_actual_label.config(
            #     text=f"{current_isppa * 0.1:.3f} W/cm²"
            # )

            isppa_display.config(
                text=f"{current_isppa:.2f} W/cm²      ISPPA"
            )

            # ISPTA
            if (
                loaded_protocol["PRP(ms)"] is not None
                and loaded_protocol["BurstLength(ms)"] is not None
            ):
                duty_cycle = float(loaded_protocol["BurstLength(ms)"]) / float(loaded_protocol["PRP(ms)"])
                current_ispta = current_isppa * duty_cycle
            
                ispta_display.config(
                    text=f"{current_ispta:.2f} W/cm²        ISPTA"
                )
            else:
                ispta_display.config(
                    text="----     W/cm²       ISPTA"
                )

        # Protocol display
        if loaded_protocol["PRP(ms)"] is not None:
            period_value.config(
                text=f"{float(loaded_protocol['PRP(ms)']):.2f} ms"
            )
        
        if loaded_protocol["BurstLength(ms)"] is not None:
            burst_value.config(
                text=f"{float(loaded_protocol['BurstLength(ms)']):.3f} ms"
            )
    
    except Exception as e:
        print("Live display error:", e)

    root.after(200, update_live_display)        

########################## GUI ###############################################

# Set main frame
root = tk.Tk()
root.title("Ultrasound Driver " + version)
#root.geometry("750x450")

# TPO selection label and boxes 
TPO_label = tk.Label(root, text="TPO:")
TPO_label.grid(row=1, column=0, padx=5, pady=5, sticky="e")

TPO_default = tk.StringVar(value="4_channel")
TPO = tk.OptionMenu(root, TPO_default, "4_channel", "2_channel")
TPO.grid(row=1, column=1, padx=5, pady=5, sticky="w")

# Transducer selection label and boxes 
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

# MRI mode checkbox
check_A = tk.Checkbutton(
    root,
    text="MRI mode (Simultaneous MRI-TUS)",
    variable=check_A_var,
    command=update_start_state,
    wraplength=100
)
check_A.grid(row=1, column=2, padx=5, pady=5, sticky="w")

# Checklists
check_and_confirm_label = tk.Label(root, text="Checklist (!!!)\nConfirm and check the boxes:")
check_and_confirm_label.grid(row=3, column=0, padx=5, pady=5, sticky='e')

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

# Protocol label and boxes 
protocol_label = tk.Label(root, text="Protocol")
protocol_label.grid(row=6, column=0, padx=5, pady=5, sticky="e")

protocol_button = tk.Button(
    root,
    text="Select JSON",
    command=load_protocol_json
)

protocol_button.grid(row=6, column=1, padx=5, pady=5, sticky="w")

# Protocol and loading status
protocol_name_var = tk.StringVar(value="No protocol loaded")

protocol_name_label = tk.Label(
    root,
    textvariable=protocol_name_var,
    fg="blue"
)

protocol_name_label.grid(row=6, column=1, padx=(120,5), pady=5, sticky="w")

# Depth label and box
depth_label = tk.Label(root, text="Target Depth (mm):")
depth_label.grid(row=7, column=0, padx=5, pady=5, sticky="e")

depth = tk.Entry(root)
depth.grid(row=7, column=1, padx=5, pady=5, sticky="w")

# Depth limits shown next to target depth
depth_limit_var = tk.StringVar(value="DPX limit: 55–120 mm")

depth_limit_label = tk.Label(
    root,
    textvariable=depth_limit_var,
    fg="gray"
)
depth_limit_label.grid(row=7, column=1, padx=(150, 5), pady=5, sticky="e")

# Timer label and box
timer_label = tk.Label(root, text="Timer (seconds):")
timer_label.grid(row=8, column=0, padx=5, pady=5, sticky="e")

timer = tk.Entry(root)
timer.grid(row=8, column=1, padx=5, pady=5, sticky="w")

# Req ISPPA in water label and boxe
isppa_label = tk.Label(root, text="Req. ISPPA in water W/cm^2:")
isppa_label.grid(row=9, column=0, padx=5, pady=5, sticky="e")

isppa_default = tk.StringVar(value="30")
isppa = tk.Entry(root, textvariable=isppa_default)
isppa.grid(row=9, column=1, padx=5, pady=5, sticky="w")

# Update transducer state when TPO changes
TPO_default.trace_add("write", update_transducer_state)
TPO_default.trace_add("write", update_confirm_visibility)
Transducer_default.trace_add("write", update_depth_limit_label)
update_transducer_state()
update_depth_limit_label()

# Instructions above buttons
instructions_label = tk.Label(
    root,
    text="Init = Sends settings to device. Press this after loading protocol and setting your values, then confirm on the device display!\n\n* Sonication starts 3 seconds after the start button is pressed",
    wraplength=400,
    justify="left"
)
instructions_label.grid(row=11, column=1, pady=10, sticky='w')

# MI warning
mi_warning_label = tk.Label(
    root,
    text="",
    fg="red",
    font=("Arial", 14, "bold"),
    wraplength=400,
    justify="left"
)
mi_warning_label.grid(row=10, column=1, pady=5, sticky="w")

# The buttons to Init and start 
save_button = tk.Button(root, text="Init", command=save_function)
save_button.grid(row=12, column=0, pady=10)

start_button = tk.Button(
    root,
    text="Start sonication (Click Init first!)",
    command=start_function,
    state="disabled"
)

start_button.grid(row=12, column=1, pady=10)

####################### FIRST MOCK DISPLAY ###################################

# Scales
SCALE = 0.8

def sx(x):
    return int(x * SCALE)

IS_WINDOWS = platform.system() == "Windows"

DISPLAY_FONT = "Arial" if IS_WINDOWS else "Helvetica"
DISPLAY_WIDTH = 720 if IS_WINDOWS else 650

def sf(x):
    scale = 0.72 if IS_WINDOWS else SCALE
    return max(8, int(x * scale))

# Box colors 
DISPLAY_BG = "#7a0000"
DISPLAY_YELLOW = "#ffe600"
DISPLAY_WHITE = "white"
DISPLAY_GREEN = "#39ff14"
DISPLAY_BUTTON = "#b30000"

# Frames
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
    width=sx(DISPLAY_WIDTH),
    height=sx(300)
)

display_frame.pack()
display_frame.pack_propagate(False)

# Title of the frame
display_title = tk.Label(
    display_frame,
    text="AFTER PRESSING INIT COMPARE THESE TO ACTUAL DEVICE VALUES \n (IT'S OK IF ISSPA / ISPTA AND POWER ARE CLOSE BUT NOT EXACT)",
    fg="white",
    bg=DISPLAY_BG,
    font=(DISPLAY_FONT, sf(18), "bold")
)

display_title.place(x=sx(20), y=sx(10))

# Power block default values
power_max_label = tk.Label(
    display_frame,
    text="----- W max     Power/Ch.",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=(DISPLAY_FONT, sf(16), "bold")
)
power_max_label.place(x=sx(20), y=sx(60))

power_actual_label = tk.Label(
    display_frame,
    text="not shown           PACTUAL",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=(DISPLAY_FONT, sf(16))
)
power_actual_label.place(x=sx(20), y=sx(95))

isppa_display = tk.Label(
    display_frame,
    text="---- W/cm²       ISPPA",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=(DISPLAY_FONT, sf(16), "bold")
)
isppa_display.place(x=sx(20), y=sx(130))

ispta_display = tk.Label(
    display_frame,
    text="----     W/cm²           ISPTA",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=(DISPLAY_FONT, sf(16))
)
ispta_display.place(x=sx(20), y=sx(165))

# Frequency default values
freq_title = tk.Label(
    display_frame,
    text="Freq.",
    fg=DISPLAY_YELLOW,
    bg=DISPLAY_BG,
    font=(DISPLAY_FONT, sf(28))
)
freq_title.place(x=sx(330), y=sx(70))

freq_value = tk.Label(
    display_frame,
    text="500.00 kHz",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=(DISPLAY_FONT, sf(26))
)
freq_value.place(x=sx(280), y=sx(120))

# Focus defaults
focus_title = tk.Label(
    display_frame,
    text="Focus",
    fg=DISPLAY_YELLOW,
    bg=DISPLAY_BG,
    font=(DISPLAY_FONT, sf(28))
)
focus_title.place(x=sx(500), y=sx(70))

focus_value = tk.Label(
    display_frame,
    text="----- mm",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=(DISPLAY_FONT, sf(24))
)
focus_value.place(x=sx(500), y=sx(120))

#Burst default values
burst_title = tk.Label(
    display_frame,
    text="Burst",
    fg=DISPLAY_YELLOW,
    bg=DISPLAY_BG,
    font=(DISPLAY_FONT, sf(28))
)
burst_title.place(x=sx(20), y=sx(200))

burst_value = tk.Label(
    display_frame,
    text="------- ms",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=(DISPLAY_FONT, sf(24))
)
burst_value.place(x=sx(40), y=sx(250))

# Period default values
period_title = tk.Label(
    display_frame,
    text="Period",
    fg=DISPLAY_YELLOW,
    bg=DISPLAY_BG,
    font=(DISPLAY_FONT, sf(28))
)
period_title.place(x=sx(320), y=sx(200))

period_value = tk.Label(
    display_frame,
    text="------- ms",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=(DISPLAY_FONT, sf(24))
)
period_value.place(x=sx(300), y=sx(250))

# Timer default values
timer_title_display = tk.Label(
    display_frame,
    text="Timer",
    fg=DISPLAY_YELLOW,
    bg=DISPLAY_BG,
    font=(DISPLAY_FONT, sf(28))
)
timer_title_display.place(x=sx(500), y=sx(200))

timer_value_display = tk.Label(
    display_frame,
    text="------- s",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=(DISPLAY_FONT, sf(24))
)
timer_value_display.place(x=sx(500), y=sx(250))

######################## SECOND DISPLAY PANEL ################################

# Frame
display_outer_2 = tk.Frame(
    root,
    bg="black",
    bd=4,
    relief="raised"
)

display_outer_2.grid(
    row=7,
    column=3,
    rowspan=20,
    padx=10,
    pady=10,
    sticky="n"
)

display_frame_2 = tk.Frame(
    display_outer_2,
    bg=DISPLAY_BG,
    width=sx(DISPLAY_WIDTH),
    height=sx(300)
)

display_frame_2.pack()
display_frame_2.pack_propagate(False)

# Title of the frame
display_title = tk.Label(
    display_frame_2,
    text="PRESS \"Opt.\" ON THE DEVICE AND CHECK IF YOUR TRANSDUCER\n IS MATCHING WHAT IS SHOWN HERE",
    fg="white",
    bg=DISPLAY_BG,
    font=(DISPLAY_FONT, sf(18), "bold")
)

display_title.place(x=sx(20), y=sx(10))

# All stuff shown
rf_params_label = tk.Label(
    display_frame_2,
    text="RF Parameters: Std.\nExtra Field: Comp. Focus\nPower Limits Enforced: OFF",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=(DISPLAY_FONT, sf(22))
)
rf_params_label.place(x=sx(130), y=sx(70))

WINDOWSPOS_DIFF = 15
WINDOWSPOS_DIFF = 15 if IS_WINDOWS else 0

selected_transducer_label = tk.Label(
    display_frame_2,
    text="Selected Transducer:",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=(DISPLAY_FONT, sf(22))
)
selected_transducer_label.place(x=sx(100), y=sx(150 + WINDOWSPOS_DIFF))

selected_transducer_value = tk.Label(
    display_frame_2,
    text="DPX-500-058A",
    fg=DISPLAY_YELLOW,
    bg=DISPLAY_BG,
    font=(DISPLAY_FONT, sf(20))
)
selected_transducer_value.place(x=sx(320 + WINDOWSPOS_DIFF), y=sx(150 + WINDOWSPOS_DIFF))

trigger_mode_label = tk.Label(
    display_frame_2,
    text="Trigger Mode: On",
    fg=DISPLAY_WHITE,
    bg=DISPLAY_BG,
    font=(DISPLAY_FONT, sf(22))
)
trigger_mode_label.place(x=sx(180), y=sx(180 + WINDOWSPOS_DIFF))

# Apply visibility
update_confirm_visibility()

# Start updating
update_live_display()

# Run app
root.mainloop()