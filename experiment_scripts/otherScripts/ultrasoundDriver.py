import tkinter as tk
import time, serial
import serial.tools.list_ports

# Install pyserial. Don't use the standard serial

def sniff_port_based_on_deviceID(vid, pid):
    for p in serial.tools.list_ports.comports():
        if p.vid == vid and p.pid == pid:
            return p.device
    return None

def update_start_state():
    """Enable Start only if A and B are checked."""
    if check_A_var.get() and check_B_var.get():
        start_button.config(state="normal")
    else:
        start_button.config(state="disabled")


def start_function(): 
    selected_TPO = TPO_default.get()
    
    if not hasattr(root, "NeuroFUS"):
        print("You need to click Save first")
        return
    
    if selected_TPO == '4_channel':
        root.NeuroFUS.write(b'START\r')
    elif selected_TPO == '2_channel':
        root.NeuroFUS.write(("START\r\n").encode("ascii"))


def save_function():
    
    # Disable start button while saving
    start_button.config(state="disabled")
    root.update()
    
    selected_TPO = TPO_default.get()
    selected_protocol = protocol_default.get()
    selected_timer = timer.get()
    selected_depth = depth.get() 
    
    # Set power
    if zero_power_var.get():
        Power = 0
    else:
        Power = 30000
    
    # Center frequency 
    xdrCenterFreq = 500000  # Hz
    
    # The port is the same for both 2ch and 4ch 
    port = sniff_port_based_on_deviceID(9025, 61)
    
    # Protocol parameters
    if selected_protocol == 'Online(1000Hz)':
        burst_length = 300
        PRP = 1000
    elif selected_protocol == 'theta_burst':
        burst_length = 20000
        PRP = 200000
    elif selected_protocol == '100Hz':
        burst_length = 1000
        PRP = 10000
    
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
        
        root.NeuroFUS.write(b'TRIGGERMODE=1\r')
        # Go from zero everytime because software has weird limits
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


# ---------------- GUI ----------------

root = tk.Tk()
root.title("Ultrasound Driver")

# Checkbox variables
check_A_var = tk.BooleanVar(value=False)
check_B_var = tk.BooleanVar(value=False)

# Checkboxes at top
check_A = tk.Checkbutton(root, text="I confirm that the selected transducer matches what I connected to the device", variable=check_A_var, command=update_start_state)
check_A.grid(row=0, column=1, padx=5, pady=5)

check_B = tk.Checkbutton(root, text="I confirm that the transducer cables are connected in correct order", variable=check_B_var, command=update_start_state)
check_B.grid(row=1, column=1, padx=5, pady=5)

# TPO selection
TPO_label = tk.Label(root, text="TPO:")
TPO_label.grid(row=2, column=0, padx=5, pady=5, sticky="e")

TPO_default = tk.StringVar(value="4_channel")
TPO = tk.OptionMenu(root, TPO_default, "4_channel", "2_channel")
TPO.grid(row=2, column=1, padx=5, pady=5, sticky="w")

# Protocol
protocol_label = tk.Label(root, text="Protocol:")
protocol_label.grid(row=3, column=0, padx=5, pady=5, sticky="e")

protocol_default = tk.StringVar(value="theta_burst")
protocol = tk.OptionMenu(root, protocol_default, "theta_burst", "100Hz", "Online(1000Hz)")
protocol.grid(row=3, column=1, padx=5, pady=5, sticky="w")

# Timer
timer_label = tk.Label(root, text="Timer (seconds):")
timer_label.grid(row=4, column=0, padx=5, pady=5, sticky="e")

timer = tk.Entry(root)
timer.grid(row=4, column=1, padx=5, pady=5, sticky="w")

# Depth
depth_label = tk.Label(root, text="Depth (mm):")
depth_label.grid(row=5, column=0, padx=5, pady=5, sticky="e")

depth = tk.Entry(root)
depth.grid(row=5, column=1, padx=5, pady=5, sticky="w")

# Zero power
zero_power_var = tk.BooleanVar(value=False)
zero_power_checkbox = tk.Checkbutton(root, text="0W power", variable=zero_power_var)
zero_power_checkbox.grid(row=6, column=1, sticky="w", padx=5)

# Buttons
save_button = tk.Button(root, text="Save", command=save_function)
save_button.grid(row=7, column=0, pady=10)

start_button = tk.Button(root, text="Start (Click save first!)",
                         command=start_function,
                         state="disabled")
start_button.grid(row=7, column=1, pady=10)

# Run app
root.mainloop()