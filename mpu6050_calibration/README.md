# mpu6050_calibration
Provides accelerometer and gyroscope offsets for an MPU6050 sensor module.

## Instructions:
Place the MPU6050 sensor module on a flat horizontal surface.

Run a program that retrieves the module's sensor data for 5-10 minutes in order for the module to reach a stable temperature.  This can be accomplished by running the mpu6050 companion program.

Run this program to calibrate the accelerometer and gyroscope offsets.  A line similar to the following is printed when calibration is complete that provides the new offset values that can be utilized within other programs.

New offsets: aX = -854, aY = -56, aZ = 773, gX = 92, gY = 37, gZ = 19

This program writes the new offset values to the module, however, offset values are reset to factory defaults when the module is disconnected from power.

## Fetch Libraries:
% swift package update

## Compile:
% swift build

## Run:
% .build/debug/mpu6050_calibration
