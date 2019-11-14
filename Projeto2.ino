#include <DueTimer.h>

// DEFINIÇÕES 

#define FREQ_AMOSTRAGEM 308

#define ORDEM_CTRL        4
#define N_COEF_CTRL       5

#define PWM_1V_12b        4095/3.3
#define PWM_1v5_12b       (4095/3.3)*1.5

// 

int sinal_c = A1;

int outPin = 13;    // DEBUG LED
int debugCtrl = 12;

int outPWM = 10;
int sinal_u = 8;
int sinal_teste = 9;

volatile float amostra = 0;
volatile float cf_c[N_COEF_CTRL] = {2.499, -3.794, 1.653, 1.042, -0.04199};
// Val-padrao -> {2.117, -2.996, 1.292, 1.056, -0.05561};
// Val-experimental -> {2.414, -3.415, 1.473, 0.9117, -0.08834};
// Val Funcional -> {2.499, -3.794, 1.653, 1.042, -0.04199};

volatile float r1 = 0;
volatile float e = 0, e1 = 0, e2 = 0;
volatile float u = 0, u1 = 0, u2 = 0;

int value = 0;  // variable to store the value coming from the sensor

int debug = 0;

bool ledState = false;

// Interrupção a cada 10 Hz
void interrupt100ms(){
 
  //digitalWrite(outPin, HIGH); // Led on
  
  switch(value){
    case 0:
      analogWrite(outPWM, PWM_1V_12b);  // 1V tensão média
      r1 = 1.0;
      value = 1;
      digitalWrite(outPin, HIGH); // Led off
      break;
    case 1:
      analogWrite(outPWM, PWM_1v5_12b);  // 1.5V tensão média
      r1 = 1.5;
      value = 0;
      digitalWrite(outPin, LOW); // Led off
      break;
  } 
}


void acaoControle(){

  analogWrite(sinal_teste, 1*(4095/3.3));

  if(debug == 0){
    digitalWrite(debugCtrl, LOW);
    debug = 1;
  }else{
    digitalWrite(debugCtrl, HIGH);
    debug = 0;
  }
  
  amostra = analogRead(sinal_c)*(3.3/4095);

  e = r1 - amostra;
  
  u = cf_c[0]*e + cf_c[1]*e1 + cf_c[2]*e2 + cf_c[3]*u1 + cf_c[4]*u2;
//u = cf_c1*e(k) + cf_c2*e(k-1) + cf_c3*e(k-2) + cf_c4*u(k-1) + cf_c5*u(k-2);
  
  analogWrite(sinal_u, u*(4095/3.3));  // Ação de comando
  //analogWrite(sinal_teste, u*(4095/3.3));  // Ação de comando
  
  u2 = u1;
  u1 = u;

  e2 = e1;
  e1 = e;

  analogWrite(sinal_teste, 0*(4095/3.3));

}

void setup() {
  // declare the outPin as an OUTPUT:
  pinMode(outPin, OUTPUT);
  
  pinMode(outPWM, OUTPUT);
  pinMode(sinal_u, OUTPUT);
  pinMode(sinal_teste, OUTPUT);
  
  pinMode(debugCtrl, OUTPUT);
  
  Timer1.attachInterrupt(acaoControle).setFrequency(FREQ_AMOSTRAGEM).start();
  Timer0.attachInterrupt(interrupt100ms).setFrequency(FREQ_AMOSTRAGEM/25).start();

  analogReadResolution(12);
  analogWriteResolution(12);
  
  Serial.begin(9600);
}

void loop() {
  
  Serial.println(amostra);

}
