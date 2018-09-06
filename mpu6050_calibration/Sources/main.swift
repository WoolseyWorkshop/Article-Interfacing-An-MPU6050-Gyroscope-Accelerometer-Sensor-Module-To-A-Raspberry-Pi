// mpu6050_calibration - main.swift
//
// Description:
// Provides accelerometer and gyroscope offsets for MPU6050 sensor module.
//
// Created by John Woolsey on 08-10-2018.
// Copyright © 2018 Woolsey Workshop.  All rights reserved.
//
// Instructions:
// Place the MPU6050 sensor module on a flat horizontal surface.
// Run a program that retrieves the module's sensor data for 5-10 minutes in
// order for the module to reach a stable temperature.  This can be accomplished
// by running the mpu6050 companion program.
// Run this program to calibrate the accelerometer and gyroscope offsets.
// A line similar to the following is printed when calibration is complete that
// provides the new offset values that can be utilized within other programs.
// New offsets: aX = -854, aY = -56, aZ = 773, gX = 92, gY = 37, gZ = 19
// This program writes the new offset values to the module, however, offset
// values are reset to factory defaults when the module is disconnected from
// power.


import Foundation
import SwiftyGPIO
import MPU6050


// Globals
let Accuracy = 0.05  // calibration accuracy; 0.1 (10%), 0.05 (5%)
let SampleSize = 1000  // sample size for average readings
let AccelRangeSensitivity = 16384.0  // sensitivity per datasheet for ±2g range
let GyroRangeSensitivity = 131.0  // sensitivity per datasheet for ±250°/s range


// Get average sensor readings over a sample size
func averageReadings(for device: MPU6050) -> (ax: Int, ay: Int, az: Int, gx: Int, gy: Int, gz: Int) {
   var sumAccelX =  0, sumAccelY = 0, sumAccelZ = 0
   var sumGyroX = 0, sumGyroY = 0, sumGyroZ = 0
   for index in 1...(SampleSize + 100) {
      let (ax, ay, az, _, gx, gy, gz) = device.getAll()
      if (index > 100) {  // ignore first 100 readings
         sumAccelX += ax
         sumAccelY += ay
         sumAccelZ += az
         sumGyroX += gx
         sumGyroY += gy
         sumGyroZ += gz
      }
      usleep(5000)
   }
   let avgAccelX = Int(sumAccelX / SampleSize)
   let avgAccelY = Int(sumAccelY / SampleSize)
   let avgAccelZ = Int(sumAccelZ / SampleSize)
   let avgGyroX = Int(sumGyroX / SampleSize)
   let avgGyroY = Int(sumGyroY / SampleSize)
   let avgGyroZ = Int(sumGyroZ / SampleSize)
   print(String(format: "Average raw readings: aX = %5d, aY = %5d, aZ = %5d, gX = %5d, gY = %5d, gZ = %5d",
      arguments: [avgAccelX, avgAccelY, avgAccelZ, avgGyroX, avgGyroY, avgGyroZ]))
   return (avgAccelX, avgAccelY, avgAccelZ, avgGyroX, avgGyroY, avgGyroZ)
}


// Setup
guard let i2c = SwiftyGPIO.hardwareI2Cs(for:.RaspberryPi3)?[1] else {
   fatalError("Could not initialize I2C bus")
}
let mpu6050 = MPU6050(i2c)  // Use MPU6050(i2c, address: 0x69) if needed
mpu6050.enable(true)

// Accuracy
print(String(format: "Calibration accuracy: %.1f%%",
   arguments: [Accuracy * 100]))

// Set full-scale ranges
mpu6050.AccelRange = .fs2g  // full-scale range of ±2g
mpu6050.GyroRange = .fs250ds  // full-scale range of ±250°/s
print("Accelerometer full-scale range: ", terminator:"")
if let range = mpu6050.AccelRange {
   print(range.description)
} else {
   print("unknown")
}
print("Gyroscope full-scale range: ", terminator:"")
if let range = mpu6050.GyroRange {
   print(range.description)
} else {
   print("unknown")
}

// Reset offsets
print(String(format: "Old Offsets: aX = %5d, aY = %5d, aZ = %5d, gX = %5d, gY = %5d, gZ = %5d\n",
   arguments: [mpu6050.AccelOffsetX, mpu6050.AccelOffsetY, mpu6050.AccelOffsetZ, mpu6050.GyroOffsetX, mpu6050.GyroOffsetY, mpu6050.GyroOffsetZ]))
mpu6050.AccelOffsetX = 0
mpu6050.AccelOffsetY = 0
mpu6050.AccelOffsetZ = 0
mpu6050.GyroOffsetX = 0
mpu6050.GyroOffsetY = 0
mpu6050.GyroOffsetZ = 0

// Perform calibration
var offsetAccelX = 0, offsetAccelY = 0, offsetAccelZ = 0
var offsetGyroX = 0, offsetGyroY = 0, offsetGyroZ = 0
while (true) {
   // Set new offsets
   mpu6050.AccelOffsetX = offsetAccelX
   mpu6050.AccelOffsetY = offsetAccelY
   mpu6050.AccelOffsetZ = offsetAccelZ
   mpu6050.GyroOffsetX = offsetGyroX
   mpu6050.GyroOffsetY = offsetGyroY
   mpu6050.GyroOffsetZ = offsetGyroZ

   // Get new readings
   let (avgAccelX, avgAccelY, avgAccelZ, avgGyroX, avgGyroY, avgGyroZ) = averageReadings(for: mpu6050)

   // Readings within specified accuracy?
   if (abs(avgAccelX) < Int(AccelRangeSensitivity * Accuracy) &&
       abs(avgAccelY) < Int(AccelRangeSensitivity * Accuracy) &&
       abs(Int(AccelRangeSensitivity) - avgAccelZ) < Int(AccelRangeSensitivity * Accuracy) &&
       abs(avgGyroX) < Int(GyroRangeSensitivity * Accuracy) &&
       abs(avgGyroY) < Int(GyroRangeSensitivity * Accuracy) &&
       abs(avgGyroZ) < Int(GyroRangeSensitivity * Accuracy)) {
      break  // exit loop if readings are within specified accuracy
   }

   // Calculate new offsets
   // The 8 and 4 values are rescaling factors used to match the expected
   // full-scale range setting of the offset registers.
   offsetAccelX -= Int(Double(avgAccelX) / 8.0)
   offsetAccelY -= Int(Double(avgAccelY) / 8.0)
   offsetAccelZ += Int((AccelRangeSensitivity - Double(avgAccelZ)) / 8.0)
   offsetGyroX -= Int(Double(avgGyroX) / 4.0)
   offsetGyroY -= Int(Double(avgGyroY) / 4.0)
   offsetGyroZ -= Int(Double(avgGyroZ) / 4.0)
}
print(String(format: "\nNew offsets: aX = %5d, aY = %5d, aZ = %5d, gX = %5d, gY = %5d, gZ = %5d\n",
   arguments: [mpu6050.AccelOffsetX, mpu6050.AccelOffsetY, mpu6050.AccelOffsetZ, mpu6050.GyroOffsetX, mpu6050.GyroOffsetY, mpu6050.GyroOffsetZ]))

// Display human readable values
let (ax,ay,az,t,gx,gy,gz) = mpu6050.getAll()
let aX = Double(ax)/AccelRangeSensitivity
let aY = Double(ay)/AccelRangeSensitivity
let aZ = Double(az)/AccelRangeSensitivity
let gX = Double(gx)/GyroRangeSensitivity
let gY = Double(gy)/GyroRangeSensitivity
let gZ = Double(gz)/GyroRangeSensitivity
print(String(format: "aX = %4.1f g, aY = %4.1f g, aZ = %4.1f g, gX = %6.1f °/s, gY = %6.1f °/s, gZ = %6.1f °/s, T = %5.1f °C",
   arguments: [aX, aY, aZ, gX, gY, gZ, t]))
