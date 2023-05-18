
#include "soc/soc.h"
#include "soc/rtc_cntl_reg.h"
#include "WiFi.h"
#include "ESPAsyncWebServer.h"
#include "BMI088.h"
#include <Wire.h>
#include <Adafruit_BMP280.h>
#include <DFRobot_URM13.h>
#include "esp_bt_main.h"
#include "esp_bt_device.h"
#include "BluetoothSerial.h"

int status;
BluetoothSerial SerialBT;
Bmi088Accel accel(Wire, 0x19);
Bmi088Gyro gyro(Wire, 0x68);
Adafruit_BMP280 bmp;
DFRobot_URM13_I2C sensor(/*i2cAddr = */0x12, /*i2cBus = */&Wire);
float temp, prs, ax, ay, az, gx, gy, gz, distt;

void printDeviceAddress() {

  const uint8_t* point = esp_bt_dev_get_address();
  for (int i = 0; i < 6; i++) {
    char str[3];
    sprintf(str, "%02X", (int)point[i]);
    Serial.print(str);
    if (i < 5){
      Serial.print(":");
    }
  }
}

void setup() {
  WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0);
  Serial.begin(115200);
  SerialBT.begin("Glidar");
  printDeviceAddress();
  status = bmp.begin(0x77);
  status = accel.begin();
  status = gyro.begin();
  sensor.begin();
  sensor.refreshBasicInfo();
  sensor.setADDR(0x12);
  sensor.setMeasureMode(sensor.eInternalTemp | \
                        sensor.eTempCompModeEn | \
                        sensor.eAutoMeasureModeDis | \
                        sensor.eMeasureRangeModeLong);
  sensor.setExternalTempretureC(30.0);
  sensor.setMeasureSensitivity(0x00);
  pinMode(17, OUTPUT);
  digitalWrite(17, LOW);
  bmp.setSampling(Adafruit_BMP280::MODE_NORMAL,     /* Operating Mode. */
                  Adafruit_BMP280::SAMPLING_X2,     /* Temp. oversampling */
                  Adafruit_BMP280::SAMPLING_X16,    /* Pressure oversampling */
                  Adafruit_BMP280::FILTER_X16,      /* Filtering. */
                  Adafruit_BMP280::STANDBY_MS_500); /* Standby time. */
  delay(100);
}


String getdata()
{
  sensor.passiveMeasurementTRIG();
  accel.readSensor();
  gyro.readSensor();
  ax = accel.getAccelX_mss();
  ay = accel.getAccelY_mss();
  az = accel.getAccelZ_mss();
  temp = bmp.readTemperature();
  prs = bmp.readPressure()/100;
  distt = sensor.getDistanceCm();
  return (String)temp + "," + (String)prs + "," + (String)ax  + "," + (String)ay  + "," + (String)az +","+ (String)distt;
}

void loop()
{
  String datta = getdata();
  SerialBT.println(datta);
  Serial.println(datta);
  delay(100);
}
