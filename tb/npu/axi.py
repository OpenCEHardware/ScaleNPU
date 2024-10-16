import enum

import cocotb
from cocotb.binary import BinaryValue
from cocotb.triggers import Lock, RisingEdge, ReadOnly

from cocotb_bus.drivers import BusDriver

class AXIBurst(enum.IntEnum):
    FIXED = 0b00
    INCR = 0b01
    WRAP = 0b10


class AXIxRESP(enum.IntEnum):
    OKAY = 0b00
    EXOKAY = 0b01
    SLVERR = 0b10
    DECERR = 0b11


class AXIProtocolError(Exception):
    def __init__(self,  message: str, xresp: AXIxRESP):
        super().__init__(message)
        self.xresp = xresp


class AXIReadBurstLengthMismatch(Exception):
    pass


class AXI4Agent(BusDriver):
    '''
    AXI4 Agent

    Monitors an internal memory and handles read and write requests.
    '''
    _signals = [
        "arready", "arvalid", "araddr",             # Read address channel
        "arlen",   "arsize",  "arburst", "arprot",

        "rready",  "rvalid",  "rdata",   "rlast",   # Read response channel

        "awready", "awaddr",  "awvalid",            # Write address channel
        "awprot",  "awsize",  "awburst", "awlen",

        "wready",  "wvalid",  "wdata",

    ]

    # Not currently supported by this driver
    _optional_signals = [
        "wlast",   "wstrb",
        "bvalid",  "bready",  "bresp",   "rresp",
        "rcount",  "wcount",  "racount", "wacount",
        "arlock",  "awlock",  "arcache", "awcache",
        "arqos",   "awqos",   "arid",    "awid",
        "bid",     "rid",     "wid"
    ]

    def __init__(self, entity, name, clock, memory, callback=None, event=None,
                 big_endian=False, **kwargs):

        BusDriver.__init__(self, entity, name, clock, **kwargs)
        self.clock = clock

        self.big_endian = big_endian
        self.bus.arready.setimmediatevalue(0)
        self.bus.rvalid.setimmediatevalue(0)
        self.bus.rlast.setimmediatevalue(0)
        self.bus.awready.setimmediatevalue(0)
        self._memory = memory

        self.write_address_busy = Lock("%s_wabusy" % name)
        self.read_address_busy = Lock("%s_rabusy" % name)
        self.write_data_busy = Lock("%s_wbusy" % name)

        cocotb.start_soon(self._read_data())
        cocotb.start_soon(self._write_data())

    def _size_to_bytes_in_beat(self, AxSIZE):
        if AxSIZE < 7:
            return 2 ** AxSIZE
        return None

    async def _write_data(self):
        clock_re = RisingEdge(self.clock)

        while True:
            while True:
                self.bus.wready.value = 0
                await ReadOnly()
                if self.bus.awvalid.value:
                    self.bus.wready.value = 1
                    break
                await clock_re

            await ReadOnly()
            _awaddr = int(self.bus.awaddr)
            _awlen = int(self.bus.awlen)
            _awsize = int(self.bus.awsize)
            _awburst = int(self.bus.awburst)
            _awprot = int(self.bus.awprot)

            burst_length = _awlen + 1
            bytes_in_beat = self._size_to_bytes_in_beat(_awsize)

            if __debug__:
                self.log.debug(
                    "awaddr  %d\n" % _awaddr +
                    "awlen   %d\n" % _awlen +
                    "awsize  %d\n" % _awsize +
                    "awburst %d\n" % _awburst +
                    "awprot %d\n" % _awprot +
                    "BURST_LENGTH %d\n" % burst_length +
                    "Bytes in beat %d\n" % bytes_in_beat)

            burst_count = burst_length

            await clock_re

            while True:
                if self.bus.wvalid.value:
                    word = self.bus.wdata.value
                    word.big_endian = self.big_endian
                    _burst_diff = burst_length - burst_count
                    _st = _awaddr + (_burst_diff * bytes_in_beat)  # start
                    _end = _awaddr + ((_burst_diff + 1) * bytes_in_beat)  # end
                    self._memory[_st:_end] = array.array('B', word.buff)
                    burst_count -= 1
                    if burst_count == 0:
                        break
                await clock_re

    async def _read_data(self):
        clock_re = RisingEdge(self.clock)

        while True:
            self.bus.arready.value = 1
            while True:
                await ReadOnly()
                if self.bus.arvalid.value:
                    break
                await clock_re

            await ReadOnly()
            _araddr = int(self.bus.araddr)
            _arlen = int(self.bus.arlen)
            _arsize = int(self.bus.arsize)
            _arburst = int(self.bus.arburst)
            _arprot = int(self.bus.arprot)

            burst_length = _arlen + 1
            bytes_in_beat = self._size_to_bytes_in_beat(_arsize)

            word = BinaryValue(n_bits=bytes_in_beat*8, bigEndian=self.big_endian)

            if __debug__:
                self.log.debug(
                    "araddr  %d\n" % _araddr +
                    "arlen   %d\n" % _arlen +
                    "arsize  %d\n" % _arsize +
                    "arburst %d\n" % _arburst +
                    "arprot %d\n" % _arprot +
                    "BURST_LENGTH %d\n" % burst_length +
                    "Bytes in beat %d\n" % bytes_in_beat)

            burst_count = burst_length

            await clock_re
            self.bus.arready.value = 0

            self.bus.rvalid.value = 1
            while burst_count > 0:
                _burst_diff = burst_length - burst_count
                _st = _araddr + (_burst_diff * bytes_in_beat)
                _end = _araddr + ((_burst_diff + 1) * bytes_in_beat)
                word.buff = self._memory[_st:_end].tobytes()
                self.bus.rdata.value = word
                self.bus.rlast.value = int(burst_count == 1)

                await ReadOnly()

                if self.bus.rready.value:
                    burst_count -= 1

                await clock_re
                self.bus.rlast.value = 0

            self.bus.rvalid.value = 0
