

#include "soc/soc.h"
#include "soc/rtc_cntl_reg.h"
#include "WiFi.h"
#include "ESPAsyncWebServer.h"
#include "BMI088.h"
#include <Wire.h>
#include <Adafruit_BMP280.h>
#include <DFRobot_URM13.h>
int status;
AsyncWebServer server(80);
Bmi088Accel accel(Wire, 0x19);
Bmi088Gyro gyro(Wire, 0x68);
Adafruit_BMP280 bmp;
DFRobot_URM13_I2C sensor(/*i2cAddr = */0x12, /*i2cBus = */&Wire);
float temp, prs, ax, ay, az, gx, gy, gz, distt;
void setup() {
  WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0);
  Serial.begin(115200);
  status = bmp.begin(0x77);
  status = accel.begin();
  status = gyro.begin();
  if ( NO_ERR != sensor.begin() ) {

  }
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
  WiFi.softAP("Glidar", "Glidar2023");
  server.on("/data", HTTP_GET, [](AsyncWebServerRequest * request) {
    request->send_P(200, "text/plain", getdata().c_str());
  });
  server.begin();
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
  prs = bmp.readPressure();
  distt = sensor.getDistanceCm();
  return (String)temp + "," + (String)prs + "," + (String)ax  + "," + (String)ay  + "," + (String)az  + "," + (String)distt;
}

void loop()
{
  delay(1);
}
