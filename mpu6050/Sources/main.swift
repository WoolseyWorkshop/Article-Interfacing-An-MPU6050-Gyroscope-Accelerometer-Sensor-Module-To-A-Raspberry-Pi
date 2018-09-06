// mpu6050 - main.swift
//
// Description:
// Retrieves motion data from an MPU6050 sensor module using the SwiftyGPIO and
// MPU-6050.swift libraries.
//
// Created by John Woolsey on 08-10-2018.
// Copyright © 2018 Woolsey Workshop.  All rights reserved.


import Foundation
import SwiftyGPIO
import MPU6050


// Sets MPU6050 offsets
func setMPU6050Offsets(_ device: MPU6050, aX: Int, aY: Int, aZ: Int, gX: Int, gY: Int, gZ: Int) {
   print(String(format: "Old Offsets: aX = %5d, aY = %5d, aZ = %5d, gX = %5d, gY = %5d, gZ = %5d",
      arguments: [device.AccelOffsetX, device.AccelOffsetY, device.AccelOffsetZ, device.GyroOffsetX, device.GyroOffsetY, device.GyroOffsetZ]))
   device.AccelOffsetX = aX
   device.AccelOffsetY = aY
   device.AccelOffsetZ = aZ
   device.GyroOffsetX = gX
   device.GyroOffsetY = gY
   device.GyroOffsetZ = gZ
   print(String(format: "New Offsets: aX = %5d, aY = %5d, aZ = %5d, gX = %5d, gY = %5d, gZ = %5d",
      arguments: [device.AccelOffsetX, device.AccelOffsetY, device.AccelOffsetZ, device.GyroOffsetX, device.GyroOffsetY, device.GyroOffsetZ]))
}


// Initialize I2C bus
guard let i2c = SwiftyGPIO.hardwareI2Cs(for:.RaspberryPi3)?[1] else {
   fatalError("Could not initialize I2C bus")
}

// Initialize MPU6050 sensor module
// Uses default I2C address of 0x68.
// Use MPU6050(i2c, address: 0x69) to set alternate address if needed.
let mpu6050 = MPU6050(i2c)  // MPU6050 sensor module handle
mpu6050.enable(true)

// Full-scale range settings
mpu6050.AccelRange = .fs2g  // set full-scale range to ±2g (default)
mpu6050.GyroRange = .fs250ds  // set full-scale range to ±250°/s (default)
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

// Optionally update accelerometer and gyroscope data register offsets.
// Offsets are reset to factory defaults when module is disconnected from power.
// Use offset values obtained from running mpu6050_calibration program.
// setMPU6050Offsets(mpu6050, aX: -906, aY: -83, aZ: 773, gX: 97, gY: 34, gZ: 20)

print()
while (true) {
   // Read raw accel/gyro/temp sensor readings from module
   let (ax,ay,az,t,gx,gy,gz) = mpu6050.getAll()

   // Convert raw register values to human readable values for default
   // ±2g accelerometer and ±250°/s gyroscope full-scale ranges
   let aX = Double(ax)/16384.0
   let aY = Double(ay)/16384.0
   let aZ = Double(az)/16384.0
   let gX = Double(gx)/131.0
   let gY = Double(gy)/131.0
   let gZ = Double(gz)/131.0

   // Print formatted results
   print(String(format: "aX = %4.1f g, aY = %4.1f g, aZ = %4.1f g, gX = %6.1f °/s, gY = %6.1f °/s, gZ = %6.1f °/s, T = %5.1f °C",
      arguments: [aX, aY, aZ, gX, gY, gZ, t]))

   sleep(1)  // wait for one second
}
