import serial
import time

def NFOpen(COM, trigger, advanced):
    """
    Connects to the NeuroFUS device via serial port.
    
    Parameters:
    - COM: String, e.g., 'COM5'
    - trigger: int (0 or 1). The trigger = 1 means that the ultrasound protocol 
    will start after a TTL pulse is sent into the 'trigger' port of the 
    NeuroFUS device.
    - advanced: int (0 or 1), If advanced is 1, this enables the power, 
    frequency and phase of each element of the NeuroFUS transducer to be 
    configured independently.

    Returns:
    - NeuroFUS: the serial object
    - NFOK: bool, True if connection check passed
    """
    

    # Create new serial object
    NeuroFUS = serial.Serial(port=COM,
                             baudrate=115200,
                             bytesize=serial.EIGHTBITS,
                             stopbits=serial.STOPBITS_ONE,
                             timeout=1,  # in seconds
                             )

    # Open the port
    NFOK = NFCheckConn(NeuroFUS)

    # Wait before sending commands
    time.sleep(3)

    # Trigger mode
    if trigger == 1:
        NeuroFUS.write(b'TRIGGERMODE=1\r')
        print("External triggering enabled")

    # Advanced mode
    if advanced == 1:
        NeuroFUS.write(b'LOCAL=0\r')
        print("Advanced remote control enabled. Phase, power and frequency of each element can be independently configured.")

    return NeuroFUS, NFOK

def NFClose(NeuroFUS):
    "Closes the communication"
    NeuroFUS.close()    

def NFCheckConn(NeuroFUS):
    """
    Check whether the device responds with a message containing 'TPO'.
    
    Parameters:
    - NeuroFUS: An open pyserial Serial object

    Returns:
    - True if 'TPO' is found at the start of the response
    - False otherwise
    """
    n_char = 24  # number of bytes to read
    response = NeuroFUS.read(n_char)  # returns a bytes object
    response_str = response.decode(errors='ignore')  # convert to string

    if response_str.startswith('TPO'):
        return True
    else:
        return False
    
def NFGlobalFrequency(NeuroFUS, Frequency):
    """
    Sets the global acoustic frequency for all elements in the NeuroFUS transducer.

    Parameters:
    - NeuroFUS: an open pyserial Serial object
    - Frequency: int, frequency in Hz (e.g., 1500000 for 1.5 MHz)
    """
    
    # Convert frequency to string and format command
    freq_str = str(Frequency)
    command = f'GLOBALFREQ={freq_str}\r'

    # Send command
    NeuroFUS.write(command.encode())

def NFGlobalPower(NeuroFUS, Power):
    """
    Sets the power of all elements of the NeuroFUS transducer in Watts.
    
    Parameters:
    - NeuroFUS: an open pyserial Serial object
    - Power: int, power value (max 60)
    """
    
    # # Optionally check Power range (assuming minimum power is 0 or another known value)
    # if not (0 <= Power <= 60):
    #     raise ValueError("Power must be between 0 and 60 Watts.")
    
    # Convert power to string and send command
    pow_str = str(Power)
    command = f'GLOBALPOWER={pow_str}\r'
    NeuroFUS.write(command.encode())

def NFBurstLength(NeuroFUS, Burst):
    """
    Sets the duration of each ultrasound burst in microseconds.
    
    Parameters:
    - NeuroFUS: an open pyserial Serial object
    - Burst: int, burst duration in microseconds (min 10, max 10000)
    
    Note:
    - Burst cannot be longer than the pulse repetition period set by NFPulseRep.
    """

    # if not (10 <= Burst <= 10000):
    #     raise ValueError("Burst duration must be between 10 and 10000 microseconds.")

    burst_str = str(Burst)
    command = f'BURST={burst_str}\r'
    NeuroFUS.write(command.encode())


def NFPulseRepPeriod(NeuroFUS, PRP):
    """
    Sets the pulse repetition period (PRP) in microseconds.
    
    Parameters:
    - NeuroFUS: an open pyserial Serial object
    - PRP: int, pulse repetition period in microseconds (min 10, max 10000)
    
    Note:
    - PRP cannot be lower than the burst length set using NFBurstLength.
    """

    # if not (10 <= PRP <= 10000):
    #     raise ValueError("Pulse repetition period (PRP) must be between 10 and 10000 microseconds.")

    prp_str = str(PRP)
    command = f'PERIOD={prp_str}\r'
    NeuroFUS.write(command.encode())

def NFDuration(NeuroFUS, Duration):
    """
    Sets the overall duration of a NeuroFUS protocol in microseconds.
    
    Parameters:
    - NeuroFUS: an open pyserial Serial object
    - Duration: int, duration in microseconds (1 second to 600 seconds,
                i.e., 1_000_000 to 600_000_000 microseconds)
                Can be set in increments of 10 microseconds.
    """

    # if not (1_000_000 <= Duration <= 600_000_000):
    #     raise ValueError("Duration must be between 1,000,000 and 600,000,000 microseconds (1 to 600 seconds).")

    dur_str = str(Duration)
    command = f'TIMER={dur_str}\r'
    NeuroFUS.write(command.encode())

def NFDepth(NeuroFUS, depth, utx=0):
    """
    Configures NeuroFUS focus depth in micrometers.
    
    Parameters:
    - NeuroFUS: an open pyserial Serial object
    - depth: float, depth in millimeters (with up to 1 decimal place)
    - utx: optional int, set to 1 if using uTx transducer with different steering range
    
    Raises ValueError if depth is outside allowed steering ranges.
    """
    if utx == 0:
        # Default steering range
        if depth < 30:
            raise ValueError("Depth value is too low and outside the steering range of NeuroFUS. Please enter a value more than 30mm and less than 70mm.")
        elif depth > 82.5:
            raise ValueError("Depth value is too high (> 80.51mm) and outside the steering range of NeuroFUS. Please enter a value less than 80.51mm.")
    else:
        # uTx transducer range
        if depth > 10:
            raise ValueError("Depth value is too high and outside the steering range of NeuroFUS. Please enter a value less than 10mm.")

    # Convert mm to micrometers (µm)
    depth_um = str(depth * 1000)
    command = f'FOCUS={depth_um}\r'
    NeuroFUS.write(command.encode())

def NFStart(NeuroFUS):
    """
    Begins a NeuroFUS protocol by sending the START command.
    
    Parameters:
    - NeuroFUS: an open pyserial Serial object
    """

    NeuroFUS.write(b'START\r')

def NFStop(NeuroFUS):
    """
    Aborts a NeuroFUS protocol by sending the ABORT command.
    
    Parameters:
    - NeuroFUS: an open pyserial Serial object
    """
    
    NeuroFUS.write(b'ABORT\r')
