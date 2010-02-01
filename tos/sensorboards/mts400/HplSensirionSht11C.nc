/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * HplSensirionSht11C is a low-level component, intended to provide
 * the physical resources used by the Sensirion SHT11 sensor on the
 * telosb platform so that the chip driver can make use of them. You
 * really shouldn't be wiring to this, unless you're writing a new
 * Sensirion SHT11 driver.
 *
 * @author Gilman Tolle <gtolle@archrock.com>
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2006/12/12 18:23:45 $
 */
#include <mts400.h>

configuration HplSensirionSht11C {
  provides interface SplitControl;
  provides interface Resource[ uint8_t id ];
  provides interface GeneralIO as DATA;
  provides interface GeneralIO as SCK;
  provides interface GpioInterrupt as InterruptDATA;
  
  uses interface SensirionSht11 as Humidity;
}
implementation {
  components MicaBusC,new Atm128GpioInterruptC() as interrupt ,HplAtm128InterruptC;

  interrupt.Atm128Interrupt -> HplAtm128InterruptC.Int7;
  DATA = MicaBusC.Int3;
  SCK = MicaBusC.PW3;
  InterruptDATA = interrupt.Interrupt;

  components new HplAdg715C(I2C_POWER_SWITCH_ADDR) as PowerSwitch;
  components new HplAdg715C(I2C_DATA_SWITCH_ADDR) as DataSwitch;
  components new Atm128I2CMasterC() as I2CPower;
  components new Atm128I2CMasterC() as I2CData;
  PowerSwitch.I2CResource ->I2CPower.Resource;
  DataSwitch.I2CResource -> I2CData.Resource;
  PowerSwitch.I2C->I2CPower;
  DataSwitch.I2C -> I2CData;

  components HplSensirionSht11P, MTSGlobalC;
  SplitControl = HplSensirionSht11P.SplitControl;
  HplSensirionSht11P.MTSGlobal -> MTSGlobalC.SplitControl;
  MTSGlobalC.PowerSwitch -> PowerSwitch;
  MTSGlobalC.DataSwitch -> DataSwitch;
  HplSensirionSht11P.PowerSwitch -> PowerSwitch;
  HplSensirionSht11P.DataSwitch -> DataSwitch;
  HplSensirionSht11P.Humidity = Humidity; /* Nasty fix */
  
  components new TimerMilliC();
  HplSensirionSht11P.Timer -> TimerMilliC;
  
  components new SimpleFcfsArbiterC( "Sht11.Resource" ) as Arbiter;
  Resource = Arbiter;
}
